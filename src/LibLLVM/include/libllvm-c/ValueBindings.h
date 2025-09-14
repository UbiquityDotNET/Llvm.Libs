#ifndef _VALUE_BINDINGS_H_
#define _VALUE_BINDINGS_H_

#include "llvm-c/Core.h"
#include "ModuleBindings.h"

LLVM_C_EXTERN_C_BEGIN
    // ordering matters, all distinct values are generated first, then any derived values (e.g. foo = bar + 1), to ensure the
    // values match expectations of underlying C++ code and don't alter the sequencing as C++ numbers enum values without an
    // initializer as automatic +1 of the previous value, thus sticking the derived values in at arbitrary locations in the
    // declaration order would reset the values.

    typedef enum LibLLVMValueKind
    {
#define HANDLE_VALUE(Name) Name##Kind,
#define HANDLE_MEMORY_VALUE(Name) Name##Kind,
#define HANDLE_INSTRUCTION(Name) Name##Kind,
#include "llvm/IR/Value.def"
#undef HANDLE_VALUE
#undef HANDLE_MEMORY_VALUE
#undef HANDLE_INSTRUCTION

#define HANDLE_INST(N, OPC, CLASS) OPC##Kind = Instruction##Kind + N,
#define HANDLE_USER_INST(N, OPC, CLASS) OPC##Kind = Instruction##Kind + N,
#include "llvm/IR/Instruction.def"
#undef HANDLE_INST
#undef HANDLE_USER_INST

#define HANDLE_CONSTANT_MARKER(MarkerName, ValueName) MarkerName##Kind = ValueName##Kind,
#include "llvm/IR/Value.def"
#undef HANDLE_CONSTANT_MARKER
    }LibLLVMValueKind;

    LLVMBool LibLLVMIsConstantZeroValue( LLVMValueRef valueRef );
    void LibLLVMRemoveGlobalFromParent( LLVMValueRef valueRef );

    LibLLVMValueKind LibLLVMGetValueKind( LLVMValueRef valueRef);
    LLVMValueRef LibLLVMGetAliasee( LLVMValueRef Val );
    uint32_t LibLLVMGetArgumentIndex( LLVMValueRef Val);

    void LibLLVMGlobalVariableAddDebugExpression( LLVMValueRef /*GlobalVariable*/ globalVar, LLVMMetadataRef exp );
    void LibLLVMFunctionAppendBasicBlock( LLVMValueRef /*Function*/ function, LLVMBasicBlockRef block );
    LLVMValueRef LibLLVMValueAsMetadataGetValue( LLVMMetadataRef vmd );

    // Detect if a ConstantDataSequential is a C string (i8 sequence terminated with \0 and no embedded \0)
    LLVMBool LibLLVMIsConstantCString(LLVMValueRef C);

    // Retrieve the number of elements in a ConstantDataSequential
    uint32_t LibLLVMGetConstantDataSequentialElementCount( LLVMValueRef C );

    // retrieves the contents of a ConstantDataSequential
    // NOTE: The returned pointer does not guarantee a terminating '\0' the 'OUT'
    //       Length does contain the valid length of the data.
    const char* LibLLVMGetConstantDataSequentialRawData( LLVMValueRef C, size_t* Length );

    // Determines if an instruction has debug records
    // NOTE: if i is anything but an instruction this returns 0.
    // This is used to prevent access violations in calls to LLVMGetFirstDbgRecord()
    // where it assumes the value is an instruction AND that the DebugMarker is NOT
    // nullptr so it is dereference-able. However, if no Debug records are attached,
    // then LLVMGetFirstDbgRecord() will crash from a null pointer dereference. So,
    // this function is used to detect such a case before iterating the records.
    LLVMBool LibLLVMHasDbgRecords(LLVMValueRef i);
LLVM_C_EXTERN_C_END

#endif
