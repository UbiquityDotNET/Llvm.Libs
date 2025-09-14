// Copyright (c) Ubiquity.NET Contributors. All rights reserved.
// Licensed under the Apache-2.0 WITH LLVM-exception license. See the LICENSE.md file in the project root for full license information.

using System.Collections.Generic;
using System.Linq;

using CppSharp.AST;

namespace LlvmBindingsGenerator.Templates
{
    internal partial class ExportsTemplate
        : ICodeGenTemplate
    {
        public ExportsTemplate( ASTContext ast )
        {
            Ast = ast;
        }

        public string ToolVersion => GetType( ).Assembly.GetAssemblyInformationalVersion( );

        public string FileExtension => "g.DEF";

        public string SubFolder => string.Empty;

        public string Generate( )
        {
            return TransformText( );
        }

#if SUPPORT_INLINED_TARGETFUNCS
        public IEnumerable<Function> InlinedFunctions
            => from tu in Ast.GeneratedUnits( )
               from func in tu.Functions
               where func.IsInline && !func.Ignore
               select func;
#endif

        public IEnumerable<Function> ExtensionFunctions
            => from tu in Ast.GeneratedUnits( )
               where tu.IsExtensionHeader( )
               from func in tu.Functions
               where !func.IsInline && !func.Ignore
               select func;

        public IEnumerable<Function> LlvmFunctions
            => from tu in Ast.GeneratedUnits( )
               where tu.IsCoreHeader( )
               from func in tu.Functions
               where !func.IsInline && !func.Ignore
               select func;

        private readonly ASTContext Ast;
    }
}
