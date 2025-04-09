# Interop Support
This folder contains the low level LLVM direct interop support. It requires specialized build
ordering and processing, which is handled by the PowerShell scripts.

The nature of the .NET SDK projects and VCX projects drives the need for the script,instead of
VS solution dependencies or even MSBuild project to project references. Unfortunately, due to
the way multi-targeting is done in the newer C# SDK projects the project to project references
don't work with C++. The VCXproj files don't have targets for all the .NET targets. Making that
all work seamlessly in VS is just plain hard work that has, thus far, not worked particularly
well. Thus, the design here uses a simpler PowerShell script that takes care of building the
correct platform+configuration+target framework combinations of each and finally builds the NuGet
package from the resulting binaries.

## Why A Distinct source generator
### Roslyn Source Generators - 'There be dragons there!'
Roslyn allows source generators directly in the compiler making for a feature similar to C++ template
code generation AT compile time. However, there's a copule of BIG issue with that for this particular
code base.
1) Non-deterministic ordering
    - More specifically for this project there is no way to declare the dependency on outputs of
      one generator as the input for another. (They all see the same original source as input so
      they can run in parallel.)
2) Dependencies for project references
    - As the generators are not general purpose they are not published or produced as a NUGET
      package. They only would work as a project reference. But that creates a TON of problems for
      the binary runtime dependencies of source generators, which don't flow with them as project
      references...

