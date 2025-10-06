# Ubiquity.NET.Llvm.Interop Generation 
The code generation for the Ubiquity.NET.Llvm.Interop namespace leverages [CppSharp] for
parsing and processing the LLVM-C (and custom extension) headers. The actual code generation
is done using a custom system of T4 templates. While CppSharp has a code generation system
it is focused primarily on projecting the full C++ type system (including implementing
derived types in C#!). However, the generation is pretty inflexible when it comes to the
final form of the output in C# and how it handles marshaling. Ubiquity.NET.Llvm uses custom
handle types for all references in the C API along with custom string marshaling to handle
the various kinds of string disposal used in the C API. Unfortunately, CppSharp wasn't
flexible enough to handle that with it's built-in generation. This variant of the generator
deals only with the Windows `exports.def

## T4 Templates
### GlobalHaExportsTemplate.tt
Provides a template for generation of the Windows Exports.def file

