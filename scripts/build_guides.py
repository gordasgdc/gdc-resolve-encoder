#!/usr/bin/env python3
"""Generates the user guide PDFs (RO/EN/ES) for GDC Resolve Encoder.

Usage: scripts/build_guides.py <assets-dir> <out-dir> [--version 1.8.0]
<assets-dir> holds deliver-format.jpg / deliver-codec.jpg / deliver-settings.jpg
(from scripts/build_site_assets.py). Writes GDC_Resolve_Encoder_Ghid_RO.pdf,
GDC_Resolve_Encoder_Guide_EN.pdf and GDC_Resolve_Encoder_Guia_ES.pdf and prints
a summary (pages, outline entries, images, fonts embedded) for each.
"""
import os
import sys

from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (BaseDocTemplate, Frame, Image, KeepTogether, PageBreak, PageTemplate, Paragraph, Spacer,
                                Table, TableStyle)
from reportlab.platypus.tableofcontents import TableOfContents

VERSION = "1.8.0"
SUP = "/System/Library/Fonts/Supplemental/"
pdfmetrics.registerFont(TTFont("Body", SUP + "Arial.ttf"))
pdfmetrics.registerFont(TTFont("BodyB", SUP + "Arial Bold.ttf"))
pdfmetrics.registerFont(TTFont("BodyI", SUP + "Arial Italic.ttf"))
pdfmetrics.registerFont(TTFont("Mono", SUP + "Courier New.ttf"))
pdfmetrics.registerFontFamily("Body", normal="Body", bold="BodyB", italic="BodyI", boldItalic="BodyB")

INK = colors.HexColor("#101214")
MUTED = colors.HexColor("#5d6266")
ACCENT = colors.HexColor("#1d7480")
LINE = colors.HexColor("#d9dcdd")
SOFT = colors.HexColor("#eef1f1")

ST = {
    "h1": ParagraphStyle("h1", fontName="BodyB", fontSize=19, leading=23, textColor=INK, spaceBefore=4, spaceAfter=8),
    "h2": ParagraphStyle("h2", fontName="BodyB", fontSize=12.5, leading=16, textColor=ACCENT, spaceBefore=10, spaceAfter=4),
    "p": ParagraphStyle("p", fontName="Body", fontSize=10, leading=14.5, textColor=INK, spaceAfter=6, alignment=TA_LEFT),
    "li": ParagraphStyle("li", fontName="Body", fontSize=10, leading=14, textColor=INK, leftIndent=12, bulletIndent=0, spaceAfter=3, bulletFontName="Body"),
    "cap": ParagraphStyle("cap", fontName="BodyI", fontSize=8.5, leading=11, textColor=MUTED, spaceAfter=8),
    "code": ParagraphStyle("code", fontName="Mono", fontSize=8.6, leading=11.5, textColor=INK, backColor=SOFT, borderPadding=5, spaceAfter=8),
    "cell": ParagraphStyle("cell", fontName="Body", fontSize=8.8, leading=11.5, textColor=INK),
    "cellb": ParagraphStyle("cellb", fontName="BodyB", fontSize=8.8, leading=11.5, textColor=INK),
    "toc1": ParagraphStyle("toc1", fontName="Body", fontSize=10.5, leading=17, textColor=INK, leftIndent=0),
    "note": ParagraphStyle("note", fontName="Body", fontSize=9, leading=13, textColor=INK, backColor=SOFT, borderPadding=7, spaceAfter=8),
}

REPO = "https://github.com/gordasgdc/gdc-resolve-encoder"
SITE = "https://gordas.dev/gdc-resolve-encoder/"
PATH = "/Library/Application Support/Blackmagic Design/DaVinci Resolve/IOPlugins/gdc_resolve_encoder.dvcp.bundle"

L = {}

