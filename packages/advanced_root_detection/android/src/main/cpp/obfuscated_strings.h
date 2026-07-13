#pragma once
#include <string>
#include <array>

/**
 * Compile-time XOR string obfuscation.
 *
 * Sensitive path strings are XOR-encrypted at compile time so they do not
 * appear in plain-text in `strings libshield.so`.
 *
 * Usage:
 *   auto path = OBFUSCATE("/system/bin/su");
 *   // path is a std::string with the decrypted value
 */

namespace shield {

static constexpr uint8_t XOR_KEY = 0x5A;

template<size_t N>
struct ObfuscatedString {
    std::array<char, N> data;

    constexpr ObfuscatedString(const char (&str)[N]) {
        for (size_t i = 0; i < N; ++i) {
            data[i] = static_cast<char>(str[i] ^ XOR_KEY);
        }
    }

    std::string decrypt() const {
        std::string result(N - 1, '\0');
        for (size_t i = 0; i < N - 1; ++i) {
            result[i] = static_cast<char>(data[i] ^ XOR_KEY);
        }
        return result;
    }
};

#define OBFUSCATE(s) (shield::ObfuscatedString<sizeof(s)>(s).decrypt())

} // namespace shield
