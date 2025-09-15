// Copyright (c) Ubiquity.NET Contributors. All rights reserved.
// Licensed under the Apache-2.0 WITH LLVM-exception license. See the LICENSE.md file in the project root for full license information.

using System.Collections.Generic;

using CppSharp.Generators;
using CppSharp.Passes;

using LlvmBindingsGenerator.Configuration;
using LlvmBindingsGenerator.Templates;

namespace LlvmBindingsGenerator
{
    // Factory class for the templates needed in code generation
    // This is essentially a more flexible form of the CppSharp.CodeGenerator,
    // which, despite the name, doesn't generate code, but instead creates
    // templates in the form of GeneratorOutput. Therefore, ICodeGenerator
    // here is the functional equivalent to CppSharp's GeneratorOutput.
    internal class LibLlvmTemplateFactory
        : ICodeGeneratorTemplateFactory
    {
        public LibLlvmTemplateFactory( IGeneratorConfig config)
        {
        }

        public void SetupPasses( BindingContext bindingContext )
        {
            bindingContext.TranslationUnitPasses.AddPass( new CheckAbiParameters( ) );
        }

        public IEnumerable<ICodeGenerator> CreateTemplates( BindingContext bindingContext, Options options )
        {
            if( options.GenerateDefFile)
            {
                yield return new TemplateCodeGenerator(options.ExportsDefFilePath, new ExportsTemplate( bindingContext.ASTContext ) );
            }
        }
    }
}
