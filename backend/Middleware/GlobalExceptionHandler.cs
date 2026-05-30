using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.common;
using backend.dtos.Response;
using backend.Enums;
using backend.Exceptions;
using FluentValidation;

namespace backend.Middleware
{
    public class GlobalExceptionHandler(ILogger<GlobalExceptionHandler> logger) : IMiddleware
    {
        public async Task InvokeAsync(HttpContext context, RequestDelegate next)
        {
            try
            {
                await next(context);
            }
            catch (Exception ex)
            {
                await HandleAsync(context, ex);
            }
        }

        private async Task HandleAsync(HttpContext context, Exception exception)
        {
            var traceId = context.TraceIdentifier;
            context.Response.ContentType = "application/json";

            ApiResponse<ErrorDetail> response = exception switch
            {
                AppException appEx        => HandleAppException(appEx, traceId, context),
                ValidationException valEx => HandleValidation(valEx, traceId, context),
                _                         => HandleUnknown(exception, traceId, context)
            };

            await context.Response.WriteAsJsonAsync(response);
        }

        private ApiResponse<ErrorDetail> HandleAppException(
            AppException ex, string traceId, HttpContext context)
        {
            var meta = ex.ErrorCode.GetMeta();
            context.Response.StatusCode = (int)meta.HttpStatus;

            logger.LogWarning("[{TraceId}] {ErrorCode}: {Message}",
                traceId, ex.ErrorCode, ex.Message);

            return new ApiResponse<ErrorDetail>
            {
                Success = false,
                Code = meta.Code,
                Message = meta.Message,
                Result = new ErrorDetail
                {
                    ErrorCode = ex.ErrorCode.ToString(),
                    TraceId = traceId
                }
            };
        }

        private ApiResponse<ErrorDetail> HandleValidation(
            ValidationException ex, string traceId, HttpContext context)
        {
            var meta = ErrorCode.VALIDATION_ERROR.GetMeta();
            context.Response.StatusCode = (int)meta.HttpStatus;

            logger.LogWarning("[{TraceId}] {ErrorCode}: {Errors}",
                traceId, ErrorCode.VALIDATION_ERROR,
                string.Join(" | ", ex.Errors.Select(e => e.ErrorMessage)));

            return new ApiResponse<ErrorDetail>
            {
                Success = false,
                Code = meta.Code,
                Message = meta.Message,
                Result = new ErrorDetail
                {
                    ErrorCode = ErrorCode.VALIDATION_ERROR.ToString(),
                    TraceId = traceId,
                    Errors = ex.Errors.Select(e => e.ErrorMessage).ToList()
                }
            };
        }

        private ApiResponse<ErrorDetail> HandleUnknown(
            Exception ex, string traceId, HttpContext context)
        {
            logger.LogError(ex, "[{TraceId}] Unhandled exception: {Message}",
                traceId, ex.Message);

            var meta = ErrorCode.INTERNAL_ERROR.GetMeta();
            context.Response.StatusCode = (int)meta.HttpStatus;

            return new ApiResponse<ErrorDetail>
            {
                Success = false,
                Code = meta.Code,
                Message = meta.Message,
                Result = new ErrorDetail
                {
                    ErrorCode = ErrorCode.INTERNAL_ERROR.ToString(),
                    TraceId = traceId,
                    DebugMessage = IsDev() ? ex.ToString() : null
                }
            };
        }

        private static bool IsDev() =>
            Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") == "Development";
    }
}
