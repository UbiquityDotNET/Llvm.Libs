// -----------------------------------------------------------------------
// <copyright file="GeneratorConfig.cs" company="Ubiquity.NET Contributors">
// Copyright (c) Ubiquity.NET Contributors. All rights reserved.
// </copyright>
// -----------------------------------------------------------------------

using System.Collections.Immutable;
using System.IO;

namespace LlvmBindingsGenerator.Configuration
{
    internal class GeneratorConfig
        : IGeneratorConfig
    {
        public ImmutableArray<string> IgnoredHeaders { get; }
            = [
                NormalizePathSep("llvm-c/lto.h"),
                NormalizePathSep("llvm-c/Remarks.h"),
            ];

            // Runtime agnostic path separator normalization
            internal static string NormalizePathSep( string path )
            {
                return path.Replace( Path.AltDirectorySeparatorChar, Path.DirectorySeparatorChar );
            }
    }
}
