# Source folder
This folder contains the source code to the multiple projects used in producing the
packages for the native code Extended LLVM-C API (Ubiqutiy.NET.LibLLVM [or just LibLLVM]).

## LIBLLVM
This contains the source and build projects for the dynamic library itself.

Currently this is done once per rid. Currently this is done once per rid + additional target
so that it creates a single package for each runtime.

## LIBLLVMNuget
This project us used to create a NUGET package for the dynamic library. This has a hard
dependency on the output of the LIBLLVM project. In automated builds, this runs immediately
after the creation of the dynamic library itself.

Currently this is done once per rid so that it creates a single package for each runtime. 

## LibLLVMNugetMetaPackage
This project is used to create a "metapackage" for each supported runtime. Even though this
references the packages built elsewhere it does not require the actual binaries and can
therefore operate in parallel. This allows consumers to directly reference only this one
pacage per runtime. (Ultimately, an "Uber" package could refer to all the RID specific
ones...).

## LLvmBindingsGenerator
This is the "source generator" the name is a bit misleading due to history. It's role now
is simply two fold:
1) For Windows builds, generates the EXPORTS.DEF file to mark the APIs exported by this
   library.
    1) On windows the default visibility of a function is "private" and therefore an
       explicit declaration is needed for consumers to see it.
