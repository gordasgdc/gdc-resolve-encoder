#!/usr/bin/env python3
"""Generates the three product pages (RO at the root, EN in en/, ES in es/).

Usage: scripts/build_site.py <output-dir> [--version 1.8.0]
<output-dir> is the folder served at https://gordas.dev/gdc-resolve-encoder/
(assets/ and guides/ are expected next to the pages and are not touched).
Composition follows the FotoAsist GC page (intro, pinned hero, tab band,
editorial blocks, access band, minimal footer); the Deliver-flow adaptation
(dark hero stage, numbered pipeline, measured-quality grid) is new.
"""
import argparse
import html
import os
import sys

VERSION = "1.8.0"
SHA = "ed00b95498f3f9e3e11136baf79178f55cfb08f1d1ae44af5d099c8f7d6c0351"
SIZE_MB = {"ro": "15,3 MB", "en": "15.3 MB", "es": "15,3 MB"}
BASE = "https://gordas.dev/gdc-resolve-encoder/"
REPO = "https://github.com/gordasgdc/gdc-resolve-encoder"
WIN_VERSION = "1.7.0"
WIN_FILE = "gdc-resolve-encoder-windows-x64.zip"
WIN_URL = f"{REPO}/releases/download/v{WIN_VERSION}/{WIN_FILE}"
WIN_SHA = "785d1dc93e3c8085c7ae29b0b6a405ffc4e1384cf6735e09163ed187ed44d5f2"
WIN_BYTES = 50165975

