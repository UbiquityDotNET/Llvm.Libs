#ifndef LLVM_BINDINGS_LLVM_METADATABINDINGS_H
#define LLVM_BINDINGS_LLVM_METADATABINDINGS_H

#include <stdint.h>
#include "llvm-c/Core.h"
#include "llvm-c/DebugInfo.h"

LLVM_C_EXTERN_C_BEGIN
    typedef enum LibLLVMDwarfTag
    {
#define HANDLE_DW_TAG(ID, NAME, VERSION, VENDOR, KIND) \
  LibLLVMDwarfTag##NAME = ID,
#include "llvm/BinaryFormat/Dwarf.def"
#undef HANDLE_DW_TAG
    } LibLLVMDwarfTag;

    typedef enum LibLLVMDwarfAttributeEncoding
        : uint8_t
    {
#define HANDLE_DW_ATE(ID, NAME, VERSION, VENDOR) DW_ATE_##NAME = ID,
#include "llvm/BinaryFormat/Dwarf.def"
#undef HANDLE_DW_ATE
        DW_ATE_lo_user = 0x80,
        DW_ATE_hi_user = 0xff
    }LibLLVMDwarfTypeKind;

    // NOTE: This enum is a replication of Metadata::MetadataKind, it is distinct from
    // the LLVM-C definition of LLVMMetadataKind as that ONLY includes definitions for
    // what is included in debug information. (rather than ANY metadata)
    typedef enum LibLLVMMetadataKind
    {
#define HANDLE_METADATA_LEAF(CLASS) LibLLVMMetadataKind_##CLASS,
#include "llvm/IR/Metadata.def"
#undef HANDLE_METADATA_LEAF
    } LibLLVMMetadataKind;

    typedef struct LLVMOpaqueMDOperand* LibLLVMMDOperandRef;

    LibLLVMDwarfAttributeEncoding LibLLVMDIBasicTypeGetEncoding( LLVMMetadataRef /*DIBasicType*/ basicType );
    LLVMContextRef LibLLVMGetNodeContext( LLVMMetadataRef /*MDNode*/ node );
    LLVMDWARFEmissionKind LibLLVMDiCompileUnitGetEmissionKind(LLVMMetadataRef handle);

    LLVMMetadataRef LibLLVMDIBuilderCreateTempFunctionFwdDecl( LLVMDIBuilderRef D
                                                               , LLVMMetadataRef /*DIScope* */Scope
                                                               , char const* Name
                                                               , size_t NameLen
                                                               , char const* LinkageName
                                                               , size_t LinakgeNameLen
                                                               , LLVMMetadataRef /*DIFile* */ File
                                                               , unsigned LineNo
                                                               , LLVMMetadataRef /*DISubroutineType* */ Ty
                                                               , LLVMBool isLocalToUnit
                                                               , LLVMBool isDefinition
                                                               , unsigned ScopeLine
                                                               , LLVMDIFlags Flags /*= 0*/
                                                               , LLVMBool isOptimized /*= false*/
    );

    LibLLVMDwarfTag LibLLVMDIDescriptorGetTag( LLVMMetadataRef descriptor );
    //LLVMMetadataRef /*DILocation*/ LibLLVMDILocationGetInlinedAt( LLVMMetadataRef /*DILocation*/ location );
    LLVMMetadataRef /*DILocalScope*/ LibLLVMDILocationGetInlinedAtScope( LLVMMetadataRef /*DILocation*/ location );

    // caller must call LLVMDisposeMessage() on the returned string
    char const* LibLLVMMetadataAsString( LLVMMetadataRef descriptor );

    uint32_t LibLLVMMDNodeGetNumOperands( LLVMMetadataRef /*MDNode*/ node );
    LibLLVMMDOperandRef LibLLVMMDNodeGetOperand( LLVMMetadataRef /*MDNode*/ node, uint32_t index );
    void LibLLVMMDNodeReplaceOperand( LLVMMetadataRef /* MDNode */ node, uint32_t index, LLVMMetadataRef operand );
    LLVMMetadataRef LibLLVMGetOperandNode( LibLLVMMDOperandRef operand );

    LLVMModuleRef LibLLVMNamedMetadataGetParentModule( LLVMNamedMDNodeRef namedMDNode );
    void LibLLVMNamedMetadataEraseFromParent( LLVMNamedMDNodeRef namedMDNode );
    LLVMMetadataKind LibLLVMGetMetadataID( LLVMMetadataRef /*Metadata*/ md );

    unsigned LibLLVMNamedMDNodeGetNumOperands( LLVMNamedMDNodeRef namedMDNode );
    /*MDNode*/ LLVMMetadataRef LibLLVMNamedMDNodeGetOperand( LLVMNamedMDNodeRef namedMDNode, unsigned index );
    void LibLLVMNamedMDNodeSetOperand( LLVMNamedMDNodeRef namedMDNode, unsigned index, LLVMMetadataRef /*MDNode*/ node );
    void LibLLVMNamedMDNodeAddOperand( LLVMNamedMDNodeRef namedMDNode, LLVMMetadataRef /*MDNode*/ node );
    void LibLLVMNamedMDNodeClearOperands( LLVMNamedMDNodeRef namedMDNode );

    LLVMMetadataRef LibLLVMConstantAsMetadata( LLVMValueRef Val );

    char const* LibLLVMGetMDStringText( LLVMMetadataRef mdstring, unsigned* len );

    void LibLLVMAddNamedMetadataOperand2( LLVMModuleRef M, const char* name, LLVMMetadataRef Val );
    void LibLLVMSetMetadata2( LLVMValueRef Inst, unsigned KindID, LLVMMetadataRef MD );

    LLVMBool LibLLVMIsTemporary( LLVMMetadataRef M );
    LLVMBool LibLLVMIsResolved( LLVMMetadataRef M );
    LLVMBool LibLLVMIsUniqued( LLVMMetadataRef M );
    LLVMBool LibLLVMIsDistinct( LLVMMetadataRef M );

    int64_t LibLLVMDISubRangeGetLowerBounds( LLVMMetadataRef /*DISubRange*/ sr, int64_t defaultLowerBound );
LLVM_C_EXTERN_C_END

#endif
