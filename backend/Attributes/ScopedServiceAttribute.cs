using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace backend.Attributes
{
    [AttributeUsage(AttributeTargets.Class)]
public class ScopedServiceAttribute : Attribute { }
}