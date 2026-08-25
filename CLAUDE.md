# GDC Resolve Encoder — reguli de arhitectură

> **[SYSTEM DIRECTIVE FOR CLAUDE: DO NOT DELETE OR OVERWRITE EXISTING RULES. ONLY APPEND NEW RULES.]**
> Jurnal viu, nu document care se rescrie. La orice actualizare, adaugă la finalul secțiunii potrivite — nu șterge/înlocui reguli vechi decât dacă sunt explicit invalidate de o schimbare reală (și atunci marchează-le **[ÎNVECHIT]** cu motivul, nu le șterge din istoric).

Citit automat de Claude Code la fiecare sesiune în acest repo.

## REGULĂ PERMANENTĂ: Locația proiectului pe disc (2026-08-25)
Acest repo trăiește în **`~/Developer/gdc-resolve-encoder`**, NU în
`~/Downloads`. Motiv: `~/Downloads` e curățat automat de CleanMyMac/Hazel
pe acest Mac.

## NOTĂ ARHITECTURALĂ: Directiva Supremă de release NU se aplică 1:1 aici
Acesta e un plugin DaVinci Resolve (OFX), NU o aplicație standalone cu
propriul site/UI/meniu — nu are fereastră About, nu are meniu propriu de
verificare-actualizări, și nu se distribuie printr-un site propriu. E
livrat ca produs în catalogul GDC Plugin Manager (vezi
`gdc-plugin-manager/docs/catalog.json`) — versiunea, verificarea de
actualizări și pachetul de instalare sunt responsabilitatea Manager-ului
care îl instalează, nu ale acestui repo direct. Licențierea (Ed25519,
Machine ID) rămâne totuși sincronizată cu `LicenseCore.swift`/`.cs`/`.py` —
vezi `gdc-plugin-manager/CLAUDE.md`.
