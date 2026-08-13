// license_check.h — verificare cod serial in C++, folosind Ed25519
// (biblioteca vendorizata orlp/ed25519, verify-only).
//
// Formatul codului: Base32(4 octeti hash produs + 8 octeti timestamp
// expirare + 4 octeti identificator aleator unic + 6 octeti hash
// masina + 64 octeti semnatura Ed25519). Codurile sunt generate cu
// generate_serial_compact() din license_core.py (ramane la Cristi,
// niciodata distribuit).
//
// Hash-ul de masina (6 octeti, 0 = necorelat cu nicio masina anume)
// leaga optional un cod de un singur calculator — clientul vede
// ID-ul lui direct in panoul Resolve (get_machine_id_display()) si
// il trimite, tu il pui la generare cu --machine-id.

#pragma once
#include <string>
#include <cstdint>

namespace gdc_license {

struct CheckResult {
    bool valid = false;
    bool expired = false;
    bool wrong_machine = false;
    std::string error;
    uint64_t expires_at = 0;
};

// public_key_b64: cheia publica (Base64), generata o singura data de keygen.py
// product_id: identificatorul exact al produsului (acelasi folosit la generare)
CheckResult check_serial(const std::string& serial, const std::string& public_key_b64,
                          const std::string& product_id);

// ── ID de masina, pentru licente legate de un singur calculator ─────

// Un identificator hardware stabil, specific platformei (IOPlatformUUID
// pe Mac, MachineGuid din registry pe Windows, /etc/machine-id pe
// Linux), redus la 6 octeti printr-un hash si codat Base32 — un string
// scurt, lizibil, pe care clientul il poate citi si trimite direct din
// interfata Resolve, fara nicio comanda separata.
std::string get_machine_id_display();

// ── Persistenta locala, ca sa nu ceara codul de fiecare data si ca sa
// poata fi ascuns din interfata dupa prima activare reusita ──────────

// Calea fisierului local unde se salveaza licenta activata, specifica
// platformei (Application Support pe Mac, ProgramData pe Windows,
// ~/.config pe Linux).
std::string activation_file_path(const std::string& product_id);

// Salveaza un cod deja validat, ca sa nu mai fie nevoie sa fie introdus
// din nou. Apelata DOAR dupa ce check_serial() a confirmat ca e valid.
bool save_activated_license(const std::string& product_id, const std::string& serial);

// Verifica daca exista deja o licenta activata si valida, salvata
// anterior local. Daca da, intoarce CheckResult.valid=true — codul
// insusi NU mai trebuie afisat nicaieri in interfata dupa acest punct.
CheckResult check_activated_license(const std::string& product_id, const std::string& public_key_b64);

}  // namespace gdc_license