L["ro"] = dict(
    file="GDC_Resolve_Encoder_Ghid_RO.pdf", lang="ro", title="Ghid de utilizare", sub="Plugin gratuit de export H.264 și H.265 pentru DaVinci Resolve Studio pe Mac",
    ver=f"Versiunea {VERSION}", toc="Cuprins", foot="GDC Resolve Encoder · Dumitru Cristinel Gordas (GDC)", page="Pagina",
    tbl_h=("Setare", "Ce face"), var_h=("Variantă din Type", "Encoder", "Adâncime / crominanță"),
    sections=[
        ("1. Ce este", [
            ("p", "GDC Resolve Encoder adaugă în DaVinci Resolve Studio, direct în pagina Deliver, encodere H.264 și H.265 complete (x264, x265 și Apple VideoToolbox), trei containere proprii (GDC QuickTime, GDC MP4, GDC Matroska) și metadata HDR10 scrisă în fișier."),
            ("p", "Ediția 1.8.0 pentru macOS este <b>gratuită și cu sursă deschisă</b>: nu cere cont, activare, perioadă de probă sau donație. Funcționează numai cu DaVinci Resolve Studio; versiunea gratuită Resolve nu încarcă pluginuri de export. Pluginul rulează local și nu trimite date nicăieri."),
        ]),
        ("2. Instalare", [
            ("p", "Cerințe: macOS 26 sau mai nou (minim declarat; verificat pe macOS 27), Mac cu Apple Silicon, DaVinci Resolve Studio."),
            ("ul", ["Descarcă <b>GDCResolveEncoder-1.8.0.pkg</b> de pe pagina proiectului și deschide-l cu dublu-clic.", "Urmează pașii instalatorului (acceptă licența; cere parola Mac-ului tău).", "Repornește DaVinci Resolve. Nu e nevoie să instalezi altceva: FFmpeg și bibliotecile de codare vin în pachet."]),
            ("p", "Pachetul instalează în:"),
            ("code", PATH),
            ("p", "Pentru dezinstalare, închide Resolve și mută folderul de mai sus la Coș (Finder cere parola)."),
        ]),
        ("3. Fluxul în Deliver", [
            ("p", "În pagina Deliver, în Render Settings, filele Video:"),
            ("ul", ["<b>Format</b>: alege GDC QuickTime, GDC MP4 sau GDC Matroska (apar după formatele native).", "<b>Codec</b>: alege GDC Encoder.", "<b>Type</b>: alege una dintre cele 8 variante (tabelul de mai jos).", "<b>Plugin Settings</b>: reglează calitatea, apoi adaugă jobul în coada de randare ca de obicei."]),
            ("img", "guide-format.jpg", "Lista Format: GDC QuickTime, GDC MP4 și GDC Matroska."),
            ("img", "guide-codec.jpg", "Codec = GDC Encoder; lista Type cu cele 8 variante."),
        ]),
        ("4. Variantele din Type", [
            ("var", [("GDC H.264 (Software x264)", "libx264", "8-bit 4:2:0"), ("GDC H.265 (Software x265)", "libx265", "8-bit 4:2:0"), ("GDC H.264 (Apple VideoToolbox)", "hardware", "8-bit 4:2:0"), ("GDC H.265 (Apple VideoToolbox)", "hardware", "8-bit 4:2:0"), ("GDC H.264 10-bit (x264 High10)", "libx264", "10-bit 4:2:0"), ("GDC H.265 10-bit (x265 Main10)", "libx265", "10-bit 4:2:0"), ("GDC H.264 4:2:2 10-bit (High 4:2:2)", "libx264", "10-bit 4:2:2"), ("GDC H.265 4:2:2 10-bit (Main 4:2:2 10)", "libx265", "10-bit 4:2:2")]),
            ("p", "Variantele hardware apar în listă doar dacă Mac-ul tău le poate rula efectiv. HDR10 Metadata este disponibil la variantele software."),
        ]),
        ("5. Setările din panou", [
            ("tbl", [("Preset", "Compromis viteză / eficiență, de la ultrafast la veryslow. Mai lent = fișier mai mic la aceeași calitate."), ("Level", "Nivelul H.264/H.265 (3.0 – 5.2) sau Auto. Lasă Auto, în afară de cerințe de compatibilitate cu playere vechi."), ("Tune", "Optimizări pentru conținut: film, animation, grain, stillimage, psnr, ssim, fastdecode, zerolatency (lista diferă puțin între H.264 și H.265)."), ("Rate Control", "Constant Quality (CRF), Target Bitrate sau Constant QP. CRF e alegerea obișnuită: calitate constantă, dimensiune variabilă."), ("Quality (CRF)", "0 – 51, mai mic = mai bună calitate. Punct de plecare: 18 pentru master, 20–23 pentru livrare web."), ("Quality (1–100)", "La VideoToolbox, în modul calitate: mai mare = mai bună. Punct de plecare: 65."), ("Keyframe Interval", "Distanța dintre keyframe-uri, în secunde (implicit 2)."), ("Advanced Params", "Parametri x264/x265 expert, de exemplu aq-mode=3:psy-rd=1.0,0.15. Au prioritate față de setările de mai sus."), ("HDR10 Metadata", "Off sau On (numai exporturi PQ): primare de mastering (P3-D65 sau Rec.2020), luminanță maximă 100–10000 nits, MaxCLL, MaxFALL (0 = nesemnalat).")]),
            ("img", "guide-settings.jpg", "Panoul Plugin Settings pentru GDC H.265 (Software x265)."),
        ]),
        ("6. Containere și metadate", [
            ("ul", ["Cele trei containere scriu etichetele de culoare (primare, transfer, matrice, interval) în fișier.", "La exporturi PQ cu HDR10 pornit, fișierul conține și mastering display și MaxCLL/MaxFALL, atât în fluxul video, cât și în container.", "Sunetul se scrie ca PCM necomprimat (16, 24 sau 32 de biți), neschimbat. În MP4, sunetul PCM are suport limitat în unele playere.", "Nu se scriu încă timecode-ul de start și markerele.", "Lățimea și înălțimea trebuie să fie pare (la 4:2:2 contează lățimea); altfel exportul este refuzat cu un mesaj în jurnal."]),
        ]),
        ("7. Rețete de pornire", [
            ("tbl", [("Master 10-bit", "GDC H.265 10-bit (Main10), GDC QuickTime, CRF 16–18, preset slow."), ("Livrare web", "GDC H.264 (Software x264), GDC MP4, CRF 20–23, preset medium."), ("Previzualizare rapidă", "GDC H.265 (Apple VideoToolbox), Quality 65."), ("HDR10 (PQ)", "GDC H.265 10-bit, GDC MP4 sau QuickTime, HDR10 Metadata = On, primare și luminanță conform display-ului de mastering.")]),
            ("p", "Sunt puncte de plecare, nu garanții: verifică rezultatul pe materialul tău."),
        ]),
        ("8. Ce a fost verificat", [
            ("p", "Ediția 1.8.0 a fost verificată în DaVinci Resolve Studio 21.2 pe un Mac cu Apple Silicon, pe material de cameră de cinema, cu 17 exporturi (clipuri întregi și o secvență cu mai multe clipuri, cu sunet):"),
            ("ul", ["imagine: PSNR minim 40,6 dB față de sursă, cadre numărate corect;", "sunet: sincron (decalaj 0), eșantioane identice cu sursa, cu excepția fade-urilor de câteva milisecunde la marginea clipurilor;", "culoare: etichete scrise corect, HDR10 prezent în fișier;", "reimport în Resolve și redare în FFmpeg fără erori."]),
            ("p", "Windows nu face parte din această ediție. Ediția Windows gratuită, fără activare, este v1.7.1 (întreținere); starea ei actuală este pe pagina produsului."),
        ]),
        ("9. Probleme frecvente", [
            ("ul", ["<b>Nu apar formatele GDC:</b> verifică că folosești DaVinci Resolve Studio și că ai repornit Resolve după instalare; verifică existența folderului de instalare de mai sus.", "<b>Lipsește o variantă hardware:</b> Mac-ul nu o poate rula; folosește varianta software.", "<b>Export eșuat:</b> în Resolve, Help → Create Diagnostics Log on Desktop; jurnalul conține motivul și setările de control al ratei folosite.", "<b>Anulare:</b> un export oprit lasă un fișier valid, trunchiat la ultimul cadru scris."]),
        ]),
        ("10. Licență și credite", [
            ("p", "Codul pluginului este sub licență MIT. Pachetul pentru Mac include FFmpeg, x264 și x265 și se distribuie sub GPLv3; textele licențelor și oferta de cod sursă sunt în pachet, în Contents/Resources/Licenses. Codul sursă: " + REPO + "."),
            ("p", "Autor: Dumitru Cristinel Gordas (GDC). Pagina produsului: " + SITE + ". GDC Resolve Encoder este un proiect independent; nu este dezvoltat, aprobat sau susținut de Blackmagic Design. DaVinci Resolve este marca deținătorului său. Contribuțiile (în special pentru Windows) sunt binevenite prin Issues și Pull Requests."),
        ]),
    ],
)

