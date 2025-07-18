#include <llvm-c/Core.h>
#include <llvm/IR/DIBuilder.h>
#include <llvm/IR/Module.h>
#include <llvm/Support/CBindingWrapping.h>

#include "libllvm-c/MetadataBindings.h"

using namespace llvm;

DEFINE_SIMPLE_CONVERSION_FUNCTIONS( MDOperand, LibLLVMMDOperandRef )

template <typename DIT> DIT* unwrapDI( LLVMMetadataRef Ref )
{
    return (DIT* )( Ref ? unwrap<MDNode>( Ref ) : nullptr );
}

static DINode::DIFlags map_from_llvmDIFlags( LLVMDIFlags Flags )
{
    return static_cast< DINode::DIFlags >( Flags );
}

static LLVMDIFlags map_to_llvmDIFlags( DINode::DIFlags Flags )
{
    return static_cast< LLVMDIFlags >( Flags );
}

static DISubprogram::DISPFlags
pack_into_DISPFlags( bool IsLocalToUnit, bool IsDefinition, bool IsOptimized )
{
    return DISubprogram::toSPFlags( IsLocalToUnit, IsDefinition, IsOptimized );
}

extern "C"
{
    LLVMContextRef LibLLVMGetNodeContext( LLVMMetadataRef /*MDNode*/ node )
    {
        MDNode* pNode = unwrap<MDNode>( node );
        return wrap( &pNode->getContext( ) );
    }

    LibLLVMDwarfAttributeEncoding LibLLVMDIBasicTypeGetEncoding( LLVMMetadataRef /*DIBasicType*/ basicType )
    {
        return static_cast< LibLLVMDwarfAttributeEncoding >( unwrap<DIBasicType>( basicType )->getEncoding( ) );
    }

    LLVMMetadataRef /*DILocalScope*/ LibLLVMDILocationGetInlinedAtScope( LLVMMetadataRef /*DILocation*/ location )
    {
        DILocation* loc = unwrap<DILocation>( location );
        return wrap( loc->getInlinedAtScope( ) );
    }

    LibLLVMDwarfTag LibLLVMDIDescriptorGetTag( LLVMMetadataRef descriptor )
    {
        DINode* desc = unwrap<DINode>( descriptor );
        return (LibLLVMDwarfTag )desc->getTag( );
    }

    LLVMDWARFEmissionKind LibLLVMDiCompileUnitGetEmissionKind( LLVMMetadataRef handle)
    {
        DICompileUnit* pCU = unwrap<DICompileUnit>(handle);
        return (LLVMDWARFEmissionKind)pCU->getEmissionKind();
    }

    LLVMMetadataRef LibLLVMDIBuilderCreateTempFunctionFwdDecl( LLVMDIBuilderRef Builder
                                                               , LLVMMetadataRef /*DIScope* */Scope
                                                               , char const* Name
                                                               , size_t NameLen
                                                               , char const* LinkageName
                                                               , size_t LinkageNameLen
                                                               , LLVMMetadataRef /*DIFile* */ File
                                                               , unsigned LineNo
                                                               , LLVMMetadataRef /*DISubroutineType* */ Ty
                                                               , LLVMBool isLocalToUnit
                                                               , LLVMBool isDefinition
                                                               , unsigned ScopeLine
                                                               , LLVMDIFlags Flags /*= 0*/
                                                               , LLVMBool isOptimized /*= false*/
    )
    {
        return wrap( unwrap( Builder )->createTempFunctionFwdDecl(
            unwrapDI<DIScope>( Scope ),
            { Name, NameLen },
            { LinkageName, LinkageNameLen },
            unwrapDI<DIFile>( File ),
            LineNo,
            unwrapDI<DISubroutineType>( Ty ),
            ScopeLine,
            map_from_llvmDIFlags( Flags ),
            pack_into_DISPFlags( isLocalToUnit, isDefinition, isOptimized ),
            nullptr,
            nullptr,
            nullptr ) );
    }

    char const* LibLLVMMetadataAsString( LLVMMetadataRef descriptor )
    {
        std::string Messages;
        raw_string_ostream Msg( Messages );
        Metadata* d = unwrap<Metadata>( descriptor );
        d->print( Msg );
        return LLVMCreateMessage( Msg.str( ).c_str( ) );
    }

    uint32_t LibLLVMMDNodeGetNumOperands( LLVMMetadataRef /*MDNode*/ node )
    {
        MDNode* pNode = unwrap<MDNode>( node );
        return pNode->getNumOperands( );
    }

    LibLLVMMDOperandRef LibLLVMMDNodeGetOperand( LLVMMetadataRef /*MDNode*/ node, uint32_t index )
    {
        MDNode* pNode = unwrap<MDNode>( node );
        return wrap( &pNode->getOperand( index ) );
    }

    void LibLLVMMDNodeReplaceOperand( LLVMMetadataRef /* MDNode */ node, uint32_t index, LLVMMetadataRef operand )
    {
        unwrap<MDNode>( node )->replaceOperandWith( index, unwrap( operand ) );
    }

    LLVMMetadataRef LibLLVMGetOperandNode( LibLLVMMDOperandRef operand )
    {
        MDOperand const* pOperand = unwrap( operand );
        return wrap( pOperand->get( ) );
    }

    LLVMModuleRef LibLLVMNamedMetadataGetParentModule( LLVMNamedMDNodeRef namedMDNode )
    {
        auto pMDNode = unwrap( namedMDNode );
        return wrap( pMDNode->getParent( ) );
    }

    void LibLLVMNamedMetadataEraseFromParent( LLVMNamedMDNodeRef namedMDNode )
    {
        unwrap( namedMDNode )->eraseFromParent( );
    }

    LLVMMetadataKind LibLLVMGetMetadataID( LLVMMetadataRef /*Metadata*/ md )
    {
        Metadata* pMetadata = unwrap( md );
        return (LLVMMetadataKind )pMetadata->getMetadataID( );
    }

    unsigned LibLLVMNamedMDNodeGetNumOperands( LLVMNamedMDNodeRef namedMDNode )
    {
        auto pMDNode = unwrap( namedMDNode );
        return pMDNode->getNumOperands( );
    }

    LLVMMetadataRef LibLLVMNamedMDNodeGetOperand( LLVMNamedMDNodeRef namedMDNode, unsigned index )
    {
        auto pMDNode = unwrap( namedMDNode );
        if ( index >= pMDNode->getNumOperands( ) )
            return nullptr;

        return wrap( pMDNode->getOperand( index ) );
    }

    void LibLLVMNamedMDNodeSetOperand( LLVMNamedMDNodeRef namedMDNode, unsigned index, LLVMMetadataRef /*MDNode*/ node )
    {
        auto pMDNode = unwrap( namedMDNode );
        if ( index >= pMDNode->getNumOperands( ) )
            return;

        pMDNode->setOperand( index, unwrap<MDNode>( node ) );
    }

    void LibLLVMNamedMDNodeAddOperand( LLVMNamedMDNodeRef namedMDNode, LLVMMetadataRef /*MDNode*/ node )
    {
        auto pMDNode = unwrap( namedMDNode );
        pMDNode->addOperand( unwrap<MDNode>( node ) );
    }

    void LibLLVMNamedMDNodeClearOperands( LLVMNamedMDNodeRef namedMDNode )
    {
        unwrap( namedMDNode )->clearOperands( );
    }

    LLVMMetadataRef LibLLVMConstantAsMetadata( LLVMValueRef C )
    {
        return wrap( ConstantAsMetadata::get( unwrap<Constant>( C ) ) );
    }

    void LibLLVMAddNamedMetadataOperand2( LLVMModuleRef M
                                          , char const* name
                                          , LLVMMetadataRef Val
    )
    {
        NamedMDNode* N = unwrap( M )->getOrInsertNamedMetadata( name );
        if ( !N )
            return;

        if ( !Val )
            return;

        N->addOperand( unwrap<MDNode>( Val ) );
    }

    void LibLLVMSetMetadata2( LLVMValueRef Inst, unsigned KindID, LLVMMetadataRef MD )
    {
        MDNode* N = MD ? unwrap<MDNode>( MD ) : nullptr;
        unwrap<Instruction>( Inst )->setMetadata( KindID, N );
    }

    LLVMBool LibLLVMIsTemporary( LLVMMetadataRef M )
    {
        auto pMetadata = unwrap<MDNode>( M );
        return pMetadata->isTemporary( );
    }

    LLVMBool LibLLVMIsResolved( LLVMMetadataRef M )
    {
        auto pMetadata = unwrap<MDNode>( M );
        return pMetadata->isResolved( );
    }

    LLVMBool LibLLVMIsUniqued( LLVMMetadataRef M )
    {
        auto pMetadata = unwrap<MDNode>( M );
        return pMetadata->isUniqued( );
    }

    LLVMBool LibLLVMIsDistinct( LLVMMetadataRef M )
    {
        auto pMetadata = unwrap<MDNode>( M );
        return pMetadata->isDistinct( );
    }

    char const* LibLLVMGetMDStringText( LLVMMetadataRef mdstring, unsigned* len )
    {
        MDString const* S = unwrap<MDString>( mdstring );
        *len = S->getString( ).size( );
        return S->getString( ).data( );
    }

    int64_t LibLLVMDISubRangeGetLowerBounds( LLVMMetadataRef /*DISubRange*/ sr, int64_t defaultLowerBound )
    {
        DISubrange const* subRange = unwrap<DISubrange>( sr );

        // Node might not have a subrange, it's optional
        ConstantInt* pBound = dyn_cast_if_present<ConstantInt*>(subRange->getLowerBound());
        return (pBound) ? pBound->getSExtValue() : defaultLowerBound;
    }
}
