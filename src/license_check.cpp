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
    #include <Wbemidl.h>
    #include <comdef.h>
    // Linkeaza wbemuuid/ole32/oleaut32 — vezi CMakeLists.txt (bloc WIN32).
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

// Interogheaza WMI o singura data pentru o proprietate a unei clase date
// (ex. "Win32_ComputerSystemProduct"/"UUID" sau "Win32_DiskDrive"/"SerialNumber").
// Returneaza string gol daca WMI nu e disponibil (VM restrictionata, rulare
// fara privilegii, COM deja initializat cu alt threading model etc.) —
// apelantul decide fallback-ul, nu aceasta functie.
#if defined(_WIN32)
std::string wmi_query_first(const wchar_t* wql, const wchar_t* property) {
    std::string result;
    HRESULT hr = CoInitializeEx(0, COINIT_MULTITHREADED);
    bool needUninit = SUCCEEDED(hr);

    IWbemLocator* locator = nullptr;
    if (SUCCEEDED(CoCreateInstance(CLSID_WbemLocator, 0, CLSCTX_INPROC_SERVER,
                                    IID_IWbemLocator, (LPVOID*)&locator))) {
        IWbemServices* services = nullptr;
        if (SUCCEEDED(locator->ConnectServer(_bstr_t(L"ROOT\\CIMV2"), nullptr, nullptr,
                                              0, 0, 0, 0, &services))) {
            CoSetProxyBlanket(services, RPC_C_AUTHN_WINNT, RPC_C_AUTHZ_NONE, nullptr,
                              RPC_C_AUTHN_LEVEL_CALL, RPC_C_IMP_LEVEL_IMPERSONATE, nullptr, EOAC_NONE);

            IEnumWbemClassObject* enumerator = nullptr;
            if (SUCCEEDED(services->ExecQuery(_bstr_t(L"WQL"), _bstr_t(wql),
                                               WBEM_FLAG_FORWARD_ONLY | WBEM_FLAG_RETURN_IMMEDIATELY,
                                               nullptr, &enumerator))) {
                IWbemClassObject* obj = nullptr;
                ULONG returned = 0;
                if (enumerator->Next(WBEM_INFINITE, 1, &obj, &returned) == S_OK && returned > 0) {
                    VARIANT vt;
                    VariantInit(&vt);
                    if (SUCCEEDED(obj->Get(property, 0, &vt, 0, 0)) && vt.vt == VT_BSTR) {
                        result = std::string(_bstr_t(vt.bstrVal));
                    }
                    VariantClear(&vt);
                    obj->Release();
                }
                enumerator->Release();
            }
            services->Release();
        }
        locator->Release();
    }
    if (needUninit) CoUninitialize();
    return result;
}

std::string trim(std::string s) {
    size_t a = s.find_first_not_of(" \t\r\n");
    size_t b = s.find_last_not_of(" \t\r\n");
    return (a == std::string::npos) ? std::string() : s.substr(a, b - a + 1);
}
#endif

// Intoarce true si populeaza `out` cu ID-ul de masina real DOAR cand
// hardware-ul a putut fi citit efectiv. Cand nu (WMI/IOKit indisponibil
// temporar), intoarce false si `out` primeste placeholder-ul stabil de
// mai jos — separarea asta e ce permite check_serial() sa distinga "asta
// chiar e alta masina" de "n-am putut intreba masina asta acum" (vezi
// politica de kill-switch din license_check.h).
bool raw_machine_id(std::string& out) {
#if defined(_WIN32)
    // ────────────────────────────────────────────────────────────────
    // GDC-SEC-02 (audit securitate 2026-08-24): MachineGuid din Registry
    // (HKLM\SOFTWARE\Microsoft\Cryptography) se rescrie cu un simplu
    // "reg add" din orice cont admin — o licenta legata de masina A se
    // "muta" pe masina B fara efort. NU mai folosim MachineGuid.
    //
    // FORMULA STRICTA pe Windows (obligatorie identic in Python, C#, C++
    // — orice implementare noua TREBUIE sa o respecte byte-cu-byte,
    // altfel machine_id-ul afisat difera intre componente pentru aceeasi
    // masina si toate licentele Windows deja emise devin invalide):
    //
    //   raw = trim(Win32_ComputerSystemProduct.UUID) + "|" + trim(Win32_DiskDrive[0].SerialNumber)
    //   hash = SHA-512(raw), primii 6 octeti, Base32 (fara padding)
    //
    // Board UUID (BIOS/placa de baza, via WMI) + serialul discului fizic:
    // schimbarea unuia singur nu mai schimba ID-ul rezultat. Vezi
    // MACHINE_ID_ARCHITECTURE.md pentru detalii si istoricul deciziei.
    // ────────────────────────────────────────────────────────────────
    std::string board_uuid = trim(wmi_query_first(L"SELECT UUID FROM Win32_ComputerSystemProduct", L"UUID"));
    std::string disk_serial = trim(wmi_query_first(L"SELECT SerialNumber FROM Win32_DiskDrive", L"SerialNumber"));
    if (!board_uuid.empty()) {
        out = board_uuid + "|" + disk_serial;
        return true;
    }
    out = "windows-machine-id-unavailable";
    return false;

#elif defined(__APPLE__)
    io_registry_entry_t entry = IORegistryEntryFromPath(kIOMainPortDefault, "IOService:/");
    if (entry == 0) { out = "mac-machine-id-unavailable"; return false; }

    CFStringRef uuidRef = (CFStringRef)IORegistryEntryCreateCFProperty(
        entry, CFSTR("IOPlatformUUID"), kCFAllocatorDefault, 0);
    IOObjectRelease(entry);

    if (!uuidRef) { out = "mac-machine-id-unavailable"; return false; }

    char buf[128] = {0};
    CFStringGetCString(uuidRef, buf, sizeof(buf), kCFStringEncodingUTF8);
    CFRelease(uuidRef);
    out = std::string(buf);
    return true;

#else
    std::ifstream f("/etc/machine-id");
    if (f.is_open())
    {
        std::string id;
        std::getline(f, id);
        if (!id.empty()) { out = id; return true; }
    }
    out = "linux-machine-id-unavailable";
    return false;
#endif
}