L["en"] = dict(
    file="GDC_Resolve_Encoder_Guide_EN.pdf", lang="en", title="User guide", sub="Free H.264 and H.265 export plugin for DaVinci Resolve Studio on Mac",
    ver=f"Version {VERSION}", toc="Contents", foot="GDC Resolve Encoder · Dumitru Cristinel Gordas (GDC)", page="Page",
    tbl_h=("Setting", "What it does"), var_h=("Type variant", "Encoder", "Depth / chroma"),
    sections=[
        ("1. What it is", [
            ("p", "GDC Resolve Encoder adds complete H.264 and H.265 encoders (x264, x265 and Apple VideoToolbox), three containers of its own (GDC QuickTime, GDC MP4, GDC Matroska) and HDR10 metadata in the file to DaVinci Resolve Studio, right inside the Deliver page."),
            ("p", "Edition 1.8.0 for macOS is <b>free and open source</b>: no account, activation, trial period or donation is required. It works only with DaVinci Resolve Studio; the free Resolve does not load export plugins. The plugin runs locally and sends no data anywhere."),
        ]),
        ("2. Installation", [
            ("p", "Requirements: macOS 26 or later (declared minimum; verified on macOS 27), a Mac with Apple Silicon, DaVinci Resolve Studio."),
            ("ul", ["Download <b>GDCResolveEncoder-1.8.0.pkg</b> from the project page and double-click it.", "Follow the installer (accept the license; it asks for your Mac password).", "Restart DaVinci Resolve. Nothing else needs installing: FFmpeg and the encoding libraries ship inside the package."]),
            ("p", "The package installs to:"),
            ("code", PATH),
            ("p", "To uninstall, quit Resolve and move the folder above to the Trash (Finder asks for your password)."),
        ]),
        ("3. The Deliver flow", [
            ("p", "In the Deliver page, Render Settings, Video tab:"),
            ("ul", ["<b>Format</b>: pick GDC QuickTime, GDC MP4 or GDC Matroska (they appear after the native formats).", "<b>Codec</b>: pick GDC Encoder.", "<b>Type</b>: pick one of the 8 variants (table below).", "<b>Plugin Settings</b>: tune the quality, then add the job to the render queue as usual."]),
            ("img", "guide-format.jpg", "The Format list: GDC QuickTime, GDC MP4 and GDC Matroska."),
            ("img", "guide-codec.jpg", "Codec = GDC Encoder; the Type list with the 8 variants."),
        ]),
        ("4. The Type variants", [
            ("var", [("GDC H.264 (Software x264)", "libx264", "8-bit 4:2:0"), ("GDC H.265 (Software x265)", "libx265", "8-bit 4:2:0"), ("GDC H.264 (Apple VideoToolbox)", "hardware", "8-bit 4:2:0"), ("GDC H.265 (Apple VideoToolbox)", "hardware", "8-bit 4:2:0"), ("GDC H.264 10-bit (x264 High10)", "libx264", "10-bit 4:2:0"), ("GDC H.265 10-bit (x265 Main10)", "libx265", "10-bit 4:2:0"), ("GDC H.264 4:2:2 10-bit (High 4:2:2)", "libx264", "10-bit 4:2:2"), ("GDC H.265 4:2:2 10-bit (Main 4:2:2 10)", "libx265", "10-bit 4:2:2")]),
            ("p", "Hardware variants appear in the list only if your Mac can actually run them. HDR10 Metadata is available on the software variants."),
        ]),
        ("5. The panel settings", [
            ("tbl", [("Preset", "Speed / efficiency trade-off, from ultrafast to veryslow. Slower = smaller file at the same quality."), ("Level", "H.264/H.265 level (3.0 – 5.2) or Auto. Leave Auto unless an old player requires otherwise."), ("Tune", "Content-specific tuning: film, animation, grain, stillimage, psnr, ssim, fastdecode, zerolatency (the list differs slightly between H.264 and H.265)."), ("Rate Control", "Constant Quality (CRF), Target Bitrate or Constant QP. CRF is the usual choice: constant quality, variable size."), ("Quality (CRF)", "0 – 51, lower = better. Starting point: 18 for masters, 20–23 for web delivery."), ("Quality (1–100)", "On VideoToolbox, in quality mode: higher = better. Starting point: 65."), ("Keyframe Interval", "Distance between keyframes, in seconds (default 2)."), ("Advanced Params", "Expert x264/x265 parameters, for example aq-mode=3:psy-rd=1.0,0.15. They take precedence over the settings above."), ("HDR10 Metadata", "Off or On (PQ exports only): mastering primaries (P3-D65 or Rec.2020), peak luminance 100–10000 nits, MaxCLL, MaxFALL (0 = not signalled).")]),
            ("img", "guide-settings.jpg", "The Plugin Settings panel for GDC H.265 (Software x265)."),
        ]),
        ("6. Containers and metadata", [
            ("ul", ["The three containers write the color tags (primaries, transfer, matrix, range) into the file.", "On PQ exports with HDR10 on, the file also carries mastering display and MaxCLL/MaxFALL, both in the video stream and in the container.", "Audio is written as uncompressed PCM (16, 24 or 32 bit), unchanged. In MP4, PCM audio has limited support in some players.", "Start timecode and markers are not written yet.", "Width and height must be even (for 4:2:2 only the width matters); otherwise the export is refused with a message in the log."]),
        ]),
        ("7. Starting recipes", [
            ("tbl", [("10-bit master", "GDC H.265 10-bit (Main10), GDC QuickTime, CRF 16–18, preset slow."), ("Web delivery", "GDC H.264 (Software x264), GDC MP4, CRF 20–23, preset medium."), ("Quick preview", "GDC H.265 (Apple VideoToolbox), Quality 65."), ("HDR10 (PQ)", "GDC H.265 10-bit, GDC MP4 or QuickTime, HDR10 Metadata = On, primaries and luminance matching the mastering display.")]),
            ("p", "These are starting points, not guarantees: check the result on your own material."),
        ]),
        ("8. What was verified", [
            ("p", "Edition 1.8.0 was verified in DaVinci Resolve Studio 21.2 on an Apple Silicon Mac, on cinema camera material, with 17 exports (full clips and a multi-clip sequence, with sound):"),
            ("ul", ["picture: minimum PSNR 40.6 dB against the source, frames counted correctly;", "sound: in sync (offset 0), samples identical to the source except for the few milliseconds of fade at clip edges;", "color: tags written correctly, HDR10 present in the file;", "reimport in Resolve and playback in FFmpeg without errors."]),
            ("p", "Windows is not part of this edition. The free Windows edition, with no activation, is v1.7.1 (maintenance); its current status is on the product page."),
        ]),
        ("9. Common problems", [
            ("ul", ["<b>The GDC formats do not appear:</b> make sure you use DaVinci Resolve Studio and restarted Resolve after installing; check that the install folder above exists.", "<b>A hardware variant is missing:</b> your Mac cannot run it; use the software variant.", "<b>Failed export:</b> in Resolve, Help → Create Diagnostics Log on Desktop; the log holds the reason and the rate-control settings used.", "<b>Cancelling:</b> a stopped export leaves a valid file, truncated at the last written frame."]),
        ]),
        ("10. License and credits", [
            ("p", "The plugin code is MIT-licensed. The Mac package includes FFmpeg, x264 and x265 and is distributed under the GPLv3; the license texts and the source offer are inside the package, in Contents/Resources/Licenses. Source code: " + REPO + "."),
            ("p", "Author: Dumitru Cristinel Gordas (GDC). Product page: " + SITE + ". GDC Resolve Encoder is an independent project; it is not developed, endorsed or supported by Blackmagic Design. DaVinci Resolve is a trademark of its owner. Contributions (especially for Windows) are welcome through Issues and Pull Requests."),
        ]),
    ],
)