T = {
"ro": dict(
    lang="ro", dir="", home="./", prefix="",
    title="GDC Resolve Encoder — Exportă din Deliver, cu codecuri H.264 și H.265 proprii.",
    desc="GDC Resolve Encoder: plugin macOS gratuit și cu sursă deschisă pentru DaVinci Resolve Studio. H.264 și H.265, 8-bit și 10-bit, 4:2:2, HDR10, containere QuickTime, MP4 și Matroska direct din Deliver.",
    nav=[("#flux", "Fluxul Deliver"), ("#calitate", "Calitate"), ("#acces", "Descărcare")], cta="Descarcă ↗",
    eyebrow="GDC RESOLVE ENCODER / PENTRU MAC",
    h1="Randezi în Deliver.<br>Alegi tu codecul.",
    lead="Un plugin pentru DaVinci Resolve Studio care adaugă în lista Format și Codec encodere H.264 și H.265 complete: 10-bit, 4:2:2, HDR10 și containere proprii.",
    pill="Vezi fluxul Deliver", textlink="Cifrele verificate ↘",
    pins=[("FORMAT", "Alegi containerul."), ("TYPE", "Alegi encoderul."), ("SETĂRI", "Reglezi calitatea.")],
    feat=[("Trei containere noi în lista Format.", "GDC QuickTime, GDC MP4 și GDC Matroska apar în Deliver după formatele native. Culoarea și metadatele HDR10 se scriu în fișier."),
          ("Encoderul pe care îl alegi.", "H.264 și H.265, software (x264, x265) sau hardware (Apple VideoToolbox), pe 8-bit, 10-bit și 4:2:2 10-bit."),
          ("Calitatea, sub control.", "Calitate constantă (CRF), bitrate țintă sau QP constant, preset, tune, nivel și parametri avansați x264/x265.")],
    fcap="Captură reală a panoului Deliver, DaVinci Resolve Studio 21.2.",
    prod_label="UN SINGUR PANOU, DIN DELIVER", prod_h="Fără aplicație separată.<br>Fără pas în plus.",
    prod_p="Pluginul trăiește în Deliver. Alegi formatul, codecul și setările, apoi randezi ca de obicei.",
    steps=[("01 Format", "Alege containerul.", "GDC QuickTime, GDC MP4 sau GDC Matroska. Toate scriu culoarea, sunetul PCM și, la export PQ, metadatele HDR10."),
           ("02 Type", "Alege encoderul.", "La Codec alegi GDC Encoder, apoi la Type una din cele 8 variante: H.264 sau H.265, 8-bit, 10-bit sau 4:2:2 10-bit, software sau Apple VideoToolbox. Variantele hardware apar doar dacă Mac-ul tău le poate rula."),
           ("03 Setări", "Reglează calitatea.", "Calitate constantă, bitrate țintă sau QP, preset, tune, nivel și parametri avansați. Jurnalul arată modul real folosit."),
           ("04 Randare", "Randează ca de obicei.", "Coada, intervalul și sunetul rămân ale Resolve. Anularea unui export lasă un fișier valid, trunchiat la ultimul cadru scris.")],
    q_label="MĂSURAT, NU PRESUPUS", q_h="Verificat pe material<br>de cameră de cinema.",
    q_p="Fiecare export a fost comparat cadru cu cadru și eșantion cu eșantion cu sursa, pe 17 exporturi: clipuri întregi și o secvență cu mai multe clipuri, cu sunet.",
    stats=[("≥ 40,6 dB", "PSNR minim, imagine față de sursă"), ("0", "eșantioane de întârziere audio–video"), ("100%", "cadrele numărate corect, la început și la sfârșit"), ("HDR10", "mastering display HDR10 scris în fișier, pe exporturi PQ")],
    q_note="Pe 10-bit 4:2:0, Resolve 21.2 livrează imaginea într-o dispunere neplanară pe care pluginul o preia acum corect. Varianta 1.7.0 producea o imagine alterată (PSNR 14 dB) la 10-bit 4:2:0.",
    ed_label="CE ÎNSEAMNĂ ÎN PRACTICĂ", ed_h="Calitate de livrare,<br>fără surprize.",
    ed_p="Fișierul conține ceea ce ai randat: aceeași imagine, același sunet, aceeași durată.",
    ed_items=[("Imagine", "Compararea cu sursa arată diferențe doar de compresie, fără alterări de culoare sau cadre sărite."), ("Sunet", "Sunetul PCM e scris neschimbat. Diferențele rămân în cele câteva milisecunde de fade pe care Resolve le aplică la marginea clipurilor."), ("Reimport", "Fișierele se redeschid în Resolve și în FFmpeg fără erori.")],
    edcap="Rezumat al verificărilor din ediția 1.8.0, pe Mac cu Apple Silicon.",
    res_label="CE ESTE ȘI CE NU ESTE", res_h="Un plugin independent.<br>Nu un produs Blackmagic.",
    res_p1="Funcționează cu DaVinci Resolve Studio; versiunea gratuită nu încarcă pluginuri de export. Pluginul rulează local și nu trimite date nicăieri.",
    res_p2="Windows nu face parte din ediția 1.8.0: ultima versiune Windows publicată este v1.7.0 (vezi Descărcare). Dezvoltarea pentru Windows e suspendată; contribuțiile sunt binevenite.",
    res_small="GDC Resolve Encoder este un proiect independent. Nu este dezvoltat, aprobat sau susținut de Blackmagic Design. DaVinci Resolve este marca deținătorului său.",
    acc_label="GDC RESOLVE ENCODER · GRATUIT · SURSĂ DESCHISĂ", acc_h="Descarcă GDC Resolve Encoder.",
    acc_p="Gratuit și cu sursă deschisă. Fără cont, activare, perioadă de probă sau donație obligatorie: instalezi și randezi.",
    dl=f"Descarcă {VERSION} pentru Mac",
    dl_meta=f"Versiunea {VERSION} · GDCResolveEncoder-{VERSION}.pkg · pachet .pkg semnat și notarizat · {SIZE_MB['ro']}",
    req_h="Cerințe", req_p="macOS 26 sau mai nou (minimul declarat de build; verificat pe macOS 27) · Mac cu Apple Silicon · DaVinci Resolve Studio.",
    inst_h="Instalare", inst_p="1. Descarcă pachetul și deschide-l cu dublu-clic.<br>2. Urmează pașii instalatorului (cere parola Mac-ului tău).<br>3. Repornește DaVinci Resolve, apoi alege în Deliver: Format → GDC QuickTime, GDC MP4 sau GDC Matroska, apoi Codec → GDC Encoder și Type → varianta dorită (de exemplu GDC H.265 Software x265).",
    open_h="Sursă deschisă și contribuții",
    open_p=f"Codul sursă este public: <a href=\"{REPO}\">github.com/gordasgdc/gdc-resolve-encoder</a>. Codul pluginului este sub licență MIT; pachetul pentru Mac include FFmpeg, x264 și x265 și se distribuie sub GPLv3, cu textele licențelor și oferta de sursă în pachet. Proiectul primește contribuții prin Issues și Pull Requests, mai ales pentru Windows.",
    status_h="Stare", status="Ediție gratuită pentru macOS. Pot exista limite; le poți semnala în pagina proiectului.",
    foot_l="GDC Resolve Encoder · Dumitru Cristinel Gordas (GDC)", foot_m=f"MIT + GPLv3 (pachet Mac) · {VERSION}",
    foot_links=[("#flux", "Fluxul Deliver"), ("#calitate", "Calitate"), ("#acces", "Descărcare"), (REPO, "Cod sursă")],
    win_h='Windows',
    win_p='Windows — ultima versiune stabilă publicată: v1.7.0. Dezvoltarea și testarea pentru Windows sunt suspendate deoarece nu mai am un sistem Windows disponibil pentru verificări. Versiunea existentă rămâne disponibilă pentru descărcare. Contribuțiile pentru continuarea suportului Windows sunt binevenite.',
    win_dl='Descarcă v1.7.0 pentru Windows',
    win_meta='Versiunea 1.7.0 · gdc-resolve-encoder-windows-x64.zip · arhivă .zip · 50,2 MB · Windows 10/11, 64-bit',
    win_inst_h='Instalare Windows (v1.7.0)',
    win_inst='1. Dezarhivează fișierul.<br>2. Rulează <code>install.bat</code> cu dublu-clic: copiază folderul <code>gdc_resolve_encoder.dvcp.bundle</code> în <code>%ProgramData%\\Blackmagic Design\\DaVinci Resolve\\Support\\IOPlugins\\</code> și cere singur drepturi de administrator.<br>3. Repornește DaVinci Resolve (Studio). Codarea hardware NVENC cere o placă NVIDIA cu driver actual.',
    win_terms_h='Condiții de utilizare pentru v1.7.0',
    win_terms='Versiunea Windows v1.7.0 păstrează condițiile din acea versiune, diferite de ediția gratuită macOS: necesită un cod de activare legat de Machine ID-ul calculatorului, iar susținerea proiectului se face exclusiv ca donație. Termenii și ghidul PDF din arhivă descriu acele condiții. Ediția macOS 1.8.0 nu cere activare, cont, perioadă de probă sau donație.',
    mac_h='macOS — ediția întreținută activ',
    guide="Ghid PDF", guide_file="GDC_Resolve_Encoder_Ghid_RO.pdf",
    legal=[("Termeni", "termeni"), ("Confidențialitate", "confidentialitate"), ("Cookie", "cookie")],
    note="Proiect administrat de dezvoltatori independenți, oferit „as is”. Contribuțiile și donațiile sunt opționale.",
),
"en": dict(
    lang="en", dir="en/", home="../", prefix="../",
    title="GDC Resolve Encoder — Export from Deliver with our own H.264 and H.265 codecs.",
    desc="GDC Resolve Encoder: a free, open-source macOS plugin for DaVinci Resolve Studio. H.264 and H.265, 8-bit and 10-bit, 4:2:2, HDR10, QuickTime, MP4 and Matroska containers straight from Deliver.",
    nav=[("#flux", "The Deliver flow"), ("#calitate", "Quality"), ("#acces", "Download")], cta="Download ↗",
    eyebrow="GDC RESOLVE ENCODER / FOR MAC",
    h1="Render in Deliver.<br>Choose your codec.",
    lead="A plugin for DaVinci Resolve Studio that adds complete H.264 and H.265 encoders to the Format and Codec lists: 10-bit, 4:2:2, HDR10 and its own containers.",
    pill="See the Deliver flow", textlink="The verified numbers ↘",
    pins=[("FORMAT", "Pick the container."), ("TYPE", "Pick the encoder."), ("SETTINGS", "Tune the quality.")],
    feat=[("Three new containers in the Format list.", "GDC QuickTime, GDC MP4 and GDC Matroska appear in Deliver after the native formats. Color tags and HDR10 metadata are written to the file."),
          ("The encoder you choose.", "H.264 and H.265, software (x264, x265) or hardware (Apple VideoToolbox), in 8-bit, 10-bit and 4:2:2 10-bit."),
          ("Quality under your control.", "Constant quality (CRF), target bitrate or constant QP, preset, tune, level and advanced x264/x265 parameters.")],
    fcap="Real capture of the Deliver panel, DaVinci Resolve Studio 21.2.",
    prod_label="ONE PANEL, INSIDE DELIVER", prod_h="No separate app.<br>No extra step.",
    prod_p="The plugin lives in Deliver. Pick the format, the codec and the settings, then render as usual.",
    steps=[("01 Format", "Pick the container.", "GDC QuickTime, GDC MP4 or GDC Matroska. All of them write the color tags, PCM audio and, on PQ exports, the HDR10 metadata."),
           ("02 Type", "Pick the encoder.", "Pick GDC Encoder under Codec, then one of the 8 variants under Type: H.264 or H.265, 8-bit, 10-bit or 4:2:2 10-bit, software or Apple VideoToolbox. Hardware variants appear only if your Mac can actually run them."),
           ("03 Settings", "Tune the quality.", "Constant quality, target bitrate or QP, preset, tune, level and advanced parameters. The log shows the mode actually used."),
           ("04 Render", "Render as usual.", "Queue, range and audio stay Resolve's. Cancelling an export leaves a valid file, truncated at the last written frame.")],
    q_label="MEASURED, NOT ASSUMED", q_h="Verified on cinema<br>camera material.",
    q_p="Every export was compared frame by frame and sample by sample with the source, across 17 exports: full clips and a multi-clip sequence, with sound.",
    stats=[("≥ 40.6 dB", "minimum PSNR, picture vs. source"), ("0", "samples of audio–video offset"), ("100%", "frames counted correctly, at start and end"), ("HDR10", "HDR10 mastering display written to the file, on PQ exports")],
    q_note="On 10-bit 4:2:0, Resolve 21.2 delivers the picture in a non-planar layout that the plugin now reads correctly. Version 1.7.0 produced a corrupted picture (PSNR 14 dB) at 10-bit 4:2:0.",
    ed_label="WHAT THIS MEANS IN PRACTICE", ed_h="Delivery quality,<br>no surprises.",
    ed_p="The file holds what you rendered: the same picture, the same sound, the same duration.",
    ed_items=[("Picture", "Comparing with the source shows compression differences only, with no color changes or skipped frames."), ("Sound", "PCM audio is written unchanged. The only differences are the few milliseconds of fade Resolve applies at clip edges."), ("Reimport", "The files reopen in Resolve and in FFmpeg without errors.")],
    edcap="Summary of the checks for edition 1.8.0, on an Apple Silicon Mac.",
    res_label="WHAT IT IS AND ISN'T", res_h="An independent plugin.<br>Not a Blackmagic product.",
    res_p1="It works with DaVinci Resolve Studio; the free version does not load export plugins. The plugin runs locally and sends no data anywhere.",
    res_p2="Windows is not part of edition 1.8.0: the latest published Windows version is v1.7.0 (see Download). Windows development is suspended; contributions are welcome.",
    res_small="GDC Resolve Encoder is an independent project. It is not developed, endorsed or supported by Blackmagic Design. DaVinci Resolve is a trademark of its owner.",
    acc_label="GDC RESOLVE ENCODER · FREE · OPEN SOURCE", acc_h="Download GDC Resolve Encoder.",
    acc_p="Free and open source. No account, activation, trial period or mandatory donation: install and render.",
    dl=f"Download {VERSION} for Mac",
    dl_meta=f"Version {VERSION} · GDCResolveEncoder-{VERSION}.pkg · signed and notarized .pkg installer · {SIZE_MB['en']}",
    req_h="Requirements", req_p="macOS 26 or later (the minimum declared by the build; verified on macOS 27) · Mac with Apple Silicon · DaVinci Resolve Studio.",
    inst_h="Installation", inst_p="1. Download the package and double-click it.<br>2. Follow the installer (it asks for your Mac password).<br>3. Restart DaVinci Resolve, then in Deliver pick Format → GDC QuickTime, GDC MP4 or GDC Matroska, then Codec → GDC Encoder and Type → the variant you want (for example GDC H.265 Software x265).",
    open_h="Open source and contributions",
    open_p=f"The source code is public: <a href=\"{REPO}\">github.com/gordasgdc/gdc-resolve-encoder</a>. The plugin code is MIT-licensed; the Mac package includes FFmpeg, x264 and x265 and is distributed under the GPLv3, with the license texts and the source offer inside the package. Contributions are welcome through Issues and Pull Requests, especially for Windows.",
    status_h="Status", status="Free edition for macOS. Limits may exist; you can report them on the project page.",
    foot_l="GDC Resolve Encoder · Dumitru Cristinel Gordas (GDC)", foot_m=f"MIT + GPLv3 (Mac package) · {VERSION}",
    foot_links=[("#flux", "The Deliver flow"), ("#calitate", "Quality"), ("#acces", "Download"), (REPO, "Source code")],
    win_h='Windows',
    win_p='Windows — latest stable published version: v1.7.0. Development and testing for Windows are suspended because I no longer have a Windows system available for verification. The existing version stays available for download. Contributions to continue Windows support are welcome.',
    win_dl='Download v1.7.0 for Windows',
    win_meta='Version 1.7.0 · gdc-resolve-encoder-windows-x64.zip · .zip archive · 50.2 MB · Windows 10/11, 64-bit',
    win_inst_h='Windows installation (v1.7.0)',
    win_inst='1. Unzip the file.<br>2. Double-click <code>install.bat</code>: it copies the <code>gdc_resolve_encoder.dvcp.bundle</code> folder to <code>%ProgramData%\\Blackmagic Design\\DaVinci Resolve\\Support\\IOPlugins\\</code> and asks for administrator rights by itself.<br>3. Restart DaVinci Resolve (Studio). NVENC hardware encoding needs an NVIDIA card with a current driver.',
    win_terms_h='Terms of use for v1.7.0',
    win_terms="The Windows v1.7.0 version keeps the terms of that release, which differ from the free macOS edition: it requires an activation code bound to the computer's Machine ID, and supporting the project is done only as a donation. The terms and the PDF guide inside the archive describe those conditions. The macOS 1.8.0 edition asks for no activation, account, trial period or donation.",
    mac_h='macOS — the actively maintained edition',
    guide="PDF guide", guide_file="GDC_Resolve_Encoder_Guide_EN.pdf",
    legal=[("Terms", "termeni"), ("Privacy", "confidentialitate"), ("Cookies", "cookie")],
    note="Project run by independent developers, provided “as is”. Contributions and donations are optional.",
),
"es": dict(
    lang="es", dir="es/", home="../", prefix="../",
    title="GDC Resolve Encoder — Exporta desde Deliver con códecs H.264 y H.265 propios.",
    desc="GDC Resolve Encoder: plugin gratuito y de código abierto para macOS y DaVinci Resolve Studio. H.264 y H.265, 8 y 10 bits, 4:2:2, HDR10, contenedores QuickTime, MP4 y Matroska directamente desde Deliver.",
    nav=[("#flux", "El flujo de Deliver"), ("#calitate", "Calidad"), ("#acces", "Descarga")], cta="Descargar ↗",
    eyebrow="GDC RESOLVE ENCODER / PARA MAC",
    h1="Renderiza en Deliver.<br>Elige tu códec.",
    lead="Un plugin para DaVinci Resolve Studio que añade a las listas Format y Codec encoders H.264 y H.265 completos: 10 bits, 4:2:2, HDR10 y contenedores propios.",
    pill="Ver el flujo de Deliver", textlink="Las cifras verificadas ↘",
    pins=[("FORMAT", "Eliges el contenedor."), ("TYPE", "Eliges el encoder."), ("AJUSTES", "Regulas la calidad.")],
    feat=[("Tres contenedores nuevos en la lista Format.", "GDC QuickTime, GDC MP4 y GDC Matroska aparecen en Deliver tras los formatos nativos. Las etiquetas de color y los metadatos HDR10 se escriben en el archivo."),
          ("El encoder que eliges.", "H.264 y H.265, por software (x264, x265) o por hardware (Apple VideoToolbox), en 8 bits, 10 bits y 4:2:2 de 10 bits."),
          ("La calidad, bajo tu control.", "Calidad constante (CRF), bitrate objetivo o QP constante, preset, tune, nivel y parámetros avanzados de x264/x265.")],
    fcap="Captura real del panel Deliver, DaVinci Resolve Studio 21.2.",
    prod_label="UN SOLO PANEL, DENTRO DE DELIVER", prod_h="Sin aplicación aparte.<br>Sin paso extra.",
    prod_p="El plugin vive en Deliver. Eliges el formato, el códec y los ajustes, y renderizas como siempre.",
    steps=[("01 Format", "Elige el contenedor.", "GDC QuickTime, GDC MP4 o GDC Matroska. Todos escriben las etiquetas de color, el audio PCM y, en exportaciones PQ, los metadatos HDR10."),
           ("02 Type", "Elige el encoder.", "En Codec eliges GDC Encoder y en Type una de las 8 variantes: H.264 o H.265, 8 bits, 10 bits o 4:2:2 de 10 bits, por software o Apple VideoToolbox. Las variantes por hardware solo aparecen si tu Mac puede ejecutarlas."),
           ("03 Ajustes", "Regula la calidad.", "Calidad constante, bitrate objetivo o QP, preset, tune, nivel y parámetros avanzados. El registro muestra el modo realmente usado."),
           ("04 Render", "Renderiza como siempre.", "La cola, el rango y el audio siguen siendo de Resolve. Cancelar una exportación deja un archivo válido, truncado en el último fotograma escrito.")],
    q_label="MEDIDO, NO SUPUESTO", q_h="Verificado con material<br>de cámara de cine.",
    q_p="Cada exportación se comparó fotograma a fotograma y muestra a muestra con el original, en 17 exportaciones: clips completos y una secuencia de varios clips, con sonido.",
    stats=[("≥ 40,6 dB", "PSNR mínimo, imagen frente al original"), ("0", "muestras de desfase audio–vídeo"), ("100%", "fotogramas contados bien, al inicio y al final"), ("HDR10", "mastering display HDR10 escrito en el archivo, en exportaciones PQ")],
    q_note="En 10 bits 4:2:0, Resolve 21.2 entrega la imagen en una disposición no planar que el plugin ya lee correctamente. La versión 1.7.0 producía una imagen alterada (PSNR 14 dB) en 10 bits 4:2:0.",
    ed_label="QUÉ SIGNIFICA EN LA PRÁCTICA", ed_h="Calidad de entrega,<br>sin sorpresas.",
    ed_p="El archivo contiene lo que renderizaste: la misma imagen, el mismo sonido, la misma duración.",
    ed_items=[("Imagen", "La comparación con el original solo muestra diferencias de compresión, sin cambios de color ni fotogramas saltados."), ("Sonido", "El audio PCM se escribe sin cambios. Solo difieren los pocos milisegundos de fundido que Resolve aplica en los bordes de los clips."), ("Reimportación", "Los archivos se reabren en Resolve y en FFmpeg sin errores.")],
    edcap="Resumen de las comprobaciones de la edición 1.8.0, en un Mac con Apple Silicon.",
    res_label="QUÉ ES Y QUÉ NO ES", res_h="Un plugin independiente.<br>No un producto de Blackmagic.",
    res_p1="Funciona con DaVinci Resolve Studio; la versión gratuita no carga plugins de exportación. El plugin se ejecuta en local y no envía datos a ninguna parte.",
    res_p2="Windows no forma parte de la edición 1.8.0: la última versión de Windows publicada es v1.7.0 (véase Descarga). El desarrollo para Windows está suspendido; se aceptan contribuciones.",
    res_small="GDC Resolve Encoder es un proyecto independiente. No está desarrollado, aprobado ni respaldado por Blackmagic Design. DaVinci Resolve es una marca de su titular.",
    acc_label="GDC RESOLVE ENCODER · GRATIS · CÓDIGO ABIERTO", acc_h="Descarga GDC Resolve Encoder.",
    acc_p="Gratuito y de código abierto. Sin cuenta, activación, periodo de prueba ni donación obligatoria: instalas y renderizas.",
    dl=f"Descargar {VERSION} para Mac",
    dl_meta=f"Versión {VERSION} · GDCResolveEncoder-{VERSION}.pkg · instalador .pkg firmado y notarizado · {SIZE_MB['es']}",
    req_h="Requisitos", req_p="macOS 26 o posterior (el mínimo declarado por el build; verificado en macOS 27) · Mac con Apple Silicon · DaVinci Resolve Studio.",
    inst_h="Instalación", inst_p="1. Descarga el paquete y ábrelo con doble clic.<br>2. Sigue el instalador (pide la contraseña de tu Mac).<br>3. Reinicia DaVinci Resolve y, en Deliver, elige Format → GDC QuickTime, GDC MP4 o GDC Matroska y luego Codec → GDC Encoder y Type → la variante deseada (por ejemplo GDC H.265 Software x265).",
    open_h="Código abierto y contribuciones",
    open_p=f"El código fuente es público: <a href=\"{REPO}\">github.com/gordasgdc/gdc-resolve-encoder</a>. El código del plugin tiene licencia MIT; el paquete para Mac incluye FFmpeg, x264 y x265 y se distribuye bajo GPLv3, con los textos de licencia y la oferta de código fuente dentro del paquete. Se aceptan contribuciones mediante Issues y Pull Requests, sobre todo para Windows.",
    status_h="Estado", status="Edición gratuita para macOS. Puede haber límites; puedes comunicarlos en la página del proyecto.",
    foot_l="GDC Resolve Encoder · Dumitru Cristinel Gordas (GDC)", foot_m=f"MIT + GPLv3 (paquete Mac) · {VERSION}",
    foot_links=[("#flux", "El flujo de Deliver"), ("#calitate", "Calidad"), ("#acces", "Descarga"), (REPO, "Código fuente")],
    win_h='Windows',
    win_p='Windows — última versión estable publicada: v1.7.0. El desarrollo y las pruebas para Windows están suspendidos porque ya no dispongo de un sistema Windows para verificar. La versión existente sigue disponible para descargar. Se agradecen las contribuciones para continuar el soporte de Windows.',
    win_dl='Descargar v1.7.0 para Windows',
    win_meta='Versión 1.7.0 · gdc-resolve-encoder-windows-x64.zip · archivo .zip · 50,2 MB · Windows 10/11, 64 bits',
    win_inst_h='Instalación en Windows (v1.7.0)',
    win_inst='1. Descomprime el archivo.<br>2. Ejecuta <code>install.bat</code> con doble clic: copia la carpeta <code>gdc_resolve_encoder.dvcp.bundle</code> a <code>%ProgramData%\\Blackmagic Design\\DaVinci Resolve\\Support\\IOPlugins\\</code> y pide por sí mismo permisos de administrador.<br>3. Reinicia DaVinci Resolve (Studio). La codificación por hardware NVENC requiere una tarjeta NVIDIA con un controlador actual.',
    win_terms_h='Condiciones de uso de v1.7.0',
    win_terms='La versión de Windows v1.7.0 conserva las condiciones de esa versión, distintas de la edición gratuita para macOS: requiere un código de activación vinculado al Machine ID del ordenador, y el apoyo al proyecto se hace únicamente como donación. Los términos y la guía PDF dentro del archivo describen esas condiciones. La edición 1.8.0 para macOS no pide activación, cuenta, periodo de prueba ni donación.',
    mac_h='macOS — la edición mantenida activamente',
    guide="Guía PDF", guide_file="GDC_Resolve_Encoder_Guia_ES.pdf",
    legal=[("Términos", "termeni"), ("Privacidad", "confidentialitate"), ("Cookies", "cookie")],
    note="Proyecto administrado por desarrolladores independientes, ofrecido «as is». Las contribuciones y donaciones son opcionales.",
),
}

