// -----------------------------------------------------------------------
// <copyright file="IGeneratorCodeTemplate.cs" company="Ubiquity.NET Contributors">
// Copyright (c) Ubiquity.NET Contributors. All rights reserved.
// </copyright>
// -----------------------------------------------------------------------

using System.Collections.Generic;
using CppSharp.Generators;

namespace LlvmBindingsGenerator
{
    internal interface ICodeGeneratorTemplateFactory
    {
        IEnumerable<ICodeGenerator> CreateTemplates( BindingContext bindingContext, Options options );

        void SetupPasses( BindingContext bindingContext );
    }
}
