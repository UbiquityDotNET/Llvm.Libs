// -----------------------------------------------------------------------
// <copyright file="GeneratorCodeTemplate.cs" company="Ubiquity.NET Contributors">
// Copyright (c) Ubiquity.NET Contributors. All rights reserved.
// </copyright>
// -----------------------------------------------------------------------

using LlvmBindingsGenerator.Templates;

namespace LlvmBindingsGenerator
{
    internal class TemplateCodeGenerator
        : ICodeGenerator
    {
        public TemplateCodeGenerator(string absoluteFilePath, ICodeGenTemplate template)
        {
            IsValid = true;
            FileAbsolutePath = absoluteFilePath;
            Template = template;
        }

        public TemplateCodeGenerator(
            string fileNameWithoutExtension,
            string fileRelativeDirectory,
            ICodeGenTemplate template
            )
            : this( isValid: true, fileNameWithoutExtension, fileRelativeDirectory, template )
        {
        }

        public TemplateCodeGenerator(
            bool isValid,
            string fileNameWithoutExtension,
            string fileRelativeDirectory,
            ICodeGenTemplate template
            )
        {
            IsValid = isValid;
            FileNameWithoutExtension = fileNameWithoutExtension;
            FileRelativeDirectory = fileRelativeDirectory;
            Template = template;
        }

        public bool IsValid { get; }

        public string? FileNameWithoutExtension { get; } = null;

        public string? FileRelativeDirectory { get; } = null;

        public string? FileAbsolutePath { get; } = null;

        public ICodeGenTemplate Template { get; }
    }
}
