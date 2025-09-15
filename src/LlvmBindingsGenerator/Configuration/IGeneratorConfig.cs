// Copyright (c) Ubiquity.NET Contributors. All rights reserved.
// Licensed under the Apache-2.0 WITH LLVM-exception license. See the LICENSE.md file in the project root for full license information.

using System.Collections.Immutable;

namespace LlvmBindingsGenerator.Configuration
{
    /// <summary>Interface for a generator configuration</summary>
    /// <remarks>
    /// In earlier versions of this app, the configuration was read in from an external YAML file.
    /// However, over time that became quite a bit simpler and mostly excessive overhead. When the
    /// handle generation was split from the exports.def generation use of a YAML file was removed.
    /// To maintain the minimum of changes and allow for easier comparisons this interface is still
    /// used, though the implementation is now entirely expressed in code.
    /// </remarks>
    internal interface IGeneratorConfig
    {
        /// <summary>Gets the Headers to ignore when parsing the input</summary>
        ImmutableArray<string> IgnoredHeaders { get; }
    }
}