CSS = """
:root{--ink:#101214;--ink2:#1a1d20;--muted:#5d6266;--line:#d9dcdd;--paper:#fff;--soft:#eef1f1;--accent:#1d7480;--accent-l:#6fc0c9;--mono:ui-monospace,SFMono-Regular,Menlo,monospace}
*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:var(--paper);color:var(--ink);font-family:-apple-system,BlinkMacSystemFont,"Helvetica Neue",Arial,sans-serif;-webkit-font-smoothing:antialiased}
a{color:inherit;text-decoration:none}button{font:inherit;cursor:pointer}
header{height:86px;display:flex;align-items:center;justify-content:space-between;max-width:1380px;padding:0 48px;margin:auto}
.brand{display:flex;align-items:center;gap:12px;font-size:20px;font-weight:650;letter-spacing:-.7px}.brand svg{width:31px;height:31px;color:var(--accent)}
nav{display:flex;align-items:center;gap:32px;font-size:12px}nav .nav-cta{border:1px solid var(--ink);border-radius:40px;padding:12px 20px}
.langs{font-size:12px;letter-spacing:.06em;opacity:.8;white-space:nowrap}.langs a[aria-current]{font-weight:700;text-decoration:underline}
.label{font-size:10px;letter-spacing:.2em;text-transform:uppercase;font-weight:600}
.intro{max-width:1280px;padding:64px 48px 40px;margin:auto;display:grid;grid-template-columns:1.45fr 1fr;gap:90px;align-items:end}
.intro h1{font-size:clamp(44px,5.2vw,78px);font-weight:400;line-height:1.03;letter-spacing:-.055em;margin:22px 0 0}
.intro p{font-size:16px;line-height:1.65;max-width:42ch;margin:0 0 22px;color:var(--muted)}
.links{display:flex;gap:22px;align-items:center;font-size:12px}.pill{display:inline-flex;align-items:center;gap:28px;background:var(--ink);color:#fff;padding:15px 22px;border-radius:40px}
.text-link{border-bottom:1px solid #999;padding:5px 0}
.stage{background:var(--ink);padding:56px 0 0;color:#fff}.stage-in{max-width:1380px;margin:auto;padding:0 48px}
.shot{margin:0}.shot-in{position:relative}.shot img{display:block;width:100%;height:auto;border-radius:10px 10px 0 0;box-shadow:0 -1px 0 #ffffff22,0 30px 80px #0008}
.pin{position:absolute;left:var(--x);top:var(--y);padding:6px;border:0;background:none;display:flex;align-items:center;gap:9px;color:#fff}
.pin span{width:29px;height:29px;display:grid;place-items:center;border-radius:50%;border:1px solid #fff;background:#101214cc;font-size:12px;box-shadow:0 0 0 4px #ffffff40}
.pin em{display:none;font-family:var(--mono);font-size:11px;letter-spacing:.08em;font-style:normal;background:#fffffff0;padding:7px 11px;color:#14181a}
.pin[aria-pressed=true] span{background:var(--accent);border-color:var(--accent-l)}
.cap{max-width:1380px;margin:auto;padding:30px 48px 56px;display:grid;grid-template-columns:1fr 1fr;gap:70px;border-top:1px solid #ffffff1a}
.cap h2{font-size:30px;line-height:1.18;font-weight:400;letter-spacing:-.025em;margin:0}.cap p{font-size:14px;color:#a9b1b4;line-height:1.7;margin:0}.cap small{display:block;font-size:10px;margin-top:13px;color:#7f888b}
.flow-head{max-width:1184px;margin:auto;padding:80px 20px 0}.flow-head h2{font-size:46px;font-weight:400;line-height:1.1;letter-spacing:-.04em;margin:16px 0 14px}.flow-head p{color:var(--muted);font-size:14px;line-height:1.7;max-width:48ch;margin:0}
.pipe{max-width:1184px;margin:34px auto 0;padding:0 20px;display:grid;grid-template-columns:repeat(4,1fr);border-top:1px solid var(--ink)}
.pipe button{border:0;background:none;text-align:left;padding:22px 16px 22px 0;font-size:12px;color:var(--muted);border-top:3px solid transparent;margin-top:-2px}
.pipe button b{display:block;font-family:var(--mono);font-size:12px;font-weight:500;margin-bottom:6px;letter-spacing:.04em}
.pipe button[aria-selected=true]{color:var(--ink);border-top-color:var(--accent)}
.pipe-detail{max-width:1184px;margin:0 auto;padding:10px 20px 70px;display:grid;grid-template-columns:1fr 1fr;gap:80px}
.pipe-detail h3{font-size:28px;line-height:1.2;font-weight:400;letter-spacing:-.025em;margin:0}.pipe-detail p{font-size:14px;line-height:1.7;color:var(--muted);margin:0}
.tour{max-width:1184px;margin:0 auto;padding:0 20px 90px}.tour img{display:block;width:100%;height:auto;border:1px solid var(--line);border-radius:8px;transition:opacity .25s}.tour img.swap{opacity:0}.tour figcaption{font-size:10px;color:var(--muted);padding:14px 0 0;text-align:center}
.quality{background:var(--soft);padding:80px 0 70px}.quality-in{max-width:1184px;margin:auto;padding:0 20px}
.quality h2{font-size:44px;font-weight:400;line-height:1.1;letter-spacing:-.04em;margin:18px 0 20px}.quality-in>p{font-size:14px;line-height:1.7;color:var(--muted);max-width:60ch;margin:0}
.stats{display:grid;grid-template-columns:repeat(4,1fr);gap:0;margin-top:44px;border-top:1px solid var(--ink)}
.stat{padding:26px 22px 8px 0}.stat b{display:block;font-family:var(--mono);font-size:34px;font-weight:500;letter-spacing:-.03em;color:var(--accent)}.stat span{display:block;margin-top:10px;font-size:12px;line-height:1.5;color:var(--muted);max-width:22ch}
.qnote{font-size:11px;line-height:1.7;color:var(--muted);max-width:90ch;margin:34px 0 0}
.editorial{max-width:1184px;margin:80px auto 90px;padding:0 20px;display:grid;grid-template-columns:.85fr 1.15fr;gap:100px;align-items:start}
.editorial-intro{position:sticky;top:60px}.editorial h2{font-size:42px;font-weight:400;line-height:1.1;letter-spacing:-.04em;margin:18px 0 22px}.editorial p{font-size:14px;line-height:1.7;color:var(--muted);max-width:36ch}
.item{border-bottom:1px solid var(--line);padding:26px 0;display:grid;grid-template-columns:130px 1fr;gap:20px}.item:first-child{border-top:1px solid var(--ink)}.item h3{font-family:var(--mono);font-size:12px;letter-spacing:.1em;text-transform:uppercase;font-weight:500;margin:2px 0}.item p{font-size:14px;line-height:1.7;margin:0;max-width:none;color:var(--ink)}
.resolve{max-width:1184px;margin:auto;padding:60px 20px 90px;border-top:1px solid var(--line);display:grid;grid-template-columns:1fr 1fr;gap:80px}
.resolve h2{font-size:36px;font-weight:400;letter-spacing:-.035em;line-height:1.15;margin:16px 0}.resolve p{font-size:14px;line-height:1.8;color:var(--muted)}.resolve small{font-size:10px;line-height:1.7;color:var(--muted);display:block}
.access{background:var(--ink);color:#fff;text-align:center;padding:80px 20px}.access h2{font-size:44px;font-weight:400;letter-spacing:-.04em;margin:18px 0}
.access p{max-width:65ch;margin:0 auto 26px;color:#aab3b6;font-size:14px;line-height:1.7}.access .pill{background:#fff;color:var(--ink)}
.access h3{font-weight:500;margin:34px 0 10px}.access code{font-family:var(--mono);font-size:11px;word-break:break-all;color:#d7e4e6}.access a{border-bottom:1px solid #6b7679}.access .pill{border:0}
.access .label{color:var(--accent-l)}
footer{max-width:1280px;margin:auto;padding:46px 48px;font-size:11px;display:flex;justify-content:space-between;gap:30px;color:var(--muted)}footer div{display:flex;gap:25px;flex-wrap:wrap}
a:focus-visible,button:focus-visible{outline:2px solid #2468a5;outline-offset:5px}
@media(max-width:1000px){.pin em{display:none}.pin{padding:10px}}
@media(max-width:760px){header{height:72px;padding:0 22px}.brand{font-size:18px}nav{gap:12px}nav>a:not(.nav-cta){display:none}nav .nav-cta{font-size:11px;padding:10px 14px}
.intro{padding:40px 24px 28px;grid-template-columns:1fr;gap:26px}.intro h1{font-size:46px}.intro p{font-size:14px}
.stage{padding-top:34px}.stage-in{padding:0 0 0 12px}.shot{overflow-x:auto;-webkit-overflow-scrolling:touch}.shot-in{min-width:880px}.brand{font-size:16px;white-space:nowrap}.brand .w2{display:none}.pin span{width:25px;height:25px;font-size:10px}
.cap{padding:24px 24px 40px;grid-template-columns:1fr;gap:16px}.cap h2{font-size:26px}
.flow-head{padding:50px 24px 0}.flow-head h2{font-size:34px}.pipe{padding:0 24px;grid-template-columns:1fr 1fr}.pipe-detail{padding:10px 24px 44px;grid-template-columns:1fr;gap:14px}.tour{padding:0 12px 56px}
.quality{padding:50px 0}.quality-in{padding:0 24px}.quality h2{font-size:34px}.stats{grid-template-columns:1fr 1fr}.stat b{font-size:26px}
.editorial{grid-template-columns:1fr;gap:24px;margin:50px 0;padding:0 24px}.editorial-intro{position:static}.editorial h2{font-size:34px}.item{grid-template-columns:1fr;gap:6px}
.resolve{grid-template-columns:1fr;gap:12px;padding:40px 24px 50px}.resolve h2{font-size:30px}.access{padding:52px 24px}.access h2{font-size:34px}
footer{padding:34px 24px;display:block}footer div{margin-top:18px}}
@media(prefers-reduced-motion:reduce){html{scroll-behavior:auto}.tour img{transition:none}}
"""

