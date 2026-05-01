using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json.Serialization;
using System.Threading.Tasks;

namespace backend.dtos.Response
{
    public class ApiResponse<T>
    {
    public int Code { get; init; } = 200;

    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? Message { get; init; }

    public T? Result { get; init; }
    }
}