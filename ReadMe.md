# Ubiquity.Net.Llvm.Libs Nuget Support
Build support for Ubiquity.Net Llvm static libraries

## About
LLVM is a large collection of libraries for building compiler back-ends that
supports a great deal of customization and extensibility. Using LLVM either
requires building the entire source tree or access to pre-built libraries.
The source is available, but building a full set of libraries for multiple
platforms and configurations (e.g. x86-Release, x64-Debug, etc...) can take
significant time, which can be an issue for an automated build. Many Free for
OSS project build services like [AppVeyor](http://AppVeyor.com) limit the total
run time for any given build. Therefore, building the full source won't work there.

In addition to the compilation times, the full size of the output is very large, if
packaged as a NuGet package it exceeds the size limits of all known public release
NuGet galleries. Thus, this repository includes support for building the libraries
on a local machine once and using [7-Zip](https://www.7-zip.org/) to compress the
libraries. The resulting libraries are then made available as a release from this
repository on GitHub to allow automated builds that consume the libraries to download
them.

## CAUTION
The static libraries are compiler version specific and mixing versions of libraries
is a tricky proposition at best. Using the released libraries directly isn't generally
a good idea. Instead, you can use the LibLLVM.DLL created by the Llvm.NET repository. That
exposes a stable, extended LLVM-C library. (The repository also provides the Llvm.NET
C# wrapper for the native DLL.) The only reason for publishing the libraries is to enable
the automated builds of Llvm.NET to have access to the pre-built libraries. Thus, these
two repositories are closely related and the static library and compiler version 
dependencies are manageable.

## Building the 7-Zip packages locally
### Pre-requisites
The build requires the MSVC CMAKE support along with Python 2.7. These are all available as
components for the VisualStudio 2017 15.7+ Community installation. According to the documentation
they should all be available from the VisualStudio 2017 build tools installer as well, though that
hasn't been tested.

### Running a local build
```PowerShell
.\scripts\Initialize-BuildEnv.ps1
build
pack
```
