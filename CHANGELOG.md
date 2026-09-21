# Changelog — GDC Resolve Encoder

Jurnal scurt, orientat spre utilizator, al schimbărilor livrate clienților
— o intrare per versiune, cu dată. Complementar jurnalului tehnic detaliat
din CLAUDE.md (acolo sunt și deciziile/motivele/pitfall-urile; aici doar
rezumatul a "ce s-a schimbat", ușor de scanat rapid).

## v1.5.0 (2026-09-21) — Metadata HDR10 (MaxCLL / MaxFALL) pentru exporturi PQ

- **Grup nou „HDR10 Metadata”** în panoul plugin-ului (variantele software H.264 și H.265): comutator `Off` / `On (PQ exports only)`, primarele de mastering (P3-D65 sau Rec.2020), luminanța maximă a display-ului de mastering (100–10000 nits), MaxCLL și MaxFALL.
- Valorile se scriu în fluxul video, unde le citesc playerele și platformele HDR. Implicit este `Off`, deci exporturile existente nu se schimbă.
- Se aplică doar pe exporturi PQ (Rec.2100 ST2084).

## v1.4.4 (2026-09-21) — Export 10-bit funcțional + etichete corecte pentru HDR și P3

- **Variantele 10-bit (H.264 High10, H.265 Main10) apar acum în lista de codecuri** din Resolve. Înainte erau înregistrate, dar Resolve le refuza.
- **Imagine corectă la 10-bit**: exporturile 10-bit ieșeau grav supraexpuse și de câteva ori mai mari decât ar fi trebuit. Acum nivelurile sunt corecte și dimensiunea fișierului e normală.
- **Etichete de culoare pentru HDR și P3**: PQ, HLG, P3-D65 și P3-DCI sunt semnalate corect și în fluxul video, nu doar în container. Înainte, un export P3 purta etichete contradictorii.

## v1.4.3 (2026-09-21) — Culori corecte în fișierele exportate + robustețe

- **Etichete de culoare corecte**: fișierul exportat poartă acum spațiul de culoare real cerut de proiect (Rec.709, Rec.2020, P3-D65; transfer PQ sau HLG). Înainte, orice export 10-bit era etichetat automat Rec.2020, indiferent de proiect. Dacă informația lipsește, se folosește Rec.709.
- **Mai stabil la export**: dimensiunile de cadru impare sunt refuzate cu un mesaj clar în loc să producă imagine coruptă, iar cadrele sunt pregătite corect înainte de codare.
- **Mai puțină memorie folosită** la trimiterea fiecărui pachet video către Resolve.
- **Verificare automată la publicare**: pachetul Mac/Windows este testat că se încarcă corect înainte de a ajunge la utilizatori.

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
