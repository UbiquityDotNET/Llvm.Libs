#ifndef _ENUM_FLAGS_H_
#define _ENUM_FLAGS_H_


#include <type_traits>
#include <cstdint>

namespace stdex
{
#if __cpp_lib_to_underlying >= 202102L // cpp23: C++23 feature __cpp_lib_to_underlying
    template<typename T>
    constexpr auto to_underlying = std::to_underlying<T>;
#elif __cpp_lib_concepts >= 202207L
    /// <summary>Concept to detect enumeration types</summary>
    template<typename T>
    concept enumeration = std::is_enum_v<T>;

    // NOTE: This creates a stronger constraint than even the official C++23 variant
    //       as it employs an enumeration concept to constrain the input type...
    template<enumeration e>
    inline constexpr auto to_underlying(e value) noexcept
    {
        return static_cast<std::underlying_type_t<e>>(value);
    }
#else
    template<typename T>
    constexpr auto to_underlying(T value) noexcept
    {
        return static_cast<std::underlying_type_t<T>>(value);
    }
#endif
}

// while windows has an equivalent of this, the stdex lib is trying to remain free of any
// specific windows or other headers beyond the standard library. This helps in preventing
// cyclical dependencies and avoids the issues of 'header "x" must be included before header
// "Y" to get functionality "Z"'. (Unfortunately WIL has several cases of this for Windows
// support, std and C++/WinRT. All headers in stdex should have no dependencies beyond what is
// in the C++ standard library (and stdex headers themselves)
#ifdef DEFINE_ENUM_FLAG_OPERATORS
#define STDEX_DECLARE_ENUM_FLAGS(enum_t) DEFINE_ENUM_FLAG_OPERATORS(enum_t)
#else
#define STDEX_DECLARE_ENUM_FLAGS(enum_t) \
inline constexpr enum_t operator|(enum_t a, enum_t b) noexcept \
{ \
    return enum_t(stdex::to_underlying(a) | stdex::to_underlying(b)); \
} \
 \
inline enum_t& operator|= (enum_t& a, enum_t b) noexcept \
{ \
    return (enum_t&)(((std::underlying_type_t<enum_t>&)a) |= stdex::to_underlying(b)); \
} \
 \
inline constexpr enum_t operator&(enum_t a, enum_t b) noexcept \
{ \
    return enum_t(stdex::to_underlying(a) & stdex::to_underlying(b)); \
} \
 \
inline enum_t& operator&=(enum_t& a, enum_t b) noexcept \
{ \
    return (enum_t&)(((std::underlying_type_t<enum_t> &)a) &= stdex::to_underlying(b)); \
} \
 \
inline constexpr enum_t operator~(enum_t a) noexcept \
{ \
    return enum_t(~stdex::to_underlying(a)); \
} \
 \
inline constexpr enum_t operator^(enum_t a, enum_t b) noexcept \
{ \
    return enum_t(stdex::to_underlying(a) ^ stdex::to_underlying(b)); \
} \
 \
inline enum_t& operator^=(enum_t& a, enum_t b) noexcept \
{ \
    return (enum_t&)(((std::underlying_type_t<enum_t> &)a) ^= stdex::to_underlying(b)); \
};
#endif

#if __cpp_lib_concepts >= 202207L
namespace stdex
{
    // CONSIDER: Adapting this concept to any type that supports the operations;
    // restricting to enums is an arbitrary choice that limits more generic use.