L["es"] = dict(
    file="GDC_Resolve_Encoder_Guia_ES.pdf", lang="es", title="Guía de uso", sub="Plugin gratuito de exportación H.264 y H.265 para DaVinci Resolve Studio en Mac",
    ver=f"Versión {VERSION}", toc="Índice", foot="GDC Resolve Encoder · Dumitru Cristinel Gordas (GDC)", page="Página",
    tbl_h=("Ajuste", "Qué hace"), var_h=("Variante de Type", "Encoder", "Profundidad / croma"),
    sections=[
        ("1. Qué es", [
            ("p", "GDC Resolve Encoder añade a DaVinci Resolve Studio, directamente en la página Deliver, encoders H.264 y H.265 completos (x264, x265 y Apple VideoToolbox), tres contenedores propios (GDC QuickTime, GDC MP4, GDC Matroska) y metadatos HDR10 escritos en el archivo."),
            ("p", "La edición 1.8.0 para macOS es <b>gratuita y de código abierto</b>: no pide cuenta, activación, periodo de prueba ni donación. Funciona solo con DaVinci Resolve Studio; la versión gratuita de Resolve no carga plugins de exportación. El plugin se ejecuta en local y no envía datos a ninguna parte."),
        ]),
        ("2. Instalación", [
            ("p", "Requisitos: macOS 26 o posterior (mínimo declarado; verificado en macOS 27), Mac con Apple Silicon, DaVinci Resolve Studio."),
            ("ul", ["Descarga <b>GDCResolveEncoder-1.8.0.pkg</b> desde la página del proyecto y ábrelo con doble clic.", "Sigue el instalador (acepta la licencia; pide la contraseña de tu Mac).", "Reinicia DaVinci Resolve. No hace falta instalar nada más: FFmpeg y las bibliotecas de codificación vienen en el paquete."]),
            ("p", "El paquete se instala en:"),
            ("code", PATH),
            ("p", "Para desinstalar, cierra Resolve y mueve la carpeta anterior a la Papelera (Finder pide la contraseña)."),
        ]),
        ("3. El flujo en Deliver", [
            ("p", "En la página Deliver, Render Settings, pestaña Video:"),
            ("ul", ["<b>Format</b>: elige GDC QuickTime, GDC MP4 o GDC Matroska (aparecen tras los formatos nativos).", "<b>Codec</b>: elige GDC Encoder.", "<b>Type</b>: elige una de las 8 variantes (tabla siguiente).", "<b>Plugin Settings</b>: regula la calidad y añade el trabajo a la cola de render como siempre."]),
            ("img", "guide-format.jpg", "La lista Format: GDC QuickTime, GDC MP4 y GDC Matroska."),
            ("img", "guide-codec.jpg", "Codec = GDC Encoder; la lista Type con las 8 variantes."),
        ]),
        ("4. Las variantes de Type", [
            ("var", [("GDC H.264 (Software x264)", "libx264", "8 bits 4:2:0"), ("GDC H.265 (Software x265)", "libx265", "8 bits 4:2:0"), ("GDC H.264 (Apple VideoToolbox)", "hardware", "8 bits 4:2:0"), ("GDC H.265 (Apple VideoToolbox)", "hardware", "8 bits 4:2:0"), ("GDC H.264 10-bit (x264 High10)", "libx264", "10 bits 4:2:0"), ("GDC H.265 10-bit (x265 Main10)", "libx265", "10 bits 4:2:0"), ("GDC H.264 4:2:2 10-bit (High 4:2:2)", "libx264", "10 bits 4:2:2"), ("GDC H.265 4:2:2 10-bit (Main 4:2:2 10)", "libx265", "10 bits 4:2:2")]),
            ("p", "Las variantes por hardware aparecen en la lista solo si tu Mac puede ejecutarlas. HDR10 Metadata está disponible en las variantes por software."),
        ]),
        ("5. Los ajustes del panel", [
            ("tbl", [("Preset", "Equilibrio velocidad / eficiencia, de ultrafast a veryslow. Más lento = archivo más pequeño con la misma calidad."), ("Level", "Nivel H.264/H.265 (3.0 – 5.2) o Auto. Deja Auto salvo que un reproductor antiguo exija otra cosa."), ("Tune", "Ajustes según el contenido: film, animation, grain, stillimage, psnr, ssim, fastdecode, zerolatency (la lista difiere un poco entre H.264 y H.265)."), ("Rate Control", "Constant Quality (CRF), Target Bitrate o Constant QP. CRF es lo habitual: calidad constante, tamaño variable."), ("Quality (CRF)", "0 – 51, menor = mejor. Punto de partida: 18 para másteres, 20–23 para entrega web."), ("Quality (1–100)", "En VideoToolbox, en modo calidad: mayor = mejor. Punto de partida: 65."), ("Keyframe Interval", "Distancia entre fotogramas clave, en segundos (por defecto 2)."), ("Advanced Params", "Parámetros expertos de x264/x265, por ejemplo aq-mode=3:psy-rd=1.0,0.15. Tienen prioridad sobre los ajustes anteriores."), ("HDR10 Metadata", "Off u On (solo exportaciones PQ): primarios de mastering (P3-D65 o Rec.2020), luminancia máxima 100–10000 nits, MaxCLL, MaxFALL (0 = no señalizado).")]),
            ("img", "guide-settings.jpg", "El panel Plugin Settings para GDC H.265 (Software x265)."),
        ]),
        ("6. Contenedores y metadatos", [
            ("ul", ["Los tres contenedores escriben las etiquetas de color (primarios, transferencia, matriz, rango) en el archivo.", "En exportaciones PQ con HDR10 activado, el archivo incluye además mastering display y MaxCLL/MaxFALL, tanto en el flujo de vídeo como en el contenedor.", "El audio se escribe como PCM sin comprimir (16, 24 o 32 bits), sin cambios. En MP4, el audio PCM tiene soporte limitado en algunos reproductores.", "Todavía no se escriben el timecode de inicio ni los marcadores.", "El ancho y el alto deben ser pares (en 4:2:2 solo importa el ancho); si no, la exportación se rechaza con un mensaje en el registro."]),
        ]),
        ("7. Recetas de partida", [
            ("tbl", [("Máster 10-bit", "GDC H.265 10-bit (Main10), GDC QuickTime, CRF 16–18, preset slow."), ("Entrega web", "GDC H.264 (Software x264), GDC MP4, CRF 20–23, preset medium."), ("Previsualización rápida", "GDC H.265 (Apple VideoToolbox), Quality 65."), ("HDR10 (PQ)", "GDC H.265 10-bit, GDC MP4 o QuickTime, HDR10 Metadata = On, primarios y luminancia según el monitor de mastering.")]),
            ("p", "Son puntos de partida, no garantías: comprueba el resultado con tu propio material."),
        ]),
        ("8. Qué se verificó", [
            ("p", "La edición 1.8.0 se verificó en DaVinci Resolve Studio 21.2 en un Mac con Apple Silicon, con material de cámara de cine, en 17 exportaciones (clips completos y una secuencia de varios clips, con sonido):"),
            ("ul", ["imagen: PSNR mínimo de 40,6 dB frente al original, fotogramas contados correctamente;", "sonido: sincronizado (desfase 0), muestras idénticas al original salvo los pocos milisegundos de fundido en los bordes de los clips;", "color: etiquetas escritas correctamente, HDR10 presente en el archivo;", "reimportación en Resolve y reproducción en FFmpeg sin errores."]),
            ("p", "Windows no forma parte de esta edición. La edición gratuita para Windows, sin activación, es v1.7.1 (mantenimiento); su estado actual está en la página del producto."),
        ]),
        ("9. Problemas frecuentes", [
            ("ul", ["<b>No aparecen los formatos GDC:</b> comprueba que usas DaVinci Resolve Studio y que reiniciaste Resolve tras instalar; comprueba que existe la carpeta de instalación indicada arriba.", "<b>Falta una variante por hardware:</b> tu Mac no puede ejecutarla; usa la variante por software.", "<b>Exportación fallida:</b> en Resolve, Help → Create Diagnostics Log on Desktop; el registro contiene el motivo y los ajustes de control de tasa usados.", "<b>Cancelar:</b> una exportación detenida deja un archivo válido, truncado en el último fotograma escrito."]),
        ]),
        ("10. Licencia y créditos", [
            ("p", "El código del plugin tiene licencia MIT. El paquete para Mac incluye FFmpeg, x264 y x265 y se distribuye bajo GPLv3; los textos de licencia y la oferta de código fuente están en el paquete, en Contents/Resources/Licenses. Código fuente: " + REPO + "."),
            ("p", "Autor: Dumitru Cristinel Gordas (GDC). Página del producto: " + SITE + ". GDC Resolve Encoder es un proyecto independiente; no está desarrollado, aprobado ni respaldado por Blackmagic Design. DaVinci Resolve es una marca de su titular. Se aceptan contribuciones (sobre todo para Windows) mediante Issues y Pull Requests."),
        ]),
    ],
)


