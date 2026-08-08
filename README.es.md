# GDC Resolve Encoder

Un códec IOPlugin gratuito y de código abierto para DaVinci Resolve Studio — H.264 y H.265 mediante FFmpeg, con aceleración por hardware automática (Apple VideoToolbox en Mac, NVIDIA NVENC en Windows/Linux).

**Sitio web**: https://gordasgdc.github.io/gdc-resolve-encoder/
**Română**: [README.md](README.md) · **English**: [README.en.md](README.en.md)

> Requiere **DaVinci Resolve Studio** — la edición gratuita no soporta IOPlugins.

## Qué registra el plugin

| Códec | Backend | Tipo | Plataformas |
|---|---|---|---|
| GDC H.264 | `libx264` | Software | Mac · Windows · Linux |
| GDC H.265 | `libx265` | Software | Mac · Windows · Linux |
| GDC H.264 | Apple VideoToolbox | Hardware | Mac (Apple Silicon) |
| GDC H.265 | Apple VideoToolbox | Hardware | Mac (Apple Silicon) |
| GDC H.264 | NVIDIA NVENC | Hardware | Windows · Linux (con GPU NVIDIA) |
| GDC H.265 | NVIDIA NVENC | Hardware | Windows · Linux (con GPU NVIDIA) |

Las variantes de hardware solo aparecen en la lista de códecs de Resolve si tu máquina realmente puede ejecutarlas — FFmpeg se comprueba al iniciar el plugin, nunca se asume.

## Instalación

Descarga el archivo para tu plataforma desde [Releases](https://github.com/gordasgdc/gdc-resolve-encoder/releases/latest).

> **Sobre FFmpeg**: el plugin no incluye FFmpeg en el paquete (tamaño grande, complicaciones de licencia GPL/LGPL). En **Mac y Linux**, necesitas FFmpeg instalado por separado en tu sistema. En **Windows**, las bibliotecas necesarias ya vienen incluidas en el archivo — no hay que instalar nada extra.

### macOS (Apple Silicon)

**Requisito previo**: [Homebrew](https://brew.sh) — si aún no lo tienes, ejecuta:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Instala FFmpeg, si aún no lo tienes:
```bash
brew install ffmpeg
```

Luego:
```bash
xattr -rd com.apple.quarantine gdc_resolve_encoder.dvcp.bundle
mv gdc_resolve_encoder.dvcp.bundle "/Library/Application Support/Blackmagic Design/DaVinci Resolve/IOPlugins/"
```

O usa [`install.sh`](install.sh), que hace todo esto automáticamente — comprueba Homebrew y FFmpeg, instala FFmpeg mediante Homebrew si falta, elimina la cuarentena y copia el plugin al lugar correcto. Si Homebrew tampoco está instalado, el script te muestra el enlace de instalación de arriba y se detiene, en lugar de intentar algo que no puede completarse.

### Windows

No hace falta instalar FFmpeg por separado — los DLL necesarios ya vienen en el archivo.

Mueve la carpeta completa `gdc_resolve_encoder.dvcp.bundle` (no solo el archivo interior) a:
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

## Uso

1. La página **Deliver**, como en cualquier exportación normal
2. Elige el formato **MP4** o **QuickTime**
3. Los códecs **GDC** aparecen en la lista de códecs, junto a los nativos
4. Los ajustes de calidad (CRF o bitrate objetivo) aparecen directamente en el panel de exportación

## Requisitos

- **DaVinci Resolve Studio** (la edición gratuita no soporta IOPlugins)
- **macOS Apple Silicon**, Windows de 64 bits, o Linux — los Mac Intel no son compatibles
- **FFmpeg instalado en tu sistema** — en Mac/Linux (Windows incluye los DLL en el archivo)
- Para NVENC: una **GPU NVIDIA** con driver actualizado

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

Cada archivo en [Releases](https://github.com/gordasgdc/gdc-resolve-encoder/releases/latest) ya contiene el bundle completamente estructurado para esa plataforma — no hay que armarlo a mano.

## Compilar desde el código fuente

Consulta [`.github/workflows/build.yml`](.github/workflows/build.yml) para ver los pasos exactos usados en cada release; resumen:

```bash
# Linux
sudo apt-get install cmake pkg-config libavcodec-dev libavutil-dev libswscale-dev
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j

# macOS (solo arm64)
brew install cmake pkg-config ffmpeg
cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_ARCHITECTURES=arm64
cmake --build build -j

# Windows (necesita un build de FFmpeg compartido, p. ej. gyan.dev)
cmake -B build -DCMAKE_BUILD_TYPE=Release -DFFMPEG_ROOT="C:\path\to\ffmpeg"
cmake --build build --config Release
```

## Limitaciones conocidas

- El CRF en los codificadores de hardware (VideoToolbox/NVENC) recurre a un bitrate fijo en lugar de una calidad constante real — el hardware no expone CRF igual que x264/x265
- La cookie mágica (SPS/PPS) usada para el muxado es una simple concatenación de NALs, no un box avcC/hvcC formal — ha funcionado en las pruebas, pero no se ha validado contra todos los casos límite de muxado

## Licencia

MIT — ver [LICENSE](LICENSE). Construido sobre el DaVinci Resolve IO Encode Plugin SDK de Blackmagic Design, redistribuido según lo requiere el SDK (`include/`, `wrapper/`). No afiliado con Blackmagic Design.

## Autor

**Cristi Gordas (GDC)** — [GitHub](https://github.com/gordasgdc) · [Facebook](https://web.facebook.com/cristiGDC) · [YouTube](https://www.youtube.com/@cristigordas)
