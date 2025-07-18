﻿// -----------------------------------------------------------------------
// <copyright file="ExportsTemplate.cs" company="Ubiquity.NET Contributors">
// Copyright (c) Ubiquity.NET Contributors. All rights reserved.
// </copyright>
// -----------------------------------------------------------------------

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