class Doc(BaseDocTemplate):
    def __init__(self, fn, cfg):
        super().__init__(fn, pagesize=A4, leftMargin=20 * mm, rightMargin=20 * mm, topMargin=20 * mm, bottomMargin=20 * mm,
                         title="GDC Resolve Encoder — " + cfg["title"], author="Dumitru Cristinel Gordas (GDC)", subject=cfg["sub"])
        self.cfg = cfg
        fr = Frame(self.leftMargin, self.bottomMargin, self.width, self.height, id="f")
        self.addPageTemplates([PageTemplate(id="cover", frames=[fr], onPage=self.cover), PageTemplate(id="body", frames=[fr], onPage=self.footer)])
        self.key = 0

    def cover(self, c, d):
        c.saveState()
        c.setFillColor(INK)
        c.rect(0, 0, A4[0], A4[1], fill=1, stroke=0)
        c.setFillColor(ACCENT)
        c.rect(0, 0, 6 * mm, A4[1], fill=1, stroke=0)
        c.setFillColor(colors.white)
        c.setFont("BodyB", 34)
        c.drawString(25 * mm, A4[1] - 95 * mm, "GDC Resolve Encoder")
        c.setFont("Body", 18)
        c.setFillColor(colors.HexColor("#6fc0c9"))
        c.drawString(25 * mm, A4[1] - 108 * mm, self.cfg["title"])
        c.setFillColor(colors.HexColor("#c4ccce"))
        c.setFont("Body", 11)
        # wrap the subtitle on two lines
        words, line, y = self.cfg["sub"].split(), "", A4[1] - 122 * mm
        for w in words:
            if pdfmetrics.stringWidth(line + " " + w, "Body", 11) > 150 * mm:
                c.drawString(25 * mm, y, line.strip())
                line, y = "", y - 6 * mm
            line += " " + w
        c.drawString(25 * mm, y, line.strip())
        c.setFont("Body", 10)
        c.drawString(25 * mm, 30 * mm, self.cfg["ver"] + "  ·  " + SITE)
        c.drawString(25 * mm, 24 * mm, self.cfg["foot"])
        c.restoreState()

    def footer(self, c, d):
        c.saveState()
        c.setFont("Body", 8)
        c.setFillColor(MUTED)
        c.drawString(20 * mm, 12 * mm, self.cfg["foot"] + "  ·  " + self.cfg["ver"])
        c.drawRightString(A4[0] - 20 * mm, 12 * mm, "%s %d" % (self.cfg["page"], d.page))
        c.restoreState()

    def afterFlowable(self, f):
        if isinstance(f, Paragraph) and f.style.name == "h1":
            k = "s_" + f.getPlainText().split(".")[0].strip()
            self.canv.bookmarkPage(k)
            self.canv.addOutlineEntry(f.getPlainText(), k, 0, 0)
            self.notify("TOCEntry", (0, f.getPlainText(), self.page, k))


