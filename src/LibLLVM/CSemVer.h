#ifndef _CSEMVER_H_
#define _CSEMVER_H_
#include <cstdint>
#include <limits>
#include <string_view>
#include <generatedversioninfo.h>

#define __LIBLLVM_PREPROC_MKSTRING(x) #x
#define LIBLLVM_PREPROC_MKSTRING(x) __LIBLLVM_PREPROC_MKSTRING(x)

namespace LibLLVM
{
    constexpr bool make_bool(std::string_view val)
    {
        using namespace std::string_view_literals;

        if (val == "true"sv || val == "True"sv || val == "TRUE"sv)
        {
            return true;
        }

        return false;
    }

    // validate ranges of preprocessor defines
    static_assert(PRODUCT_VERSION_MAJOR < std::numeric_limits<uint16_t>::max());
    static_assert(PRODUCT_VERSION_MINOR < std::numeric_limits<uint16_t>::max());
    static_assert(PRODUCT_VERSION_BUILD < std::numeric_limits<uint16_t>::max());
    static_assert(PRODUCT_VERSION_REVISION < std::numeric_limits<uint16_t>::max());

    // create typed constants from general untyped preprocessor defines
    constexpr uint64_t ProductVersionMajor = static_cast<uint64_t>(PRODUCT_VERSION_MAJOR);
    constexpr uint64_t ProductVersionMinor = static_cast<uint64_t>(PRODUCT_VERSION_MINOR);
    constexpr uint64_t ProductVersionBuild = static_cast<uint64_t>(PRODUCT_VERSION_BUILD);
    constexpr uint64_t ProductVersionRevision = static_cast<uint64_t>(PRODUCT_VERSION_REVISION);

    constexpr uint64_t FileVersion64
        = (ProductVersionMajor << 48)
        + (ProductVersionMinor << 32)
        + (ProductVersionBuild << 16)
        + ProductVersionRevision;

    // CI Builds use an ODD numbered file version, but the ordered version number ignores CI and meta data information for ordering
    constexpr uint64_t OrderedVersion = FileVersion64 >> 1;
}

#endif
