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

        if (val == "true" || val == "True"sv || val == "TRUE"sv)
        {
            return true;
        }

        if (val == "false" || val == "False"sv || val == "FALSE"sv)
        {
            return false;
        }

        return false;
    }

    constexpr bool IsReleaseBuild = make_bool(LIBLLVM_PREPROC_MKSTRING(LIBLLVM_RELEASE_BUILD));

    // For the purposes of CSemVer versioning, anything that isn't an official
    // release is a CI build. PR vs. local builds are distinguished by
    // the CSemVer-CI BuildIndex, BuidName etc... (Which are not part of the
    // binary ordered number or the FileVersion number.) The lowest bit of
    // the file version variation of the version indicates if it is a CI build
    // or not.
    constexpr bool IsCIBuild = !IsReleaseBuild;

    // validate ranges of preprocessor defines
    static_assert(PRODUCT_VERSION_MAJOR < std::numeric_limits<uint16_t>::max());
    static_assert(PRODUCT_VERSION_MINOR < std::numeric_limits<uint16_t>::max());
    static_assert(PRODUCT_VERSION_BUILD < std::numeric_limits<uint16_t>::max());
    static_assert(PRODUCT_VERSION_REVISION < std::numeric_limits<uint16_t>::max());

    static_assert((PRODUCT_VERSION_REVISION & 1) == 0, "Build Revision should not account for CI builds");

    // create typed constants from general untyped preprocessor defines
    constexpr uint64_t ProductVersionMajor = static_cast<uint64_t>(PRODUCT_VERSION_MAJOR);
    constexpr uint64_t ProductVersionMinor = static_cast<uint64_t>(PRODUCT_VERSION_MINOR);
    constexpr uint64_t ProductVersionBuild = static_cast<uint64_t>(PRODUCT_VERSION_BUILD);
    constexpr uint64_t ProductVersionRevision = static_cast<uint64_t>(PRODUCT_VERSION_REVISION);

    constexpr uint64_t OrderedVersion
        = (ProductVersionMajor << 48)
        + (ProductVersionMinor << 32)
        + (ProductVersionBuild << 16)
        + (ProductVersionRevision) >> 1;

    // CI Builds use an ODD numbered file version
    constexpr uint64_t FileVersion64 = (OrderedVersion << 1) + static_cast<uint64_t>(IsCIBuild ? 1 : 0);
}

#endif
