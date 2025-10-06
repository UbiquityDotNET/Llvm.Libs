#ifndef _OUTPUTDEBUGSTREAM_H_
#define _OUTPUTDEBUGSTREAM_H_

#if defined(DEBUG) || !defined(NDEBUG)
#include <ios>
#include <sstream>
#include <ostream>
#endif

#if defined(_WIN32)
#include <Windows.h>
#endif

#include <llvm/Support/raw_os_ostream.h>

namespace LibLLVM
{
// Currently only windows DEBUG builds provide support for debug output
// It is at least plausible to extend to other platforms if they have
// equivalent APIs to ::OutputDebugString(A|W) in Windows.
#if defined(_WIN32) && defined(DEBUG)
    ////////////////////////////////////////////////////
    // Description:
    //    C++ stream buffer for Win32 OutputDebugString()
    //
    class OutputDebugStreamBuffer
        : public std::stringbuf
    {
    public:
        OutputDebugStreamBuffer()
            : std::stringbuf(std::ios_base::out)
        {
        }

    protected:
        virtual int sync() override
        {
            ::OutputDebugStringA(std::stringbuf::str().c_str());
            str("");
            return 0;
        }
    };

    ///////////////////////////////////////////////////////////////
    // Description:
    //    C++ stream class for Win32 OutputDebugString()
    //
    class OutputDebugStream
        : public std::ostream
    {
        OutputDebugStreamBuffer Buf;

    public:
        OutputDebugStream()
            : std::ostream(&Buf, false)
        {
            clear();
        }
    };

    inline OutputDebugStream cdbg;

    class raw_debug_ostream
        : public llvm::raw_os_ostream
    {
    public:
        raw_debug_ostream()
            : llvm::raw_os_ostream(cdbg)
        {
        }
    };
#else
    using raw_debug_ostream = llvm::raw_null_ostream;
#endif
}
#endif
