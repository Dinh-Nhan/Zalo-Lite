using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading.Tasks;
using backend.Attributes;
using Google.Cloud.Firestore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace backend.Services
{
    [ScopedService]
    public class GroqModerationService
    {
        private readonly FirestoreDb _db;
        private readonly ILogger<GroqModerationService> _logger;
        private readonly string? _apiKey;
        private readonly string _model;
        private static readonly HttpClient _httpClient = new HttpClient();

        public GroqModerationService(FirestoreDb db, ILogger<GroqModerationService> logger, IConfiguration config)
        {
            _db = db;
            _logger = logger;
            _apiKey = config["Groq:ApiKey"] ?? Environment.GetEnvironmentVariable("GROQ_API_KEY");
            _model = config["Groq:Model"] ?? "llama-3.2-11b-vision-preview";
        }

        public async Task ModerateFeedAsync(string feedId, string caption, List<string> imageUrls)
        {
            if (string.IsNullOrEmpty(_apiKey))
            {
                _logger.LogWarning("[GroqModerationService] Groq API key is not configured. Skipping moderation for feed {FeedId}", feedId);
                // Mark it as approved by default if AI is not configured
                await _db.Collection("feeds").Document(feedId).UpdateAsync("moderation_status", "approved");
                return;
            }

            _logger.LogInformation("[GroqModerationService] Starting AI moderation for feed {FeedId} with {ImgCount} images", feedId, imageUrls.Count);

            try
            {
                var systemPrompt = @"Bạn là một AI kiểm duyệt nội dung tự động cho mạng xã hội Zalo Lite.
Hãy phân tích nội dung (bao gồm phần văn bản caption và các hình ảnh đính kèm nếu có) của bài viết này.
Đánh giá xem bài viết có vi phạm các tiêu chuẩn cộng đồng sau hay không:
1. Bạo lực, máu me, vũ khí, đe dọa (violence / gore)
2. Khiêu dâm, khỏa thân, nhạy cảm (nudity / pornography)
3. Ngôn từ kích động thù hằn, quấy rối, xúc phạm (hate speech / harassment)
4. Buôn bán chất cấm, ma túy, lừa đảo, cờ bạc (illegal drugs / scam)
5. Nội dung không phù hợp hoặc phản cảm khác.

Bạn PHẢI trả về kết quả dưới định dạng JSON duy nhất có cấu trúc chính xác sau:
{
  ""violates"": true hoặc false,
  ""reason"": ""Lý do chi tiết bằng tiếng Việt giải thích tại sao vi phạm (nếu violates là true) hoặc để trống (nếu violates là false)"",
  ""category"": ""spam"" hoặc ""harassment"" hoặc ""inappropriate"" hoặc ""other"" (nếu vi phạm) hoặc để trống (nếu không vi phạm),
  ""confidence"": độ tin cậy từ 0.0 đến 1.0
}";

                object contentPayload;
                if (_model.Contains("vision") && imageUrls.Count > 0)
                {
                    var contentList = new List<object>
                    {
                        new { type = "text", text = $"{systemPrompt}\n\nNội dung văn bản (Caption) của bài viết: \"{caption}\"" }
                    };

                    foreach (var url in imageUrls)
                    {
                        contentList.Add(new
                        {
                            type = "image_url",
                            image_url = new { url = url }
                        });
                    }
                    contentPayload = contentList;
                }
                else
                {
                    contentPayload = $"{systemPrompt}\n\nNội dung văn bản (Caption) của bài viết: \"{caption}\"";
                }

                var requestBody = new
                {
                    model = _model,
                    messages = new[]
                    {
                        new
                        {
                            role = "user",
                            content = contentPayload
                        }
                    },
                    response_format = new { type = "json_object" },
                    temperature = 0.1
                };

                var requestJson = JsonSerializer.Serialize(requestBody);
                
                using var request = new HttpRequestMessage(HttpMethod.Post, "https://api.groq.com/openai/v1/chat/completions");
                request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _apiKey);
                request.Content = new StringContent(requestJson, Encoding.UTF8, "application/json");

                var response = await _httpClient.SendAsync(request);
                if (!response.IsSuccessStatusCode)
                {
                    var errBody = await response.Content.ReadAsStringAsync();
                    _logger.LogError("[GroqModerationService] Groq API returned error status {Status}: {Body}", response.StatusCode, errBody);
                    // Fallback to approved to avoid locking the feed in a pending state forever
                    await _db.Collection("feeds").Document(feedId).UpdateAsync("moderation_status", "approved");
                    return;
                }

                var responseJson = await response.Content.ReadAsStringAsync();
                var groqResponse = JsonSerializer.Deserialize<GroqChatCompletionResponse>(responseJson);
                var content = groqResponse?.Choices?[0]?.Message?.Content;

                if (string.IsNullOrEmpty(content))
                {
                    _logger.LogError("[GroqModerationService] Groq returned empty content choice.");
                    await _db.Collection("feeds").Document(feedId).UpdateAsync("moderation_status", "approved");
                    return;
                }

                var result = JsonSerializer.Deserialize<ModerationResult>(content);
                if (result == null)
                {
                    _logger.LogError("[GroqModerationService] Failed to parse moderation JSON result from: {Content}", content);
                    await _db.Collection("feeds").Document(feedId).UpdateAsync("moderation_status", "approved");
                    return;
                }

                _logger.LogInformation("[GroqModerationService] Moderation result for feed {FeedId}: Violates={Violates}, Reason={Reason}, Category={Category}, Confidence={Conf}", 
                    feedId, result.Violates, result.Reason, result.Category, result.Confidence);

                if (result.Violates)
                {
                    // 1. Update feed: disable it and set status to flagged
                    await _db.Collection("feeds").Document(feedId).UpdateAsync(new Dictionary<string, object>
                    {
                        { "is_enable", false },
                        { "moderation_status", "flagged" }
                    });

                    // 2. Create auto-report
                    var reportRef = _db.Collection("reports").Document();
                    var reportData = new Dictionary<string, object>
                    {
                        { "reporter_id", "system_ai" },
                        { "target_type", "post" },
                        { "target_id", feedId },
                        { "reason", string.IsNullOrEmpty(result.Category) ? "other" : result.Category },
                        { "description", $"[Tự động từ AI] {result.Reason} (Độ tin cậy: {result.Confidence:P0})" },
                        { "status", "pending" },
                        { "admin_note", "" },
                        { "created_at", Timestamp.FromDateTime(DateTime.UtcNow) }
                    };

                    await reportRef.SetAsync(reportData);
                    _logger.LogWarning("[GroqModerationService] Feed {FeedId} was flagged. Auto-created report {ReportId}", feedId, reportRef.Id);
                }
                else
                {
                    // Update feed: set status to approved
                    await _db.Collection("feeds").Document(feedId).UpdateAsync("moderation_status", "approved");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "[GroqModerationService] Error during feed moderation for feed {FeedId}", feedId);
                // Set to approved as fallback so that feeds aren't stuck
                try
                {
                    await _db.Collection("feeds").Document(feedId).UpdateAsync("moderation_status", "approved");
                }
                catch { /* ignore fallback errors */ }
            }
        }
    }

    public class GroqChatCompletionResponse
    {
        [JsonPropertyName("choices")]
        public List<GroqChoice>? Choices { get; set; }
    }

    public class GroqChoice
    {
        [JsonPropertyName("message")]
        public GroqMessage? Message { get; set; }
    }

    public class GroqMessage
    {
        [JsonPropertyName("content")]
        public string? Content { get; set; }
    }

    public class ModerationResult
    {
        [JsonPropertyName("violates")]
        public bool Violates { get; set; }

        [JsonPropertyName("reason")]
        public string Reason { get; set; } = string.Empty;

        [JsonPropertyName("category")]
        public string Category { get; set; } = string.Empty;

        [JsonPropertyName("confidence")]
        public double Confidence { get; set; }
    }
}
