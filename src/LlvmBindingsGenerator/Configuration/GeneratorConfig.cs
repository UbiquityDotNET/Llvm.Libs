// Copyright (c) Ubiquity.NET Contributors. All rights reserved.
// Licensed under the Apache-2.0 WITH LLVM-exception license. See the LICENSE.md file in the project root for full license information.

using System.Collections.Immutable;

namespace LlvmBindingsGenerator.Configuration
{
    internal class GeneratorConfig
        : IGeneratorConfig
    {
        public ImmutableArray<string> IgnoredHeaders { get; }
            = [
                "llvm-c/lto.h".NormalizePathSep(),
                "llvm-c/Remarks.h".NormalizePathSep(),
            ];
    }
}
