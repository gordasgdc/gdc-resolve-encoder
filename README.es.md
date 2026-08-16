# GDC Resolve Encoder

Codificador nativo y de código abierto para DaVinci Resolve Studio — H.264 y H.265 vía FFmpeg, con aceleración por hardware automática (Apple VideoToolbox en Mac, NVIDIA NVENC en Windows/Linux), además de variantes de 8 bits y 10 bits.

**Página de presentación**: https://gordasgdc.github.io/gdc-resolve-encoder/
**Română**: [README.md](README.md) · **English**: [README.en.md](README.en.md)

> Requiere **DaVinci Resolve Studio** — la edición gratuita no soporta IOPlugins.

## Guía completa, en 3 idiomas

Cada archivo en [Releases](https://github.com/gordasgdc/gdc-resolve-encoder/releases/latest) incluye una guía PDF completa (instalación, cada ajuste explicado con ejemplos, recetas prácticas, solución de problemas, licencias), en rumano, inglés y español. También disponibles directamente en [`docs/guides/`](docs/guides/).

## Qué registra el plugin

| Códec | Backend | Tipo | Profundidad | Plataformas |
|---|---|---|---|---|
| GDC H.264 | `libx264` | Software | 8 bits | Mac · Windows · Linux |
| GDC H.265 | `libx265` | Software | 8 bits | Mac · Windows · Linux |
| GDC H.264 | Apple VideoToolbox | Hardware | 8 bits | Mac (Apple Silicon) |
| GDC H.265 | Apple VideoToolbox | Hardware | 8 bits | Mac (Apple Silicon) |
| GDC H.264 | NVIDIA NVENC | Hardware | 8 bits | Windows · Linux (GPU NVIDIA) |
| GDC H.265 | NVIDIA NVENC | Hardware | 8 bits | Windows · Linux (GPU NVIDIA) |
| GDC H.264 10 bits | `libx264` (High10) | Software | 10 bits | Mac · Windows · Linux |
| GDC H.265 10 bits | `libx265` (Main10) | Software | 10 bits | Mac · Windows · Linux |

Las variantes por hardware solo aparecen en la lista de códecs de Resolve **si** tu máquina puede ejecutarlas realmente — FFmpeg se comprueba al iniciar el plugin, no se asume. El modo de 10 bits está disponible actualmente solo por software.

## Ajustes disponibles en el panel del plugin

- **Preset** — velocidad vs eficiencia de compresión (ultrafast → veryslow)
- **Rate Control** — Calidad Constante (CRF), Bitrate objetivo, o QP Constante
- **Profile** — baseline/main/high/high422 (solo H.264 8 bits software)
- **Tune** — film, animation, grain, stillimage, psnr, ssim, fastdecode, zerolatency (la lista difiere ligeramente entre H.264 y H.265, verificada directamente contra cada codificador)
- **Keyframe Interval** — distancia entre fotogramas clave, en segundos (2s por defecto — convertida automáticamente en fotogramas, según el framerate real del timeline). Más corto = archivo más grande pero mejor para scrub/QC fotograma a fotograma; más largo = archivo más pequeño, adecuado para entrega/visionado

Cada ajuste, con ejemplos concretos de cuándo y cómo usarlo, está explicado en detalle en la guía PDF.

## Instalación

Descarga el archivo para tu plataforma desde [Releases](https://github.com/gordasgdc/gdc-resolve-encoder/releases/latest).

> **Sobre FFmpeg**: el plugin no incluye FFmpeg (tamaño grande, complicaciones de licencia GPL/LGPL). En **Mac y Linux**, necesitas FFmpeg instalado por separado en el sistema. En **Windows**, las librerías necesarias ya vienen incluidas en el archivo — no hay que instalar nada extra.

### macOS (Apple Silicon)

**Requisito previo**: [Homebrew](https://brew.sh) — si aún no lo tienes, ejecuta:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Lo más sencillo: en la carpeta descomprimida, ejecuta:
```bash
./install.sh
```
El script comprueba Homebrew y FFmpeg (instala FFmpeg si falta), elimina el indicador de cuarentena de macOS, y copia el plugin a la ubicación correcta. Pide tu contraseña una sola vez.

Instalación manual, si lo prefieres:
```bash
xattr -rd com.apple.quarantine gdc_resolve_encoder.dvcp.bundle
mv gdc_resolve_encoder.dvcp.bundle "/Library/Application Support/Blackmagic Design/DaVinci Resolve/IOPlugins/"
```

### Windows

No necesitas FFmpeg por separado — los DLL necesarios ya vienen en el archivo.

Mueve la carpeta completa `gdc_resolve_encoder.dvcp.bundle` (la carpeta entera, no solo el archivo interior) a:
```
%ProgramData%\Blackmagic Design\DaVinci Resolve\Support\IOPlugins\
```

### Linux

Instala FFmpeg desde el gestor de paquetes de tu distribución, por ejemplo:
```bash
sudo apt install ffmpeg        # Debian/Ubuntu
sudo dnf install ffmpeg        # Fedora
sudo pacman -S ffmpeg          # Arch
```

Luego mueve el bundle a:
```
/opt/resolve/IOPlugins/
```

Reinicia Resolve después de instalar.

## Cómo se usa

1. Página **Deliver**, como en cualquier exportación normal
2. Elige el formato **MP4** o **QuickTime**
3. Los códecs **GDC** aparecen en la lista de códecs, junto a los nativos
4. Los ajustes aparecen directamente en el panel de exportación (Plugin Settings)

## Requisitos

- **DaVinci Resolve Studio** (la edición gratuita no soporta IOPlugins)
- **macOS Apple Silicon**, Windows de 64 bits, o Linux — los Mac Intel no son compatibles
- **FFmpeg instalado en el sistema** — Mac/Linux (Windows tiene los DLL incluidos en el archivo)
- Para NVENC: una GPU **NVIDIA** con driver actualizado

## Estructura correcta del bundle

```
gdc_resolve_encoder.dvcp.bundle/
└── Contents/
    ├── MacOS/              (solo Mac)
    │   └── gdc_resolve_encoder.dvcp
    ├── Win64/               (solo Windows)
    │   └── gdc_resolve_encoder.dvcp
    └── Linux-x86-64/        (solo Linux)
        └── gdc_resolve_encoder.dvcp
```

Cada archivo en [Releases](https://github.com/gordasgdc/gdc-resolve-encoder/releases/latest) contiene el bundle completo, ya estructurado correctamente, para esa plataforma — no requiere montaje manual.

## Compilar desde el código fuente

Consulta [`.github/workflows/build.yml`](.github/workflows/build.yml) para los pasos exactos usados en cada release; resumen:

```bash
# Linux
sudo apt-get install cmake pkg-config libavcodec-dev libavutil-dev libswscale-dev
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j

# macOS (solo arm64)
brew install cmake pkg-config ffmpeg
cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_ARCHITECTURES=arm64
cmake --build build -j

# Windows (necesita un build de desarrollo de FFmpeg, ej. gyan.dev)
cmake -B build -DCMAKE_BUILD_TYPE=Release -DFFMPEG_ROOT="C:\path\to\ffmpeg"
cmake --build build --config Release
```

## Limitaciones conocidas

- Sin soporte HDR (metadatos PQ/HLG) por ahora — previsto para una versión futura
- El modo de 10 bits solo está disponible por software (x264/x265), no por hardware
- Sin renderizado multi-pasada — solo una pasada actualmente
- El CRF en codificadores por hardware (VideoToolbox/NVENC) cae automáticamente a un bitrate fijo, no a una calidad constante real — el hardware no expone CRF igual que x264/x265

## Licencia

MIT para el código propio del plugin — ver [LICENSE](LICENSE). Construido sobre el DaVinci Resolve IO Encode Plugin SDK (Blackmagic Design), redistribuido conforme a los requisitos del SDK (`include/`, `wrapper/`). No afiliado con Blackmagic Design.

El plugin enlaza con librerías licenciadas bajo **GPL** (FFmpeg, libx264, libx265) — el binario compilado está, como distribución, sujeto a los términos GPL. Detalles completos, con implicaciones, en [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md).

## Autor

**Cristi Gordas (GDC)** — [GitHub](https://github.com/gordasgdc) · [Facebook](https://web.facebook.com/cristiGDC) · [YouTube](https://www.youtube.com/@cristigordas)
