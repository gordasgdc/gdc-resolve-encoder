# Changelog — GDC Resolve Encoder

Jurnal scurt, orientat spre utilizator, al schimbărilor livrate clienților
— o intrare per versiune, cu dată. Complementar jurnalului tehnic detaliat
din CLAUDE.md (acolo sunt și deciziile/motivele/pitfall-urile; aici doar
rezumatul a "ce s-a schimbat", ușor de scanat rapid).

## v1.5.0 (2026-09-05) — 2-Pass Encoding (bitrate mai precis, x264/x265)

**Opțiune nouă**: bifă „2-Pass Encoding" în modul Target Bitrate, pentru
variantele software (H.264/H.265, x264/x265) — encodează sursa de două ori
(prima trecere analizează, a doua produce fișierul final), pentru o
distribuție mai precisă a bitrate-ului față de o singură trecere. Timpul
de randare este aproximativ dublu cât rulează activată; dezactivată
(implicit), comportamentul rămâne exact ca înainte. Nu e disponibilă pe
encoderele hardware (VideoToolbox/NVENC) sau în modurile CRF/QP.

## v1.4.2 (2026-09-05) — Fix definitiv: plugin-ul nu mai depinde de FFmpeg-ul de pe mașina ta (Mac)

**Rezolvă definitiv fragilitatea semnalată în v1.4.1**: pluginul Mac
include acum FFmpeg direct în pachet (nu se mai leagă la ce ai instalat pe
sistem prin Homebrew) — indiferent ce versiune de FFmpeg ai sau dacă ai
Homebrew instalat deloc, pluginul funcționează identic. Nimic nou de
instalat sau de configurat — arhiva `install.sh` de pe GitHub nu mai cere
Homebrew, iar `.pkg`-ul semnat rămâne calea recomandată.

## v1.4.1 (2026-09-04) — Instalator .pkg semnat + notarizat (Mac)

**Instalare Mac, complet nouă**: în loc de `install.sh` (Terminal), acum
există un pachet `.pkg` semnat cu certificat Apple Developer ID și
**notarizat** — dublu-clic, acceptă licența, gata, fără niciun pas în
Terminal și fără avertismentul de Gatekeeper. Plugin-ul ajunge direct în
folderul corect din DaVinci Resolve.

**Fix real, important, găsit la testare**: versiunile publicate anterior
pe GitHub erau construite cu o versiune de FFmpeg diferită de cea
instalată de utilizatori prin Homebrew — plugin-ul nu se încărca deloc în
Resolve, fără nicio eroare vizibilă (exact simptomul "nu apare în listă"
raportat). Acesta a fost probabil un contributor real la instabilitatea
raportată inițial. Notă tehnică completă în CLAUDE.md — rămâne o
fragilitate structurală (leagă plugin-ul de versiunea exactă de FFmpeg de
pe mașina de compilare) de rezolvat definitiv într-o sesiune viitoare.

## v1.4.0 (2026-09-04) — Calitate, opțiuni noi și instalator Windows

**Calitate & compatibilitate**:
- Distanța dintre keyframe-uri (GOP) folosea o valoare fixă, mult prea
  deasă pentru o livrare profesionistă — acum se calculează din frame
  rate-ul real al sursei, cu un implicit de 2 secunde (configurabil,
  „Keyframe Interval" în panoul de setări).
- Fișierele exportate acum semnalează explicit spațiul de culoare
  (Rec.709 / Rec.2020) — înainte nu semnalau nimic, ceea ce putea duce
  la culori interpretate greșit în unele playere.
- Opțiunea de profil „High 4:2:2" a fost eliminată — nu era niciodată
  onorată real de niciun codec din acest plugin și putea cauza eșecuri
  la deschiderea encoder-ului pentru unii utilizatori.

**Opțiuni noi**:
- **Level** (H.264/H.265) — control explicit pentru compatibilitate cu
  playere/dispozitive hardware.
- **Parametri avansați** — câmp text liber pentru parametri x264/x265
  expert (aq-mode, psy-rd, ref, etc.), pentru cine vrea control fin,
  fără să aștepte un slider dedicat pentru fiecare opțiune.
- Threading explicit pe toate nucleele disponibile, pentru o scalare
  mai previzibilă pe mașini cu multe nuclee.

**Instalare**:
- **Windows — instalator nou** (`install.ps1`/`install.bat`, incluse în
  arhiva de descărcare): pune singur plugin-ul în folderul corect din
  DaVinci Resolve, fără nicio copiere manuală — cere automat drepturi de
  Administrator dacă e nevoie. Mac avea deja acest flux
  (`install.sh`), neschimbat.
