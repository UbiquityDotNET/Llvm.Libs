#include <llvm-c/Target.h>
#include <llvm-c/Remarks.h>

extern "C"
{
    // This is part of the LLVM REMARKS shared lib in the tools, but oddly not part of the
    // the core, which is where all the other remarks APIs live... Go, Figure!
    uint32_t LLVMRemarkVersion(void)
    {
        return REMARKS_API_VERSION;
    }
}