std::vector<uint8_t> machine_id_hash() {
    std::string raw;
    raw_machine_id(raw);  // valoare, disponibila sau placeholder — hash-ul de AFISARE ramane neschimbat
    unsigned char digest[64];
    sha512_bytes(raw, digest);
    return std::vector<uint8_t>(digest, digest + 6);
}

// Folosit doar de check_serial() — daca hardware-ul chiar n-a putut fi
// citit acum, un hash calculat din placeholder NU trebuie comparat ca
// "alta masina" (ar fi un fals-pozitiv). Vezi hwid_unavailable in header.
bool machine_id_available() {
    std::string ignored;
    return raw_machine_id(ignored);
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
        result.bad_signature = true;  // format corupt/scurtat -> aceeasi categorie "tamper" ca semnatura invalida
        result.error = "Format de cod serial invalid.";
        return result;
    }

    const uint8_t* payload = packed.data();
    const uint8_t* signature = packed.data() + kPayloadSize;

    int valid = ed25519_verify(signature, payload, kPayloadSize, public_key.data());
    if (!valid) {
        result.bad_signature = true;  // tamper evident -> kill-switch: blocare dura
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
        if (!machine_id_available()) {
            // Nu stim daca e chiar alta masina sau doar WMI/IOKit temporar
            // indisponibil — apelantul decide (grace period), NU tratam ca
            // wrong_machine (ar fi un fals-pozitiv pentru un client cinstit).
            result.hwid_unavailable = true;
            result.error = "Nu am putut citi identificatorul hardware acum.";
            return result;
        }
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

// Cate secunde tinem o licenta anterior-valida "activa" cand nu putem citi
// hardware-ul acum (WMI pe Windows restrictionat, VM, etc.) — suficient
// cat un client cinstit sa nu piarda accesul din cauza unei erori
// temporare, dar nu nelimitat.
constexpr long long GRACE_PERIOD_SECONDS = 5LL * 24 * 60 * 60;  // 5 zile

std::string grace_file_path(const std::string& product_id) {
    return activation_file_path(product_id) + ".grace";
}

// unix timestamp al ultimei validari reusite (nu neaparat prin grace),
// citit/scris ca text simplu — nu are nevoie de un parser JSON aici.
long long read_last_good_ts(const std::string& product_id) {
    std::ifstream in(grace_file_path(product_id));
    if (!in.is_open()) return 0;
    long long ts = 0;
    in >> ts;
    return ts;
}

void write_last_good_ts(const std::string& product_id, long long ts) {
    std::ofstream out(grace_file_path(product_id), std::ios::trunc);
    if (out.is_open()) out << ts;
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
    in.close();
    if (serial.empty()) {
        result.error = "Fisierul de licenta local e gol.";
        return result;
    }

    CheckResult result_check = check_serial(serial, public_key_b64, product_id);

    // ── Kill-switch diferentiat (decizie 2026-08-24, vezi license_check.h) ──
    if (result_check.valid) {
        write_last_good_ts(product_id, (long long)time(nullptr));
        return result_check;
    }
    if (result_check.bad_signature) {
        // Tamper evident: sterge licenta locala falsificata/corupta —
        // clientul trebuie sa reactiveze cu un cod valid.
        std::error_code ec;
        std::filesystem::remove(path, ec);
        std::filesystem::remove(grace_file_path(product_id), ec);
        return result_check;
    }
    if (result_check.hwid_unavailable) {
        long long last_good = read_last_good_ts(product_id);
        long long now = (long long)time(nullptr);
        if (last_good != 0 && (now - last_good) < GRACE_PERIOD_SECONDS) {
            CheckResult grace = result_check;
            grace.valid = true;
            grace.grace_active = true;
            grace.hwid_unavailable = false;
            grace.error.clear();
            return grace;
        }
        // Grace expirat — mod demo, dar NU stergem licenta (poate reveni WMI/IOKit).
        return result_check;
    }
    // wrong_machine / wrong_product / expired: mod demo, licenta ramane pe disc.
    return result_check;
}

}  // namespace gdc_license
