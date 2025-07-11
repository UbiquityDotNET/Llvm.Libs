//===- IRBindings.h - Additional bindings for IR ----------------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file defines additional C bindings for the IR component.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_BINDINGS_LLVM_IRBINDINGS_H
#define LLVM_BINDINGS_LLVM_IRBINDINGS_H

#include <llvm-c/Core.h>
#include <llvm-c/ExecutionEngine.h>

LLVM_C_EXTERN_C_BEGIN
    LLVMBool LibLLVMHasUnwindDest( LLVMValueRef Invoke );
LLVM_C_EXTERN_C_END

#endif
