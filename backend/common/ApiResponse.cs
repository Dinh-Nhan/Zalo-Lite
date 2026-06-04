using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json.Serialization;
using System.Threading.Tasks;

namespace backend.common
{
    public class ApiResponse<T>
    {
        public bool Success { get; init; } = true;

        public int Code { get; init; } = 200;

        [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
        public string? Message { get; init; }

        public T? Result { get; init; }

        public static ApiResponse<T> SuccessResponse(T data, string? message = null)
        {
            return new ApiResponse<T>
            {
                Success = true,
                Code = 200,
                Message = message,
                Result = data
            };
        }

        public static ApiResponse<T> ErrorResponse(int code, string message)
        {
            return new ApiResponse<T>
            {
                Success = false,
                Code = code,
                Message = message,
                Result = default
            };
        }
    }
}
