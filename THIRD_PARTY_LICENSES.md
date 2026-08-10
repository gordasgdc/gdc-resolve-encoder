# Licențe terțe (Third-Party Licenses)

**Notă**: Acest document oferă informații factuale despre librăriile folosite și
licențele lor. Nu constituie consultanță juridică. Pentru certitudine legală
deplină (în special pentru distribuție comercială), consultă un avocat
specializat în proprietate intelectuală / licențe open-source.

This document provides factual information about the libraries used and their
licenses. It is not legal advice. For full legal certainty (especially for
commercial distribution), consult a lawyer specialized in open-source
licensing.

---

## Rezumat / Summary

`gdc_resolve_encoder` (codul propriu-zis al acestui plugin) este licențiat
sub **MIT License** — vezi `LICENSE` din acest repository.

Însă, **binarul compilat leagă (links) librării GPL** (`libx264`, `libx265`).
Conform termenilor GPL (General Public License), orice binar compilat care
leagă cod GPL devine, ca *distribuție compilată*, supus condițiilor GPL —
indiferent de licența codului propriu adăugat pe deasupra. Codul sursă al
acestui plugin rămâne MIT; **binarul livrat este, practic, o lucrare derivată
GPL** din cauza legăturii cu libx264/libx265.

**Ce înseamnă asta practic:**
- Poți folosi acest plugin liber, personal sau comercial (rendering intern).
- Dacă redistribui binarul (îl dai altcuiva, îl vinzi, îl incluzi într-un alt
  produs), ești obligat să respecți termenii GPL v2+ pentru acea distribuție
  — cel mai relevant, să pui la dispoziție codul sursă complet (al tău +
  libx264/libx265, care sunt deja publice) și să păstrezi aceeași licență
  GPL pentru distribuția respectivă.
- Nu poți vinde acest plugin ca produs "closed source" fără să respecți GPL.

---

## Librăriile folosite

### FFmpeg (libavcodec, libavutil, libswscale)
- **Website**: https://ffmpeg.org
- **Licență**: LGPL v2.1+ sau GPL v2+, în funcție de configurația de build.
  Build-urile folosite de acest proiect (care includ libx264/libx265) sunt
  configurate cu `--enable-gpl`, deci intră sub **GPL v2+**.
- **Copyright**: © FFmpeg contributors
- **Sursă**: https://github.com/FFmpeg/FFmpeg
- **Text licență**: https://ffmpeg.org/legal.html

### libx264
- **Website**: https://www.videolan.org/developers/x264.html
- **Licență**: **GPL v2+**. Există și o licență comercială disponibilă de la
  autori, pentru cine dorește să evite obligațiile GPL în distribuție.
- **Copyright**: © x264 project contributors
- **Sursă**: https://code.videolan.org/videolan/x264

### libx265
- **Website**: https://www.videolan.org/developers/x265.html
- **Licență**: **GPL v2**. Licență comercială disponibilă de la MulticoreWare
  Inc. pentru cine dorește să evite obligațiile GPL.
- **Copyright**: © MulticoreWare Inc. și contribuitori
- **Sursă**: https://bitbucket.org/multicoreware/x265_git

### Blackmagic Design IOPlugin SDK
- **Licență**: proprietară Blackmagic Design, inclusă cu DaVinci Resolve
  Developer SDK. Fișierele SDK neschimbate din acest repository
  (`include/`, structura de bază din `wrapper/`) rămân proprietatea
  Blackmagic Design și sunt incluse conform termenilor lor de distribuție
  pentru dezvoltatori de plugin-uri.

---

## Recomandare

Dacă la un moment dat vrei să distribui acest plugin comercial, la scară
mare, sau ca parte dintr-un produs plătit închis (closed-source), varianta
cea mai sigură din punct de vedere legal e să obții licențe comerciale
pentru libx264 și libx265 (de la x264/x265 respectiv MulticoreWare), care
te scutesc de obligațiile de redistribuire GPL. Pentru uz personal, freeware,
sau proiecte deschise, GPL nu ridică probleme — doar trebuie respectat.
