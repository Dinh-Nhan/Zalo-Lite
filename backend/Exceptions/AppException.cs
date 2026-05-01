using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.Enums;

namespace backend.Exceptions
{
    public class AppException : Exception
{
    public ErrorCode ErrorCode { get; }

    public AppException(ErrorCode errorCode) 
        : base(errorCode.GetMeta().Message)
    {
        ErrorCode = errorCode;
    }
}
}