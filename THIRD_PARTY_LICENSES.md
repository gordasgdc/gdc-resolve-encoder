# Third-party components / Componente terțe

**GDC Resolve Encoder** — Copyright (c) 2026 Dumitru Cristinel Gordas (GDC).
The plugin's own source code (everything in `src/`, `wrapper/`, `tests/`, `scripts/`, the installers
and documentation) is released under the **MIT License** (`LICENSE`).

The **macOS package** (`.pkg` / bundle) additionally contains the libraries below, copied unchanged from
Homebrew into `Contents/Frameworks/`. Because the bundled FFmpeg is built with `--enable-gpl --enable-version3`
and links libx264 and libx265 (both GPL-2.0-or-later), **the macOS package as a whole is distributed under the
terms of the GNU General Public License version 3 (GPL-3.0-or-later)**. MIT code is compatible with that.
The Windows build uses its own FFmpeg build (see `.github/workflows/build.yml`) and its own notices.

| Library | Version in the package | Licence | Upstream |
|---|---|---|---|
| FFmpeg (libavformat, libavcodec, libavutil, libswscale, libswresample) | 9.0.2 | GPL-3.0-or-later (configured `--enable-gpl --enable-version3`) | https://ffmpeg.org/ |
| x264 | r3222 (b35605a) | GPL-2.0-or-later | https://www.videolan.org/developers/x264.html |
| x265 | 4.3 | GPL-2.0-or-later | https://bitbucket.org/multicoreware/x265_git |
| libvpx | 1.17.0 | BSD-3-Clause | https://www.webmproject.org/code/ |
| dav1d | 1.5.4 | BSD-2-Clause | https://code.videolan.org/videolan/dav1d |
| SVT-AV1 | 4.2.0 | BSD-3-Clause (+ AOM patent licence) | https://gitlab.com/AOMediaCodec/SVT-AV1 |
| Opus | 1.6.1 | BSD-3-Clause | https://opus-codec.org/ |
| LAME (libmp3lame) | 4.0 | LGPL-2.0-or-later | https://lame.sourceforge.io/ |
| mpg123 | 1.33.7 | LGPL-2.1-only | https://www.mpg123.de/ |
| liblzma (xz) | 5.8.4 | 0BSD | https://tukaani.org/xz/ |
| OpenSSL (libssl, libcrypto) | 3.6.4 | Apache-2.0 | https://openssl-library.org/ |

Full licence texts: `legal/texts/` in this repository and, in the installed bundle,
`Contents/Resources/Licenses/`. Exact upstream source archives and how to obtain them: `legal/SOURCES.md`.

Patents: H.264/AVC and H.265/HEVC (and other formats) may be covered by patents in some countries.
This software is provided without any patent licence; users are responsible for their own use.

This project is independent and is not affiliated with, endorsed by or sponsored by Blackmagic Design.
"DaVinci Resolve" is a trademark of Blackmagic Design Pty Ltd.
