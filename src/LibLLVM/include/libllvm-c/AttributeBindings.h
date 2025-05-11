//===- AttributeBindings.h - Additional bindings for IR ----------------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file defines additional C bindings for LLVM Attributes IR Attributes.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_BINDINGS_LLVM_ATTRIBUTEBINDINGS_H
#define LLVM_BINDINGS_LLVM_ATTRIBUTEBINDINGS_H

#include <llvm-c/Core.h>
#include <llvm-c/Types.h>

#include <stdint.h>

LLVM_C_EXTERN_C_BEGIN

    enum LibLLVMAttributeArgKind
    {
        LibLLVMAttributeArgKind_None,
        LibLLVMAttributeArgKind_Int,
        LibLLVMAttributeArgKind_Type,
        LibLLVMAttributeArgKind_ConstantRange,
        LibLLVMAttributeArgKind_ConstantRangeList,
        LibLLVMAttributeArgKind_String, // NOTE: if argkind is string then ID is 0
                                        // String args MAY be BOOL 'true' 'false' but that is a constraint on the value as a string!
    };

    enum LibLLVMAttributeAllowedOn
    {
        LibLLVMAttributeAllowedOn_None,
        LibLLVMAttributeAllowedOn_Return = 0x0001,
        LibLLVMAttributeAllowedOn_Parameter = 0x0002,
        LibLLVMAttributeAllowedOn_Function = 0x0004,
        LibLLVMAttributeAllowedOn_CallSite = 0x0008,
        LibLLVMAttributeAllowedOn_Global = 0x0010,
    };

    struct LibLLVMAttributeInfo
    {
        unsigned ID;
        LibLLVMAttributeArgKind ArgKind;
        LibLLVMAttributeAllowedOn AllowedOn;
    };

    // Gets the number of attributes known by this implementation/runtime
    // The value this returns is used to allocate and array of `char const*`
    // to use with the LibLLVMGetKnownAttributeNames() API.
    size_t LibLLVMGetNumKnownAttribs();

    // Fills in an array of const string pointers. No deallocation is needed for each as
    // they are global static constants.
    LLVMErrorRef LibLLVMGetKnownAttributeNames(/*(OUT, char*[namesLen])*/char const** names, size_t namesLen);

    // Caller must dispose returned string with DisposeMessage() as it is created
    // on the fly so it must be disposed of when no longer needed.
    char const* LibLLVMAttributeToString( LLVMAttributeRef attribute );

    // Sadly these two kinds of attributes were left out of the official LLVM-C API
    LLVMBool LibLLVMIsConstantRangeAttribute(LLVMAttributeRef atrribute);
    LLVMBool LibLLVMIsConstantRangeListAttribute(LLVMAttributeRef atrribute);

    LLVMErrorRef LibLLVMGetAttributeInfo(char* attribName, size_t nameLen, /*[out, byref]*/ LibLLVMAttributeInfo* pInfo);

    // NOTE: String attributes will have a name of "none" as the ID is 0
    // NOTE: Out of range IDs will have an empty string (ret: nullptr, *len: 0)
    char const* LibLLVMGetAttributeNameFromID(uint32_t id, /*[Out]*/ uint32_t* len);
LLVM_C_EXTERN_C_END
#endif