Specifically, in this code, the built-in AOT aware P/Invoke generator that otherwise knows nothing
about the handle generation, needs to see and use the **OUTPUT** of the handle source generation.
(It's not just a run ordering problem as in the current Roslyn Source generator design - ALL
generators see the same input text!)  
[See: [Discussion on ordering and what a generator "sees"](https://github.com/dotnet/roslyn/discussions/57912#discussioncomment-1682779)]  
[See also: [Roslyn issue #57239](https://github.com/dotnet/roslyn/issues/57239)]

The interop code uses the the LibraryImportAttribute for AOT support of ALL of the interop APIs
declared. Thus, at compile time the interop source generator **MUST** be able to see the types used,
specifically, it must have access to the `NativeMarshalling` attribute for all the handle types.
Otherwise, it doesn't know how to marshal the type and bails out. It is possible to "overcome"
this with an explicit `MarshalUsingAttribute` on every parameter or return type but that's tedious.
Tedious typing is what soure generators and templates are supposed to remove. Thus, this library
will generate the handle sources **BEFORE** they are compiled in the project. (Not to mention it also
generates the exports.g.def used by the native code. Thus, the generated source files will contain
the marshalling attributes so that the interop source generator knows how to generate the correct
code.

>To be crystal clear - The problem is **NOT** one of generator run ordering, but on the ***dependency
of outputs***. By design, Roslyn source generators can only see the original source input, never
the output of another generator. Most don't, and never will, care. The handle generation, in this case
does. Solving that generically in a performant fashion is a ***HARD*** problem indeed... Not guaranteed
impossible, but so far no-one has come up with a good answer to the problem. Even C++ has this issue with
templates+concepts+CRTP; and that language has had source generating templates as a direct part of the
language for several decades now.  
[See also: [Using the CRTP and C++20 Concepts to Enforce Contracts for Static Polymorphism](https://medium.com/@rogerbooth/using-the-crtp-and-c-20-concepts-to-enforce-contracts-for-static-polymorphism-a27d93111a75) ]  
[See also: [Rules for Roslyn source generators](https://github.com/dotnet/roslyn/blob/main/docs/features/incremental-generators.cookbook.md)]

#### Alternate solutions considered and rejected
1) Running the source generator directly in the project
    1) This is where the problem of non-deterministic ordering and visibility of the generated code
       was discovered. Obviously (now anyway!) this won't work.
2) Use a source generator in a seperate assembly
    1) This solves the generator output dependency problem but introduces a new problem of how
       the build infrastructore for these types manage nuget versions
    2) Additionally, this adds complexity of a second native dependency on the dll exporting
       the native functionality. (Should there be two copies? How does code in each refer to
       the one instance?...)
3) Call the source generator from within this app to control the ordering
    1) This at least could get around the ordering/dpendency problem as it would guarantee the
       custom generator runs before the built-in one.
    2) However, this runs afoul of the binary dependency problem... Not 100% insurmountable but the
       number of caveats on the Roslyn Source Generator side of things grows to a significant factor.
       This also complicates all parts of the build to where it isn't worth the effort.

### The final choice
Keep using this LlvmBindingsGenerator as a generator for the export file on Windows and the handle
types for all runtimes. This used to work, and still does. The problem of expressing managed code
things in a custom language (YAML) is solved by not doing that. Instead ALL of the P/Invoke methods
are expressed direcly in C# code. For the handles it is a rather simplistic expression in YAML. And
arguably less complicated then all the subtleties of using a Roslyn Source generator for this sort
of one off specialized code generation.

This also keeps the door open to use the native AST from within the source generator or an analyzer
to perform additional checks and ensure the hand written code matches the actual native code...
(Though this would involve more direct use of the roslyn parser/analyzer and may be best to
generate an input to a proper anaylzer)

## Projects
### LlvmBindingsGenerator
This is thehandle and exports generator for the interop code in Ubiquity.NET.Llvm.Interop. (And
LibLLVM on Windows) It uses CppSharp to parse the C or C++ headers and generates the native
library exports.g.def (For a Windows DLL) along with the source to C# interop "handle" types.
The configuration file also helps in detection of missing or removed handle types when moving to a
newer version of LLVM.

#### Usage
`LlvmBindingsGenerator -l <llvmRoot> -e <extensionsRoot> [-d <deffilepath>] [-h <HandleGenerationDir>] [-c <YamlBindingsConfigFilePath>] [--Diagnostics <DiagnosticKind>]`

| Parameter      | Usage |
|----------------|-------|
| llvmroot       | This is the root of the LLVM directory in the repository containing the llvm headers in a sub folder called 'include' |
| extensionsRoot | this is the root of the directory containing the extended LLVM-C headers (in sub folder 'includes' from the LibLLVM project |
| deffilepath    | Output file name for the generated Exports DEF file. NO DEF file is generated if this is not provided |
| HandleGenerationDir | Output folder for where to generate the handle source. |
| YamlBindingsConfigFilePath | Input file name of the configuration file, if not specified assumes `bindingsConfig.yml` in the current directory |
| DiagnosticKind | Kind of Diagnostics to generate during pare and processing. |

##### Diagnostics
Diagnostic output is controlled by the `--DiagnosticKind` property which is one of the following values:

| Name    | Description |
|---------|-------------|
| Debug   | Detailed debug information useful for inner loop development of the parsing/generation tool itself |
| Message | [Default] Informational messages that provide general progress and information on the generation |
| Warning | Warnings about potential problem areas in the paring/generation |
| Error   | Errors that prevent correct parsing or generation |


This tool is generally only required once per Major LLVM release. (Though a Minor release that adds
new APIs would also warrant a new run) However, to ensure the code generation tool itself isn't
altered with a breaking change, the PowerShell script takes care of running the generator to update
the Ubiquity.NET.Llvm.Interop code base on each run, even if nothing changes in the end. This is
run on every automated build before building the Ubiquity.NET.Llvm.Interop project so that the
generator is tested on every full automated build. 

### LibLLVM
This is the native project that creates the extended LLVM-C API as an actual DLL. Currently
only Windows 64 bit is supported, though other configurations are plausible with additional
build steps in the PowerShell script to build for other platforms. The extensions are configured
to build with high C++ conformance mode, so they should readily build without much modification
for other platforms given the appropriate build infrastructure is set up.

### Ubiquity.NET.Llvm.Interop
This is the .NET P/Invoke layer that provides the raw API projection to .NET. The, majority
of the code is the manually maintained P/Invokes and the handle types generated from the
LlvmBindingsGenerator tool. There are a few additional support classes that are consistent across
variations in LLVM. While this library has a runtime dependency on at least one of the the native
LibLLVM binaries there is no compile time dependency. (As previously mentioned there is a custom
resolver to handle dynamically loading the required imports)

## Building the Interop libraries
### General requirements
There are some general steps that are required to successfully build the interop NuGet package and
a couple of different ways to go about completing them.
 1. Build LlvmBindingsGenerator
 2. Run LlvmBindingsGenerator to parse the llvm headers and the extended headers from the native
    LibLLVM
    1. This generates the C# Handle code AND the linker DEF file used by the Windows variants of
       native library and therefore needs to run before the other projects are built. Generating
       the exports file ensures that it is always accurate and any functions declared in the
       headers are exported so that the linker generates an error  for any missing implementation(s).
 3. Build the LLVM libraries for all supported runtimes (OS+arch) plus one target architecture
 4. Build LibLLVM as a dynamic library for all supported runtimes plus target architecture
 5. Build Ubiquity.NET.Llvm.Interop to create the interop assembly and, ultimately create the final
    NuGet package with the native and manged code bundled together.
    - NOTE, this is a 'Join' point for the build, steps 1-4 may be matrixed and parallelized to
      completely different systems as long as the final output LibLLVM dynamic library is avaliable
      to this step. This MUST wait for the competion of 1-4 across all of the supported runtimes AND
      LLVM targets.
    - OPTIMIZATION: Steps 1&2 may be skipped for all but Windows. For Windows, ONLY the exports DEF
      file is needed so there's is no need to generate the handles (That only needs to be done once
      when building the interop code in step 5)

### Automated build
The interop libraries are built using the Build-Interop.ps1 PowerShell script. This script is required
to correctly build the projects in an automated build as it isn't possible to accomplish all the required
steps in a standard project/solution. (OK, impossible is a bit strong as creating custom targets and tasks
could probably cover it but at the expense of greater complexity). The script is pretty simple though
understanding why it is needed is a more complex matter this document is aimed towards.

>[!IMPORTANT]
> The ease of building multiple platforms is a relative concept and turns out to be MUCH more
> complicated than one might hope. In particular, is the build of all the required LLVM libraries
> needed to make a final LibLLVM. The full set will generally exceed both the time and storage
> space limits of any OSS project automated build system like GitHub Actions, APPVEYOR, etc...
> Thus the native libraries are limited to ONLY the native target and one additional x-plat target.
> Each of these requires a build though they can be done in parallel/matrixed if available. Then
> the results of those builds are combined into the final interop library with appropriate settings
> to generate the NUGET pacakge with the various runtime+target dependencies. The Interop library
> has a custom resolver that will detect the need to load the library and computes the runtime +
> target specific library name and loads it. Thus the rest of the code is completely ignorant of
> the runtime + target or the import library name.

>[!NOTE]
> As of this writing Windows 64 bit is still the only supported platform, but the general idea of
> how to handle cross platform support is in place. So hopefully adding others will be a LOT simpler
> going forward.

>[!WARNING]
> This is currently all just based on experiments and available documentation and NOT tested in a
> real build. This will occur once the full refactoring of this repo is completed and submitted as
> a PR. The PR will contain updated automated build configuration for a matrix that has only one
> runtime and all targets. This will validate the support for multiple targets, and especially, will
> validate the general idea of public infrastructure builds. [This is needed to eliminate the local
> builds and publish of binaries needed with the current model]

#### Build Diagram
``` mermaid
flowchart TD
    start --> runtimeFork@{shape: fork}
    runtimeForkComment@{shape: braces, label: "Fork for each runtime supported; Each fork does not do work, only the targets build code"} --> runtimeFork
    runtimeFork --> rid1["RID win-x64"]
    runtimeFork --> rid2["RID ..."]
    rid1 --> targetFork@{shape: fork}
    rid2 --> targetFork
    targetFork --> ridAndTarget1["Target ARM"] --> targetJoin
    targetFork --> ridAndTarget2["Target X86"] --> targetJoin
    targetFork --> ridAndTarget3["Target ..."] --> targetJoin
    targetForkComment@{shape: comment, label: "Fork to Generate LLVM libraries AND LibLLVM for each Runtime + target combination"} --> targetFork
    targetJoin@{shape: join} --> runtimeJoin@{shape: join} --> IB["Build Nuget Package with all native code libraries and generated handle source"]
    targetJoinComment@{shape: braces, label: "JOIN for all LLVM Targets for a given runtime"} --> targetJoin
    runtimeJoinComment@{shape: braces, label: "JOIN for all runtimes supported"} --> runtimeJoin
```

>[!NOTE]
> The only truly parallel part is the RID+target build. The generation of the the matrix of values
> for RID and target does not require a new image etc.. in the automated build. Ideally it occurs
> on the primary machine that waits for all of the RID+target generation to complete.