SYMBOL = ('<svg viewBox="0 0 32 32" aria-hidden="true"><rect x="2" y="5" width="28" height="22" rx="3" fill="none" stroke="currentColor" stroke-width="2.4"/>'
          '<path d="M12 11l9 5-9 5z" fill="currentColor"/></svg>')

# Panel captures (neutral crops of the Deliver page; see PROJECT_STATE.md).
TOUR = ["assets/deliver-format.jpg", "assets/deliver-codec.jpg", "assets/deliver-settings.jpg", "assets/deliver-render.jpg"]
HERO = "assets/deliver-hero.jpg"
PINS = [("4.3%", "19%"), ("36.6%", "25%"), ("68.9%", "66%")]


def js_str(s):
    return "'" + s.replace("\\", "\\\\").replace("'", "\\'") + "'"


def page(code):
    t = T[code]
    e = html.escape
    alts = "".join(f'<link rel="alternate" hreflang="{c}" href="{BASE}{T[c]["dir"]}">' for c in T)
    langs = " · ".join(
        f'<a href="{(t["home"] if c == "ro" else t["home"] + c + "/") if code != c else "./"}" hreflang="{c}" lang="{c}"'
        + (' aria-current="page"' if c == code else "") + f">{c.upper()}</a>" for c in T)
    pre = t["prefix"]
    pins = "".join(
        f'<button class="pin" style="--x:{x};--y:{y}" data-feature="{i}" aria-label="{e(t["pins"][i][0])}" aria-pressed="{"true" if i == 0 else "false"}"><span>0{i+1}</span><em>{e(t["pins"][i][0])}</em></button>'
        for i, (x, y) in enumerate(PINS))
    nav = "".join(f'<a href="{h}">{e(l)}</a>' for h, l in t["nav"])
    pipe = "".join(
        f'<button role="tab" data-step="{i}" aria-selected="{"true" if i == 0 else "false"}"><b>{e(s[0].split(" ")[0])}</b>{e(s[0].split(" ", 1)[1])}</button>' for i, s in enumerate(t["steps"]))
    stats = "".join(f'<div class="stat"><b>{e(a)}</b><span>{e(b)}</span></div>' for a, b in t["stats"])
    items = "".join(f'<div class="item"><h3>{e(a)}</h3><p>{e(b)}</p></div>' for a, b in t["ed_items"])
    foot = "".join(f'<a href="{h}">{e(l)}</a>' for h, l in t["foot_links"]) + "".join(f'<a href="https://gordas.dev/{u}">{e(l)}</a>' for l, u in t["legal"])
    dl_url = f"{REPO}/releases/latest/download/GDCResolveEncoder-{VERSION}.pkg"
    guide = f'{pre}guides/{t["guide_file"]}'
    feats = ",".join("[" + js_str(a) + "," + js_str(b) + "]" for a, b in t["feat"])
    steps = ",".join("[" + js_str(a) + "," + js_str(b) + "]" for _, a, b in t["steps"])
    tour = ",".join(js_str(pre + p) for p in TOUR)
    return f"""<!doctype html><html lang="{t['lang']}"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="description" content="{e(t['desc'])}"><link rel="canonical" href="{BASE}{t['dir']}">{alts}<link rel="alternate" hreflang="x-default" href="{BASE}en/">
<meta property="og:title" content="GDC Resolve Encoder"><meta property="og:description" content="{e(t['desc'])}"><meta property="og:image" content="{BASE}assets/social-preview.png"><meta property="og:url" content="{BASE}{t['dir']}">
<link rel="icon" type="image/svg+xml" href="{pre}assets/simbol.svg"><title>{e(t['title'])}</title><style>{CSS}</style></head><body>
<header><a class="brand" href="#" aria-label="GDC Resolve Encoder">{SYMBOL}GDC Resolve <span class="w2" style="font-weight:400">Encoder</span></a><nav>{nav}<span class="langs">{langs}</span><a class="nav-cta" href="#acces">{e(t['cta'])}</a></nav></header>
<main><section class="intro"><div><span class="label">{e(t['eyebrow'])}</span><h1>{t['h1']}</h1></div><div><p>{e(t['lead'])}</p><div class="links"><a class="pill" href="#flux">{e(t['pill'])} <span>↗</span></a><a class="text-link" href="#calitate">{e(t['textlink'])}</a></div></div></section>
<section class="stage" id="hero"><div class="stage-in"><figure class="shot"><div class="shot-in"><img id="hero-img" src="{pre}{HERO}" alt="{e(t['fcap'])}" width="1600" height="900">{pins}</div></figure></div>
<div class="cap" aria-live="polite"><h2 id="feature-title">{e(t['feat'][0][0])}</h2><div><p id="feature-body">{e(t['feat'][0][1])}</p><small>{e(t['fcap'])}</small></div></div></section>
<section id="flux"><div class="flow-head"><span class="label">{e(t['prod_label'])}</span><h2>{t['prod_h']}</h2><p>{e(t['prod_p'])}</p></div>
<div class="pipe" role="tablist">{pipe}</div><div class="pipe-detail" role="tabpanel" aria-live="polite"><h3 id="step-title">{e(t['steps'][0][1])}</h3><p id="step-body">{e(t['steps'][0][2])}</p></div>
<figure class="tour"><img id="tour-img" src="{pre}{TOUR[0]}" alt="{e(t['fcap'])}"><figcaption>{e(t['fcap'])}</figcaption></figure></section>
<section class="quality" id="calitate"><div class="quality-in"><span class="label">{e(t['q_label'])}</span><h2>{t['q_h']}</h2><p>{e(t['q_p'])}</p><div class="stats">{stats}</div><p class="qnote">{e(t['q_note'])}</p></div></section>
<section class="editorial"><div class="editorial-intro"><span class="label">{e(t['ed_label'])}</span><h2>{t['ed_h']}</h2><p>{e(t['ed_p'])}</p><p style="font-size:11px">{e(t['edcap'])}</p></div><div>{items}</div></section>
<section class="resolve" id="resolve"><div><span class="label">{e(t['res_label'])}</span><h2>{t['res_h']}</h2></div><div><p>{e(t['res_p1'])}</p><p>{e(t['res_p2'])}</p><small>{e(t['res_small'])}</small></div></section>
<section class="access" id="acces"><span class="label">{e(t['acc_label'])}</span><h2>{e(t['acc_h'])}</h2><p>{e(t['acc_p'])}</p><h3 style="margin-top:6px">{e(t['mac_h'])}</h3>
<p><a class="pill" href="{dl_url}">{e(t['dl'])} <span>↓</span></a></p>
<p style="font-size:12px">{e(t['dl_meta'])}<br>SHA-256: <code>{SHA}</code></p>
<p style="font-size:12px"><a href="{guide}">{e(t["guide"])}</a></p>
<h3>{e(t['req_h'])}</h3><p>{e(t['req_p'])}</p><h3>{e(t['inst_h'])}</h3><p>{t['inst_p']}</p><h3>{e(t['open_h'])}</h3><p>{t['open_p']}</p>
<div id="windows" style="max-width:68ch;margin:46px auto 0;padding-top:34px;border-top:1px solid #ffffff26"><h3 style="margin-top:0">{e(t['win_h'])}</h3><p>{e(t['win_p'])}</p>
<p><a class="pill" style="background:none;color:#fff;border:1px solid #fff" href="{WIN_URL}">{e(t['win_dl'])} <span>↓</span></a></p>
<p style="font-size:12px">{e(t['win_meta'])}<br>SHA-256: <code>{WIN_SHA}</code></p><h3>{e(t['win_inst_h'])}</h3><p>{t['win_inst']}</p><h3>{e(t['win_terms_h'])}</h3><p>{e(t['win_terms'])}</p></div>
<p class="label" style="margin-top:28px">{e(t['status_h'])}</p><p style="font-size:11px;max-width:70ch">{e(t['status'])}</p></section></main>
<footer><span>{e(t['foot_l'])}<br><span style="display:block;margin-top:10px">{e(t['foot_m'])}</span><span style="display:block;margin-top:6px;max-width:48ch">{e(t['note'])}</span></span><div>{foot}</div></footer>
<script>
const features=[{feats}];
document.querySelectorAll('[data-feature]').forEach(b=>b.addEventListener('click',()=>{{const f=features[Number(b.dataset.feature)];document.getElementById('feature-title').textContent=f[0];document.getElementById('feature-body').textContent=f[1];document.querySelectorAll('[data-feature]').forEach(x=>x.setAttribute('aria-pressed',String(x===b)))}}));
const steps=[{steps}];const tour=[{tour}];
function selectStep(n){{document.getElementById('step-title').textContent=steps[n][0];document.getElementById('step-body').textContent=steps[n][1];const im=document.getElementById('tour-img');if(im.getAttribute('src')!==tour[n]){{if(matchMedia('(prefers-reduced-motion:reduce)').matches){{im.src=tour[n]}}else{{im.classList.add('swap');setTimeout(()=>{{const d=()=>im.classList.remove('swap');im.onload=d;im.onerror=d;im.src=tour[n];setTimeout(d,1200)}},220)}}}}document.querySelectorAll('[data-step]').forEach(b=>{{b.setAttribute('aria-selected',String(Number(b.dataset.step)===n));b.tabIndex=Number(b.dataset.step)===n?0:-1}})}}
document.querySelectorAll('[data-step]').forEach(b=>{{b.addEventListener('click',()=>selectStep(Number(b.dataset.step)));b.addEventListener('keydown',e=>{{if(['ArrowLeft','ArrowRight'].includes(e.key)){{e.preventDefault();const n=(Number(b.dataset.step)+(e.key==='ArrowRight'?1:3))%4;selectStep(n);document.querySelector('[data-step="'+n+'"]').focus()}}}})}});
</script></body></html>
"""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("out")
    a = ap.parse_args()
    for code in T:
        d = os.path.join(a.out, T[code]["dir"])
        os.makedirs(d, exist_ok=True)
        with open(os.path.join(d, "index.html"), "w", encoding="utf-8") as f:
            f.write(page(code))
        print("wrote", os.path.join(d, "index.html"))


if __name__ == "__main__":
    sys.exit(main())
