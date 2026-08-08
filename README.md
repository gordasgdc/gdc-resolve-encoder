# GDC Resolve Encoder

Encoder gratuit, open-source, pentru DaVinci Resolve Studio — H.264 și H.265 prin FFmpeg, cu accelerare hardware automată (Apple VideoToolbox pe Mac, NVIDIA NVENC pe Windows/Linux).

**Pagina de prezentare**: https://gordasgdc.github.io/gdc-resolve-encoder/
**English**: [README.en.md](README.en.md) · **Español**: [README.es.md](README.es.md)

> Necesită **DaVinci Resolve Studio** — versiunea gratuită nu suportă IOPlugins.

## Ce înregistrează plugin-ul

| Codec | Backend | Tip | Platforme |
|---|---|---|---|
| GDC H.264 | `libx264` | Software | Mac · Windows · Linux |
| GDC H.265 | `libx265` | Software | Mac · Windows · Linux |
| GDC H.264 | Apple VideoToolbox | Hardware | Mac (Apple Silicon) |
| GDC H.265 | Apple VideoToolbox | Hardware | Mac (Apple Silicon) |
| GDC H.264 | NVIDIA NVENC | Hardware | Windows · Linux (cu placă NVIDIA) |
| GDC H.265 | NVIDIA NVENC | Hardware | Windows · Linux (cu placă NVIDIA) |

Variantele hardware apar în lista de codecuri din Resolve **doar** dacă mașina ta le poate rula efectiv — FFmpeg e verificat la pornirea plugin-ului, nu presupus.

## Instalare

Descarcă arhiva pentru platforma ta din [Releases](https://github.com/gordasgdc/gdc-resolve-encoder/releases/latest).

> **Despre FFmpeg**: plugin-ul nu include FFmpeg în pachet (dimensiune mare, complicații de licențiere GPL/LGPL). Pe **Mac și Linux**, ai nevoie de FFmpeg instalat separat în sistem. Pe **Windows**, bibliotecile necesare vin deja incluse în arhivă — nu trebuie să instalezi nimic în plus.

### macOS (Apple Silicon)

**Cerință prealabilă**: [Homebrew](https://brew.sh) — dacă nu-l ai deja instalat, rulează:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Instalează FFmpeg, dacă nu-l ai deja:
```bash
brew install ffmpeg
```

Apoi:
```bash
xattr -rd com.apple.quarantine gdc_resolve_encoder.dvcp.bundle
mv gdc_resolve_encoder.dvcp.bundle "/Library/Application Support/Blackmagic Design/DaVinci Resolve/IOPlugins/"
```

Sau folosește [`install.sh`](install.sh), care face toți pașii automat — verifică Homebrew și FFmpeg, instalează FFmpeg prin Homebrew dacă lipsește, elimină carantina și copiază plugin-ul la locul corect. Dacă nici Homebrew nu e instalat, scriptul îți arată exact link-ul de instalare de mai sus și se oprește, în loc să încerce ceva ce nu poate duce la bun sfârșit.

### Windows

Nu ai nevoie de FFmpeg separat — DLL-urile necesare vin deja în arhivă.

Mută folderul `gdc_resolve_encoder.dvcp.bundle` (întreg, nu doar fișierul din interior) în:
```
%ProgramData%\Blackmagic Design\DaVinci Resolve\Support\IOPlugins\
```

### Linux

Instalează FFmpeg din managerul de pachete al distribuției tale, de exemplu:
```bash
sudo apt install ffmpeg        # Debian/Ubuntu
sudo dnf install ffmpeg        # Fedora
sudo pacman -S ffmpeg          # Arch
```

Apoi mută bundle-ul în:
```
/opt/resolve/IOPlugins/
```

Repornește Resolve după instalare.

## Cum se folosește

1. Pagina **Deliver**, ca la orice export normal
2. Alege formatul **MP4** sau **QuickTime**
3. Codecurile **GDC** apar în lista de codecuri, alături de cele native
4. Setările de calitate (CRF sau bitrate țintă) apar direct în panoul de export

## Cerințe

- **DaVinci Resolve Studio** (versiunea gratuită nu suportă IOPlugins)
- **macOS Apple Silicon**, Windows 64-bit, sau Linux — Mac Intel nu e suportat
- **FFmpeg instalat în sistem** — pe Mac/Linux (Windows are DLL-urile incluse în arhivă)
- Pentru NVENC: placă video **NVIDIA** cu driver actualizat

## Structura corectă a bundle-ului

```
gdc_resolve_encoder.dvcp.bundle/
└── Contents/
    ├── MacOS/              (doar pe Mac)
    │   └── gdc_resolve_encoder.dvcp
    ├── Win64/               (doar pe Windows)
    │   └── gdc_resolve_encoder.dvcp
    └── Linux-x86-64/        (doar pe Linux)
        └── gdc_resolve_encoder.dvcp
```

Fiecare arhivă de pe [Releases](https://github.com/gordasgdc/gdc-resolve-encoder/releases/latest) conține bundle-ul complet, deja structurat corect, pentru platforma respectivă — nu trebuie construit manual.

## Construire din sursă

Vezi [`.github/workflows/build.yml`](.github/workflows/build.yml) pentru pașii exacți folosiți la fiecare release; rezumat:

```bash
# Linux
sudo apt-get install cmake pkg-config libavcodec-dev libavutil-dev libswscale-dev
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j

# macOS (doar arm64)
brew install cmake pkg-config ffmpeg
cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_ARCHITECTURES=arm64
cmake --build build -j

# Windows (necesita FFmpeg shared dev build, ex. gyan.dev)
cmake -B build -DCMAKE_BUILD_TYPE=Release -DFFMPEG_ROOT="C:\path\to\ffmpeg"
cmake --build build --config Release
```

## Limitări cunoscute

- CRF pe encoderele hardware (VideoToolbox/NVENC) cade automat pe un bitrate fix, nu o calitate constantă reală — hardware-ul nu expune CRF la fel ca x264/x265
- Cookie-ul magic (SPS/PPS) folosit la muxare e o concatenare simplă de NAL-uri, nu un box avcC/hvcC formal — a funcționat în teste, dar n-a fost validat pe orice caz limită de muxare

## Licență

MIT — vezi [LICENSE](LICENSE). Construit pe DaVinci Resolve IO Encode Plugin SDK (Blackmagic Design), redistribuit conform cerințelor SDK-ului (`include/`, `wrapper/`). Nu este afiliat cu Blackmagic Design.

## Autor

**Cristi Gordas (GDC)** — [GitHub](https://github.com/gordasgdc) · [Facebook](https://web.facebook.com/cristiGDC) · [YouTube](https://www.youtube.com/@cristigordas)
