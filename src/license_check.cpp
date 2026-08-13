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

namespace gdc_license {
namespace {

const size_t kPayloadSize = 16;  // 4 (hash produs) + 8 (expirare) + 4 (identificator aleator unic)

// ── Base64 decode (pentru cheia publica) ────────────────────────────
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

// ── Base32 decode (RFC 4648, pentru codul serial) ───────────────────
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

}  // namespace (anonim)

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
    sha512_context ctx;
    sha512_init(&ctx);
    sha512_update(&ctx, (const unsigned char*)product_id.data(), product_id.size());
    sha512_final(&ctx, product_hash_full);

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
    // octetii 12-15 din payload sunt identificatorul aleator unic - nu
    // necesita nicio validare suplimentara, exista doar ca sa faca
    // fiecare cod distinct (Ed25519 e o semnatura determinista).

    result.valid = true;
    return result;
}

// ── Persistenta locala + ascundere dupa activare ────────────────────

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
