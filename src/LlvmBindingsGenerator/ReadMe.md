# LibLLVMBindingsGenerator
As the name implies this is a code generator for use in building the LLVM libraries.
Historically it did more than it does now but that use proved to be difficult to maintain
(It generated all the P/Invoke code from a custom representation in YAML. In the end that
was just extra work as not much was automatable. (A LOT required reading the docs, and often
the LLVM source code to determine if it was an ownership transfer (move) and, if so, how to
dispose of the resource once done with it. All of that is expressible IN C# already as part
of P/Invoke generation so there wasn't much point in continuing with that. (Though there is
something to be said for use as a starting point...)

Instead it is now split into two uses:
1) Generates the EXPORTS.g.def for the Windows DLL generation from the LLVM + LIBLLVM headers
    1) This version in the native repo deals only with the export generation and name
       validation for the extension APIs
2) Generates the "safe handle" C# code from the LLVM + LIBLLVM headers
    1) This functionality moved to the consuming repo where it is easier to maintain and
       update as all the upward managed dependencies are there.

## Usage
`LlvmBindingsGenerator -l <llvmRoot> -e <ExtensionsRoot> -d <ExportsDefFilePath> -Diagnostics <Diagnostics>`

| Options Property   | Usage |
|--------------------|-------|
| LlvmRoot           | This is the root of the LLVM directory in the repository containing the llvm headers |
| ExtensionsRoot     | This is the root of the directory containing the extended LLVM-C headers from the LibLLVM project |
| ExportsDefFilePath | [Optional] Path of the Exports file to generate
| Diagnostics        | Diagnostics output level for the app |

This tool is generally only required once per Major LLVM release. (Though a Minor release
that adds new APIs would also warrant a new run) However, to ensure the code generation tool
itself isn't altered with a breaking change, the PowerShell script takes care of running the
generator to update the Generated code base on each run, even if nothing changes in the end.
This is run on every automated build before building the LIBLLVM family of project so that
the generator is tested on every full automated build. 

### EXPORTS.g.def
The exports file contains all of the C APIS exported from the LIBLLVM DLL. This is parsed
from the headers and reflects what is in them. Thus, if a definition of an LLVM function or
that of a LIBLLVM extended function is not found then a linker failure will occur. This helps
identify things declared but removed as well as any library not referenced correctly.

