// -----------------------------------------------------------------------
// <copyright file="LibLlvmTemplateFactory.cs" company="Ubiquity.NET Contributors">
// Copyright (c) Ubiquity.NET Contributors. All rights reserved.
// </copyright>
// -----------------------------------------------------------------------

using System.Collections.Generic;
using System.Linq;

using CppSharp;
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
            HandleToTemplateMap = config.BuildTemplateMap( );
        }

        public void SetupPasses( BindingContext bindingContext )
        {
            bindingContext.TranslationUnitPasses.AddPass( new CheckAbiParameters( ) );
        }

        public IEnumerable<ICodeGenerator> CreateTemplates( BindingContext bindingContext, Options options )
        {
            if(options.GenerateHandles)
            {
                // filter out known handle types with non-templated implementations
                // LLVMErrorRef is rather unique with disposal and requires a distinct
                // implementation. (If the message is retrieved, the handle is destroyed,
                // and it is destroyed if "consumed" without getting the message.)
                var handles = from handle in bindingContext.ASTContext.GetHandleTypeDefs( )
                              where handle.Name != "LLVMErrorRef"
                              select handle;

                foreach( var handle in handles )
                {
                    bool templatesFound = false;
                    foreach(IHandleCodeTemplate template in HandleToTemplateMap[handle.Name])
                    {
                        yield return new TemplateCodeGenerator( template.HandleName, options.HandleOutputPath, template );
                        templatesFound = true;
                    }

                    if(!templatesFound)
                    {
                        // Generate an error for any handle types parsed from native headers not accounted for in the YAML configuration.
                        Diagnostics.Error( "No Mapping for handle type {0} - {1}@{2}", handle.Name, handle.TranslationUnit.FileRelativePath, handle.LineNumberStart );
                    }
                }
            }

            if( options.GenerateDefFile)
            {
                yield return new TemplateCodeGenerator(options.ExportsDefFilePath, new ExportsTemplate( bindingContext.ASTContext ) );
            }
        }

        private readonly ILookup<string, IHandleCodeTemplate> HandleToTemplateMap;
    }
}
