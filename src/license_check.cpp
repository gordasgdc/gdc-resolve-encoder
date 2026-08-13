#include "license_check.h"
#include "vendor/ed25519/ed25519.h"
extern "C" {
#include "vendor/ed25519/sha512.h"
}

#include <vector>
#include <cstring>
#include <algorithm>
#include <cctype>
#include <ctime>
#include <cstdlib>
#include <fstream>
#include <filesystem>

#if defined(_WIN32)
    #include <windows.h>
#elif defined(__APPLE__)
    #include <IOKit/IOKitLib.h>
    #include <CoreFoundation/CoreFoundation.h>
#else
    // Linux: /etc/machine-id, citit direct ca fisier text mai jos
#endif

namespace gdc_license {
namespace {

const size_t kPayloadSize = 22;  // 4 (hash produs) + 8 (expirare) + 4 (nonce unic) + 6 (hash masina)

std::vector<uint8_t> base64_decode(const std::string& in) {
    static const std::string chars =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    std::vector<uint8_t> out;
    std::vector<int> table(256, -1);
    for (size_t i = 0; i < chars.size(); ++i) table[(unsigned char)chars[i]] = (int)i;

    int val = 0, bits = -8;
    for (unsigned char c : in) {
        if (c == '=' || table[c] == -1) continue;
        val = (val << 6) + table[c];
        bits += 6;
        if (bits >= 0) {
            out.push_back((uint8_t)((val >> bits) & 0xFF));
            bits -= 8;
        }
    }
    return out;
}

std::string base32_encode(const std::vector<uint8_t>& data) {
    static const std::string alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
    std::string out;
    int val = 0, bits = 0;
    for (uint8_t b : data) {
        val = (val << 8) | b;
        bits += 8;
        while (bits >= 5) {
            out += alphabet[(val >> (bits - 5)) & 0x1F];
            bits -= 5;
        }
    }
    if (bits > 0) {
        out += alphabet[(val << (5 - bits)) & 0x1F];
    }
    return out;
}

std::vector<uint8_t> base32_decode(const std::string& in) {
    static const std::string alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
    std::vector<int> table(256, -1);
    for (size_t i = 0; i < alphabet.size(); ++i) table[(unsigned char)alphabet[i]] = (int)i;

    std::string cleaned;
    for (char c : in) {
        if (c == '-' || c == ' ') continue;
        cleaned += (char)std::toupper((unsigned char)c);
    }

    std::vector<uint8_t> out;
    int val = 0, bits = 0;
    for (char c : cleaned) {
        if (c == '=') continue;
        int idx = table[(unsigned char)c];
        if (idx == -1) continue;
        val = (val << 5) + idx;
        bits += 5;
        if (bits >= 8) {
            out.push_back((uint8_t)((val >> (bits - 8)) & 0xFF));
            bits -= 8;
        }
    }
    return out;
}

uint64_t read_u64_be(const uint8_t* p) {
    uint64_t v = 0;
    for (int i = 0; i < 8; ++i) v = (v << 8) | p[i];
    return v;
}

void sha512_bytes(const std::string& input, unsigned char out[64]) {
    sha512_context ctx;
    sha512_init(&ctx);
    sha512_update(&ctx, (const unsigned char*)input.data(), input.size());
    sha512_final(&ctx, out);
}

std::string raw_machine_id() {
#if defined(_WIN32)
    HKEY key;
    if (RegOpenKeyExA(HKEY_LOCAL_MACHINE, "SOFTWARE\\Microsoft\\Cryptography", 0,
                       KEY_READ | KEY_WOW64_64KEY, &key) == ERROR_SUCCESS)
    {
        char buf[64] = {0};
        DWORD size = sizeof(buf);
        DWORD type = 0;
        LONG res = RegQueryValueExA(key, "MachineGuid", nullptr, &type, (LPBYTE)buf, &size);
        RegCloseKey(key);
        if (res == ERROR_SUCCESS)
        {
            return std::string(buf);
        }
    }
    return "windows-machine-id-unavailable";

#elif defined(__APPLE__)
    io_registry_entry_t entry = IORegistryEntryFromPath(kIOMainPortDefault, "IOService:/");
    if (entry == 0) return "mac-machine-id-unavailable";

    CFStringRef uuidRef = (CFStringRef)IORegistryEntryCreateCFProperty(
        entry, CFSTR("IOPlatformUUID"), kCFAllocatorDefault, 0);
    IOObjectRelease(entry);

    if (!uuidRef) return "mac-machine-id-unavailable";

    char buf[128] = {0};
    CFStringGetCString(uuidRef, buf, sizeof(buf), kCFStringEncodingUTF8);
    CFRelease(uuidRef);
    return std::string(buf);

#else
    std::ifstream f("/etc/machine-id");
    if (f.is_open())
    {
        std::string id;
        std::getline(f, id);
        if (!id.empty()) return id;
    }
    return "linux-machine-id-unavailable";
#endif
}

std::vector<uint8_t> machine_id_hash() {
    unsigned char digest[64];
    sha512_bytes(raw_machine_id(), digest);
    return std::vector<uint8_t>(digest, digest + 6);
}

}  // namespace (anonim)

std::string get_machine_id_display() {
    return base32_encode(machine_id_hash());
}

CheckResult check_serial(const std::string& serial, const std::string& public_key_b64,
                          const std::string& product_id) {
    CheckResult result;

    std::vector<uint8_t> public_key = base64_decode(public_key_b64);
    if (public_key.size() != 32) {
        result.error = "Cheia publica configurata in plugin e invalida.";
        return result;
    }

    std::vector<uint8_t> packed = base32_decode(serial);
    if (packed.size() != kPayloadSize + 64) {
        result.error = "Format de cod serial invalid.";
        return result;
    }

    const uint8_t* payload = packed.data();
    const uint8_t* signature = packed.data() + kPayloadSize;

    int valid = ed25519_verify(signature, payload, kPayloadSize, public_key.data());
    if (!valid) {
        result.error = "Cod serial invalid — semnatura nu se potriveste.";
        return result;
    }

    unsigned char product_hash_full[64];
    sha512_bytes(product_id, product_hash_full);

    if (std::memcmp(payload, product_hash_full, 4) != 0) {
        result.error = "Acest cod e pentru alt produs.";
        return result;
    }

    uint64_t expires_at = read_u64_be(payload + 4);
    result.expires_at = expires_at;

    if (expires_at != 0) {
        uint64_t now = (uint64_t)time(nullptr);
        if (expires_at < now) {
            result.expired = true;
            result.error = "Codul serial a expirat.";
            return result;
        }
    }

    const uint8_t* stored_machine_hash = payload + 16;
    bool machine_locked = false;
    for (int i = 0; i < 6; ++i) {
        if (stored_machine_hash[i] != 0) { machine_locked = true; break; }
    }
    if (machine_locked) {
        std::vector<uint8_t> current = machine_id_hash();
        if (std::memcmp(stored_machine_hash, current.data(), 6) != 0) {
            result.wrong_machine = true;
            result.error = "Acest cod e activat pentru alt calculator.";
            return result;
        }
    }

    result.valid = true;
    return result;
}

std::string activation_file_path(const std::string& product_id) {
#if defined(_WIN32)
    const char* base = std::getenv("PROGRAMDATA");
    std::filesystem::path dir = std::filesystem::path(base ? base : "C:\\ProgramData") / "GDC";
#elif defined(__APPLE__)
    const char* home = std::getenv("HOME");
    std::filesystem::path dir = std::filesystem::path(home ? home : "") / "Library" / "Application Support" / "GDC";
#else
    const char* home = std::getenv("HOME");
    std::filesystem::path dir = std::filesystem::path(home ? home : "") / ".config" / "gdc";
#endif
    std::error_code ec;
    std::filesystem::create_directories(dir, ec);
    return (dir / (product_id + "_license.dat")).string();
}

bool save_activated_license(const std::string& product_id, const std::string& serial) {
    std::string path = activation_file_path(product_id);
    std::ofstream out(path, std::ios::binary | std::ios::trunc);
    if (!out.is_open()) {
        return false;
    }
    out << serial;
    return out.good();
}

CheckResult check_activated_license(const std::string& product_id, const std::string& public_key_b64) {
    CheckResult result;
    std::string path = activation_file_path(product_id);
    std::ifstream in(path, std::ios::binary);
    if (!in.is_open()) {
        result.error = "Nicio licenta activata local.";
        return result;
    }
    std::string serial((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    if (serial.empty()) {
        result.error = "Fisierul de licenta local e gol.";
        return result;
    }
    return check_serial(serial, public_key_b64, product_id);
}

}  // namespace gdc_license
