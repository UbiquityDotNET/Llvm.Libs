#include <type_traits>
#include <array>
#include <string_view>

#include "llvm/IR/Attributes.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Value.h"
#include "llvm/IR/Function.h"
#include "llvm/Support/CBindingWrapping.h"
#include "llvm-c/Error.h"
#include "libllvm-c/AttributeBindings.h"
#include "enum_flags.h"

using namespace llvm;
using namespace std::string_view_literals;

namespace
{
    const char* AllocateDisposeMessageFor(StringRef strRef)
    {
        // Make a copy of the StringRef that is compatible with LLVMDisposeMessage
        // While the str() method is there, it creates a COPY of the string to produce
        // an std::string which would then be allocated and copied again to form the
        // result. This skips the intermediate operations and leverages a single
        // allocation and copy for the result.
        auto pRetVal = (char*)malloc(strRef.size() + 1);
        if (pRetVal == nullptr)
        {
            return nullptr;
        }

        pRetVal[strRef.size()] = '\0';
        return strncpy(pRetVal, strRef.data(), strRef.size());
    }
}

extern "C"
{
    char const* LibLLVMAttributeToString(LLVMAttributeRef attribute)
    {
        // must use DisposeMessage pattern as the string is built on the fly
        // (not stored) and will not exist once this returns.
        return AllocateDisposeMessageFor(unwrap(attribute).getAsString());
    }

    LLVMBool LibLLVMIsConstantRangeAttribute(LLVMAttributeRef atrribute)
    {
        auto Attr = unwrap(atrribute);
        return Attr.isConstantRangeAttribute();
    }

    LLVMBool LibLLVMIsConstantRangeListAttribute(LLVMAttributeRef atrribute)
    {
        auto Attr = unwrap(atrribute);
        return Attr.isConstantRangeListAttribute();
    }

    STDEX_DECLARE_ENUM_FLAGS(LibLLVMAttributeAllowedOn);

    constexpr LibLLVMAttributeAllowedOn AllowedOnAll
        = LibLLVMAttributeAllowedOn_Return
        | LibLLVMAttributeAllowedOn_Parameter
        | LibLLVMAttributeAllowedOn_Function
        | LibLLVMAttributeAllowedOn_CallSite
        | LibLLVMAttributeAllowedOn_Global;

    static_assert(std::is_trivially_copyable_v<LibLLVMAttributeInfo>, "LibLLVMAttributeInfo must be blittable for stable ABI binding");

// VS IDE will see an error E0289 on the definition of AllKnownAttributeNames that is NOT anything
// that can be suppressed. It's JUST the IDE in editor experience for this declaration. (Hover, over
// the `AllKnownAttributeNames` in `LibLLVMGetNumKnownAttribs` below and it sees ALL the values.
// So it's just a problem with the in editor parsing not handling the #include for this limited
// case. Hopefully this is fixed with:
// https://developercommunity.visualstudio.com/t/CC-IntelliSense-reports-E0289-no-ins/10618237

    constexpr std::array AllKnownAttributeNames = {
#define GET_ATTR_NAMES
#define ATTRIBUTE_ALL(ENUM_NAME, DISPLAY_NAME) #DISPLAY_NAME,
#include "llvm/IR/Attributes.inc"
#undef ATTRIBUTE_ALL
#undef GET_ATTR_NAMES
    };

    size_t LibLLVMGetNumKnownAttribs()
    {
        return AllKnownAttributeNames.size() - 1;
    }

    LLVMErrorRef LibLLVMGetKnownAttributeNames( size_t namesLen, /*(OUT, char*[namesLen])*/char const** names)
    {
        auto actualSize = LibLLVMGetNumKnownAttribs();
        if( namesLen < actualSize)
        {
            return LLVMCreateStringError("Names array is too small, use LibLLVMGetNumKnownAttribs() to get the minimum required size");
        }

        for(size_t i = 0; i < actualSize; ++i)
        {
            names[i] = AllKnownAttributeNames[i];
        }
        return nullptr;
    }

    LLVMErrorRef LibLLVMGetAttributeInfo(char* attribName, size_t nameLen, /*[out, byref]*/ LibLLVMAttributeInfo* pInfo)
    {
        if(attribName == nullptr || nameLen == 0)
        {
            return LLVMCreateStringError("attribName is null or empty");
        }

        if (pInfo == nullptr)
        {
            return LLVMCreateStringError("Out ref parameter 'pInfo' is null!");
        }

        // initialize to all members default;
        *pInfo = {};

        // assume it is a custom string for simplicity of logic here.
        Attribute::AttrKind attribKind = Attribute::None;

        // Verify it is either a known string attribute or a known enumeration attribute
        if (Attribute::isExistingAttribute({attribName, nameLen}))
        {
            // It is a known attribute name, but it might be a string or an enum so figure out which...
            attribKind = Attribute::getAttrKindFromName(StringRef(attribName, nameLen));
        }

        pInfo->ID = static_cast<unsigned>(attribKind);
        if (attribKind == Attribute::None)
        {
            // It's string attribute (No ID), there's currently no way to determine
            // if a given string value is valid on any particular "index"
            // String attributes have no Enum ID either...
            pInfo->ArgKind = LibLLVMAttributeArgKind_String;
            pInfo->AllowedOn = AllowedOnAll;
            return nullptr;
        }

        // Enum attributes can have additional checks applied so provide details on that

        if (Attribute::isEnumAttrKind(attribKind))
        {
            pInfo->ArgKind = LibLLVMAttributeArgKind_None;
        }
        else if (Attribute::isIntAttrKind(attribKind))
        {
            pInfo->ArgKind = LibLLVMAttributeArgKind_Int;
        }
        else if (Attribute::isTypeAttrKind(attribKind))
        {
            pInfo->ArgKind = LibLLVMAttributeArgKind_Type;
        }
        else if (Attribute::isConstantRangeAttrKind(attribKind))
        {
            pInfo->ArgKind = LibLLVMAttributeArgKind_ConstantRange;
        }
        else if (Attribute::isConstantRangeListAttrKind(attribKind))
        {
            pInfo->ArgKind = LibLLVMAttributeArgKind_ConstantRangeList;
        }
        else
        {
            pInfo->ArgKind = LibLLVMAttributeArgKind_None;
        }

        pInfo->AllowedOn = LibLLVMAttributeAllowedOn_None;
        if (Attribute::canUseAsFnAttr(attribKind))
        {
            pInfo->AllowedOn |= LibLLVMAttributeAllowedOn_Function;
        }

        if (Attribute::canUseAsParamAttr(attribKind))
        {
            pInfo->AllowedOn |= LibLLVMAttributeAllowedOn_Parameter;
        }

        if (Attribute::canUseAsRetAttr(attribKind))
        {
            pInfo->AllowedOn |= LibLLVMAttributeAllowedOn_Return;
        }

        return nullptr;
    }

    char const* LibLLVMGetAttributeNameFromID(uint32_t id, /*[Out]*/ uint32_t* len)
    {
        // getNameFromAttrKind() will hard assert/crash if given an out of range ID
        // deal with that here and provide a known empty value
        if( id >= (uint32_t)Attribute::AttrKind::EndAttrKinds )
        {
            *len = 0;
            return nullptr;
        }

        StringRef stringRefVal = Attribute::getNameFromAttrKind(static_cast<Attribute::AttrKind>(id));
        *len = stringRefVal.size();
        return stringRefVal.data();
    }
}