def build(cfg, assets, out):
    doc = Doc(out, cfg)
    S = []
    from reportlab.platypus import NextPageTemplate
    S += [NextPageTemplate("body"), PageBreak()]
    S.append(Paragraph(cfg["toc"], ST["h1"].clone("tocH", fontSize=19)))
    toc = TableOfContents()
    toc.levelStyles = [ST["toc1"]]
    S += [toc, PageBreak()]
    imgs = 0
    for head, blocks in cfg["sections"]:
        S.append(Paragraph(head, ST["h1"]))
        for b in blocks:
            k = b[0]
            if k == "p":
                S.append(Paragraph(b[1], ST["p"]))
            elif k == "ul":
                S += [Paragraph(t, ST["li"], bulletText="•") for t in b[1]]
                S.append(Spacer(1, 4))
            elif k == "code":
                S.append(Paragraph(b[1].replace(" ", "&nbsp;") if False else b[1], ST["code"]))
            elif k == "img":
                p = os.path.join(assets, b[1])
                from PIL import Image as PI
                iw, ih = PI.open(p).size
                w = 120 * mm
                S.append(KeepTogether([Image(p, width=w, height=w * ih / iw, hAlign="LEFT"), Paragraph(b[2], ST["cap"])]))
                imgs += 1
            elif k in ("tbl", "var"):
                if k == "tbl":
                    rows = [[Paragraph(cfg["tbl_h"][0], ST["cellb"]), Paragraph(cfg["tbl_h"][1], ST["cellb"])]] + [[Paragraph(a, ST["cellb"]), Paragraph(t, ST["cell"])] for a, t in b[1]]
                    cw = [38 * mm, 132 * mm]
                else:
                    rows = [[Paragraph(h, ST["cellb"]) for h in cfg["var_h"]]] + [[Paragraph(a, ST["cell"]), Paragraph(e, ST["cell"]), Paragraph(d, ST["cell"])] for a, e, d in b[1]]
                    cw = [84 * mm, 32 * mm, 54 * mm]
                t = Table(rows, colWidths=cw, repeatRows=1)
                t.setStyle(TableStyle([("BACKGROUND", (0, 0), (-1, 0), SOFT), ("LINEBELOW", (0, 0), (-1, -1), 0.4, LINE), ("VALIGN", (0, 0), (-1, -1), "TOP"),
                                       ("TOPPADDING", (0, 0), (-1, -1), 4), ("BOTTOMPADDING", (0, 0), (-1, -1), 4)]))
                S += [t, Spacer(1, 8)]
    doc.multiBuild(S)
    return imgs


def main():
    assets, out = sys.argv[1], sys.argv[2]
    os.makedirs(out, exist_ok=True)
    import fitz
    for code, cfg in L.items():
        path = os.path.join(out, cfg["file"])
        imgs = build(cfg, assets, path)
        d = fitz.open(path)
        fonts = set(f[3] for p in d for f in p.get_fonts())
        print("%s: %d pages, %d images, outline=%d, fonts=%s, %.0f KB" % (cfg["file"], len(d), imgs, len(d.get_toc()), sorted(fonts), os.path.getsize(path) / 1024))


if __name__ == "__main__":
    main()
