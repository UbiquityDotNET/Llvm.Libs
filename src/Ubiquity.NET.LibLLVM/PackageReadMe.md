# Ubiquity.NET.LibLLVM
This package contains the binary dynamically loaded library for the native interop with LLVM.
To keep size within the constraints of public hosting it is a "meta" package that references
the actual native libraries on a per RID basis. This package also includes the headers used
to access the library. While C# doesn't use the headers directly, they are available for
parsing by tools to generate as much as possible of the low level interop API surface.
