//===- IRBindings.cpp - Additional bindings for ir ------------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file defines additional C bindings for the ir component.
//
//===----------------------------------------------------------------------===//
#include <llvm-c/Types.h>
#include "libllvm-c/IRBindings.h"

#include <llvm/IR/Value.h>
#include <llvm/IR/Instructions.h>
#include <llvm/Support/Casting.h>

using namespace llvm;

extern "C"
{
    LLVMBool LibLLVMHasUnwindDest( LLVMValueRef Invoke )
    {
        if ( CleanupReturnInst* CRI = dyn_cast< CleanupReturnInst >( unwrap( Invoke ) ) )
        {
            return CRI->hasUnwindDest( );
        }
        else if ( CatchSwitchInst* CSI = dyn_cast< CatchSwitchInst >( unwrap( Invoke ) ) )
        {
            return CSI->hasUnwindDest( );
        }
        return 0;
    }

}
