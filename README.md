# GDC Resolve Encoder

Encoder nativ, open-source, pentru DaVinci Resolve Studio — H.264 și H.265 prin FFmpeg, cu accelerare hardware automată (Apple VideoToolbox pe Mac, NVIDIA NVENC pe Windows), plus variante 8-bit și 10-bit.

**Pagina de prezentare**: https://gordasgdc.github.io/gdc-resolve-encoder/
**English**: [README.en.md](README.en.md) · **Español**: [README.es.md](README.es.md)

> Necesită **DaVinci Resolve Studio** — versiunea gratuită nu suportă IOPlugins.

## Ghid complet, în 3 limbi

Fiecare arhivă din [Releases](https://github.com/gordasgdc/gdc-resolve-encoder/releases/latest) include și un ghid PDF complet (instalare, fiecare setare explicată cu exemple, rețete practice, depanare, licențe), în română, engleză și spaniolă. Le găsești și direct în [`docs/guides/`](docs/guides/).

## Ce înregistrează plugin-ul

| Codec | Backend | Tip | Adâncime | Platforme |
|---|---|---|---|---|
| GDC H.264 | `libx264` | Software | 8-bit | Mac · Windows |
| GDC H.265 | `libx265` | Software | 8-bit | Mac · Windows |
| GDC H.264 | Apple VideoToolbox | Hardware | 8-bit | Mac (Apple Silicon) |
| GDC H.265 | Apple VideoToolbox | Hardware | 8-bit | Mac (Apple Silicon) |
| GDC H.264 | NVIDIA NVENC | Hardware | 8-bit | Windows (cu placă NVIDIA) |
| GDC H.265 | NVIDIA NVENC | Hardware | 8-bit | Windows (cu placă NVIDIA) |
| GDC H.264 10-bit | `libx264` (High10) | Software | 10-bit | Mac · Windows |
| GDC H.265 10-bit | `libx265` (Main10) | Software | 10-bit | Mac · Windows |

Variantele hardware apar în lista de codecuri din Resolve **doar** dacă mașina ta le poate rula efectiv — FFmpeg e verificat la pornirea plugin-ului, nu presupus. 10-bit e disponibil momentan doar pe variantele software.

## Setări disponibile în panoul plugin-ului

- **Preset** — viteză vs eficiența compresiei (ultrafast → veryslow)
- **Rate Control** — Constant Quality (CRF), Target Bitrate, sau Constant QP
- **Profile** — baseline/main/high (doar H.264 8-bit software)
- **Level** — 3.0-5.2 sau Auto (H.264/H.265 software)
- **Keyframe Interval** — distanța dintre keyframe-uri, în secunde
- **Advanced Params** — parametri x264/x265 direcți (expert), ex. `aq-mode=3:psy-rd=1.0,0.15`
- **Tune** — film, animation, grain, stillimage, psnr, ssim, fastdecode, zerolatency (lista diferă ușor între H.264 și H.265, verificată direct față de fiecare encoder)

Fiecare setare, cu exemple concrete de când și cum s-o folosești, e explicată detaliat în ghidul PDF.

## Instalare

Descarcă arhiva pentru platforma ta din [Releases](https://github.com/gordasgdc/gdc-resolve-encoder/releases/latest).

> **Despre FFmpeg**: plugin-ul nu include FFmpeg în pachet (dimensiune mare, complicații de licențiere GPL/LGPL). Pe **Mac**, ai nevoie de FFmpeg instalat separat în sistem. Pe **Windows**, bibliotecile necesare vin deja incluse în arhivă — nu trebuie să instalezi nimic în plus.

### macOS (Apple Silicon)

**Cerință prealabilă**: [Homebrew](https://brew.sh) — dacă nu-l ai deja instalat, rulează:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Cel mai simplu: în folderul dezarhivat, rulează:
```bash
./install.sh
```
Scriptul verifică Homebrew și FFmpeg (îl instalează dacă lipsește), elimină carantina macOS, și copiază plugin-ul la locul corect. Cere parola o singură dată.

Manual, dacă preferi:
```bash
xattr -rd com.apple.quarantine gdc_resolve_encoder.dvcp.bundle
mv gdc_resolve_encoder.dvcp.bundle "/Library/Application Support/Blackmagic Design/DaVinci Resolve/IOPlugins/"
```

### Windows

Nu ai nevoie de FFmpeg separat — DLL-urile necesare vin deja în arhivă.

Cel mai simplu: în folderul dezarhivat, rulează `install.bat` (dublu-clic) — pune singur bundle-ul în folderul corect, cerând automat drepturi de Administrator dacă e nevoie.

Manual, dacă preferi: mută folderul `gdc_resolve_encoder.dvcp.bundle` (întreg, nu doar fișierul din interior) în:
```
%ProgramData%\Blackmagic Design\DaVinci Resolve\Support\IOPlugins\
```

## Cum se folosește

1. Pagina **Deliver**, ca la orice export normal
2. Alege formatul **MP4** sau **QuickTime**
3. Codecurile **GDC** apar în lista de codecuri, alături de cele native
4. Setările apar direct în panoul de export (Plugin Settings)

## Cerințe

- **DaVinci Resolve Studio** (versiunea gratuită nu suportă IOPlugins)
- **macOS Apple Silicon** sau Windows 64-bit — Mac Intel nu e suportat
- **FFmpeg instalat în sistem** — pe Mac (Windows are DLL-urile incluse în arhivă)
- Pentru NVENC: placă video **NVIDIA** cu driver actualizat

## Structura corectă a bundle-ului

```
gdc_resolve_encoder.dvcp.bundle/
└── Contents/
    ├── MacOS/              (doar pe Mac)
    │   └── gdc_resolve_encoder.dvcp
    └── Win64/               (doar pe Windows)
        └── gdc_resolve_encoder.dvcp
```

Fiecare arhivă de pe [Releases](https://github.com/gordasgdc/gdc-resolve-encoder/releases/latest) conține bundle-ul complet, deja structurat corect, pentru platforma respectivă — nu trebuie construit manual.

## Construire din sursă

Vezi [`.github/workflows/build.yml`](.github/workflows/build.yml) pentru pașii exacți folosiți la fiecare release; rezumat:

```bash
# macOS (doar arm64)
brew install cmake pkg-config ffmpeg
cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_ARCHITECTURES=arm64
cmake --build build -j

# Windows (necesita FFmpeg shared dev build, ex. gyan.dev)
cmake -B build -DCMAKE_BUILD_TYPE=Release -DFFMPEG_ROOT="C:\path\to\ffmpeg"
cmake --build build --config Release
```

## Limitări cunoscute

- Fără suport HDR (metadate PQ/HLG) momentan — planificat pentru o versiune viitoare
- 10-bit disponibil doar pe variantele software (x264/x265), nu și hardware
- Fără randare multi-pass — o singură trecere momentan
- CRF pe encoderele hardware (VideoToolbox/NVENC) cade automat pe un bitrate fix, nu o calitate constantă reală — hardware-ul nu expune CRF la fel ca x264/x265

## Licență

MIT pentru codul propriu — vezi [LICENSE](LICENSE). Construit pe DaVinci Resolve IO Encode Plugin SDK (Blackmagic Design), redistribuit conform cerințelor SDK-ului (`include/`, `wrapper/`). Nu este afiliat cu Blackmagic Design.

Plugin-ul leagă (links) librării licențiate **GPL** (FFmpeg, libx264, libx265) — binarul compilat este, ca distribuție, supus condițiilor GPL. Detalii complete, cu implicații, în [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md).

## Autor

**Cristi Gordas (GDC)** — [GitHub](https://github.com/gordasgdc) · [Facebook](https://web.facebook.com/cristiGDC) · [YouTube](https://www.youtube.com/@cristigordas)
