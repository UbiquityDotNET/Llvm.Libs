#ifndef _MODULE_BINDINGS_H_
#define _MODULE_BINDINGS_H_

#include "llvm-c/Core.h"
#include "llvm-c/Comdat.h"

LLVM_C_EXTERN_C_BEGIN
    typedef struct LLVMOpaqueComdatIterator* LibLLVMComdatIteratorRef;

    uint32_t LibLLVMModuleGetNumComdats(LLVMModuleRef module);
    LLVMComdatRef LibLLVMModuleGetComdat(LLVMModuleRef module, char const* name);
    LibLLVMComdatIteratorRef LibLLVMModuleBeginComdats(LLVMModuleRef module);
    LLVMComdatRef LibLLVMCurrentComdat(LibLLVMComdatIteratorRef it);
    LLVMBool LibLLVMMoveNextComdat(LibLLVMComdatIteratorRef it);
    void LibLLVMModuleComdatIteratorReset(LibLLVMComdatIteratorRef it);
    void LibLLVMDisposeComdatIterator(LibLLVMComdatIteratorRef it);

    LLVMValueRef LibLLVMGetOrInsertFunction( LLVMModuleRef module, const char* name, LLVMTypeRef functionType );
    char const* LibLLVMGetModuleSourceFileName( LLVMModuleRef module );
    void LibLLVMSetModuleSourceFileName( LLVMModuleRef module, char const* name );
    char const* LibLLVMGetModuleName( LLVMModuleRef module );
    LLVMValueRef LibLLVMGetGlobalAlias( LLVMModuleRef module, char const* name );

    LLVMComdatRef LibLLVMModuleInsertOrUpdateComdat( LLVMModuleRef module, char const* name, LLVMComdatSelectionKind kind );
    void LibLLVMModuleComdatRemove( LLVMModuleRef module, LLVMComdatRef comdatRef );
    void LibLLVMModuleComdatClear( LLVMModuleRef module );

    // Result MAYBE NULL, caller does not free the result, but should
    // copy it as it can change or otherwise be freed.
    char const* LibLLVMComdatGetName(LLVMComdatRef comdatRef, size_t* len);

    // Alias enumeration
    LLVMValueRef LibLLVMModuleGetFirstGlobalAlias( LLVMModuleRef M );
    LLVMValueRef LibLLVMModuleGetNextGlobalAlias( LLVMValueRef /*GlobalAlias*/ valueRef );
LLVM_C_EXTERN_C_END

#endif