    /// <summary>Concept for enumeration supporting flags operations</summary>
    /// <remarks>
    /// Some enumerated types are intended for use as bit flags. This concept
    /// is used to constrain enumeration types to those that support such
    /// operations. These are normally provided using the STDEX_DECLARE_ENUM_FLAGS(T)
    /// macro (Or, if using Windows headers, the DEFINE_ENUM_FLAG_OPERATORS(T)
    /// macro. Either, but not both, macros is valid)
    /// NOTE:
    /// Ideally, all enum flags should have an unsigned underlying type. Unfortunately,
    /// unscoped enums have an underlying type of that depends on the size of the enumerated
    /// values and might be signed or unsigned. (C++ spec leaves it at discretion of the compiler)
    /// </remarks>
    template<typename T>
    concept enumeration_flags
        = enumeration<T>
#if __cpp_lib_is_scoped_enum >= 202011L // cpp23: C++23 feature __cpp_lib_is_scoped_enum
        && (!std::is_scoped_enum<T> || std::unsigned_integral<std::underlying_type_t<T>>) // scoped flags enum should have an unsigned underlying type
#endif
        && requires (T a, T b)
    {
        // Simple bitwise operators
        { a | b } noexcept ->std::same_as<T>;
        { a& b } noexcept ->std::same_as<T>;
        { a^ b } noexcept ->std::same_as<T>;

        // complex bitwise assignment operators (return a reference)
        { a |= b } noexcept ->std::same_as<T&>;
        { a &= b } noexcept ->std::same_as<T&>;
        { a ^= b } noexcept ->std::same_as<T&>;

        // unary bitwise operator
        { ~a } noexcept -> std::same_as<T>;
    };

    // CONSIDER: Adapting flag tests to integral values without enum constraint

    template<enumeration_flags T>
    inline constexpr T clear_flags(T value, T allowedMask) noexcept
    {
        return value & (~allowedMask);
    }

    template<enumeration_flags T>
    inline constexpr bool are_all_flags_clear(T value, T maskToTest) noexcept
    {
        return 0 == to_underlying(value & maskToTest);
    }

    template<enumeration_flags T>
    inline constexpr bool are_all_flags_set(T value, T maskToTest) noexcept
    {
        return to_underlying(maskToTest) == to_underlying(value & maskToTest);
    }

    template<enumeration_flags T>
    inline constexpr bool are_any_flags_set(T value, T maskToTest) noexcept
    {
        return (to_underlying(maskToTest) & to_underlying(value & maskToTest)) != 0;
    }

    template<enumeration_flags T>
    constexpr bool has_single_bit_set(T flags)
    {
        using namespace stdex;

        return std::has_single_bit(unsigned_cast(to_underlying(flags)));
    }

    template<enumeration_flags T>
    constexpr bool is_zero_or_has_single_bit_set(T flags)
    {
        using namespace stdex;
        auto underlyingUInt = unsigned_cast(to_underlying(flags));
        return underlyingUInt == 0 || std::has_single_bit(underlyingUInt);
    }

    template<enumeration_flags T, T maskToTest>
        requires (has_single_bit_set(maskToTest)) // maskToTest should contain exactly 1 bit set
    inline constexpr bool is_flag_clear(T value) noexcept
    {
        return are_all_flags_clear(value, maskToTest);
    }

    template<enumeration_flags T, T maskToTest>
        requires (has_single_bit_set(maskToTest)) // maskToTest should contain exactly 1 bit set
    inline constexpr bool is_flag_set(T value) noexcept
    {
        return are_all_flags_set(value, maskToTest);
    }

    /// <summary>Variable template for a mask with a given bit position and width</summary>
    /// <typeparam name="pos">Bit position</typeparam>
    /// <typeparam name="width">Bit width of the mask</typeparam>
    /// <typeparam name="value_t">Type of value the mask is for</typeparam>
    template<std::uint8_t pos, std::uint8_t width, std::unsigned_integral value_t>
        requires (stdex::bitwidth_of<value_t> >= (pos + width))
    inline constexpr value_t bit_mask = ((1 << width) - 1) << pos;

    /// <summary>Computes a mask for a field and extracts those bits</summary>
    /// <typeparam name="result_t"></typeparam>
    /// <typeparam name="pos"></typeparam>
    /// <typeparam name="width"></typeparam>
    /// <typeparam name="value_t"></typeparam>
    /// <param name="f"></param>
    /// <returns></returns>
    template<std::uint8_t pos, std::uint8_t width, std::unsigned_integral value_t>
        requires (stdex::bitwidth_of<value_t> >= (pos + width))  // Input must have enough bits to source the field
    inline constexpr value_t get_bit_field(value_t f)
    {
        return (f & bit_mask<pos, width, value_t>);
    }

    // compile time unit test as a constexpr
    static_assert(get_bit_field<3, 2>(0b1010'1010'1001'1111ui16) == (0b0000'0000'0001'1000ui16));
}
#endif // C++ concepts

#endif // Include guard

