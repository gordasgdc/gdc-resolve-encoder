# Changelog — GDC Resolve Encoder

Jurnal scurt, orientat spre utilizator, al schimbărilor livrate clienților
— o intrare per versiune, cu dată. Complementar jurnalului tehnic detaliat
din CLAUDE.md (acolo sunt și deciziile/motivele/pitfall-urile; aici doar
rezumatul a "ce s-a schimbat", ușor de scanat rapid).

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
