# Ubiquity.Net.Llvm.Libs Nuget Support
Build support for Ubiquity.Net.Llvm.Libs Nuget packages

[![NuGet](https://img.shields.io/nuget/v/Ubiquity.Net.Llvm.Libs.svg)](http://www.nuget.org/packages/Ubiquity.Net.Llvm.Libs/)

## About
LLVM is a large collection of libraries for building compiler back-ends that
supports a great deal of customization and extensibility. Using LLVM either
requires building the entire source tree or access to pre-built libraries.
The source is available, but building a full set of libraries for multiple
platforms and configurations (e.g. x86-Release, x64-Debug, etc...) can take
significant time in an automated build. Many Free for OSS project build services
like [AppVeyor](http://AppVeyor.com) limit the total run time for any given build.
Therefore, building the full source won't work there. Thus, this directory includes support
for building the libraries on a local machine once and packed into a NuGet package.
Projects using LLVM can then reference the NuGet package to let NuGet download the
libraries instead of having to build them.

Llvm.NET project maintains a [NuGet package](http://www.nuget.org/packages/Ubiquity.Net.Llvm.Libs/)
package for the official releases of LLVM that are built using this directory. **Thus, you
generally don't need to use this yourself.** However, it is made available in case there is
a need (like restrictions on external NuGet feeds etc...) so you can create your own copy of
the packages but still build projects that reference them.

## Usage
The simplest usage is to use the public NuGet feed and add the "Ubiquity.Net.Llvm.Libs" package
to your project. The package includes all the headers and libraries from LLVM.

## Building the packages localy
### Pre-requisites
The build requires the MSVC CMAKE with Ninja support along with Python 2.7. These are
all available as components for the VisualStudio 2017 15.3+ Community installation. According
to the documentation they should all be available from the VisualStudio 2017 build tools installer
as well, though that hasn't been tested. 

### Running a local build
```PowerShell
.\scripts\Initialize-BuildEnv.ps1
build
```
