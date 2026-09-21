import Foundation

// Edición en español, parte 2: recetas de exportación, parámetros avanzados, elección rápida, resolución de problemas, límites, anexos.

func es10a() -> [Block] {
    var b: [Block] = [
        .h1("10. Recetas de exportación"),
        .p("Cada receta enumera los ajustes del panel del plugin y de Resolve. Los valores son **puntos de partida**: prueba con un clip corto de 10–20 segundos, comprueba el resultado en el dispositivo de destino y solo entonces exporta la película. Las plataformas cambian sus recomendaciones periódicamente; consulta sus especificaciones vigentes antes de una entrega importante."),
        .h2("10.1 Cómo se leen las recetas"),
        .bullets([
            "**Format** = la lista Format de Deliver. \"MP4 (Resolve)\" es el formato nativo; \"GDC MP4\" es el formato propio del plugin.",
            "**Codec (Type)** = la variante elegida en el panel del plugin.",
            "**En Resolve** = los ajustes de Deliver y de Color Management que afectan al archivo.",
            "Si una fila falta en una receta, deja el valor por defecto.",
        ]),
        .note(.tip, "Para cualquier destino, exporta primero un fragmento de la parte más difícil de la película (movimiento rápido, degradados, oscuridad). Si ahí se ve bien, el resto se verá bien."),
        .h2("10.2 YouTube"),
        .p("YouTube recomprime todo lo que subes. El objetivo es subir un archivo de **alta calidad**, para que la recompresión parta de una fuente limpia. Los valores de bitrate siguientes son los que YouTube recomendaba públicamente en el momento de redactar el documento, como orden de magnitud."),
    ]
    b += recipeES("YouTube SDR, 1080p (24–30 fps)", [
        ["Format", "MP4 (Resolve) o QuickTime (Resolve), con audio AAC de 320 kbps o PCM"],
        ["Codec (Type)", "GDC H.264 (Software x264)"],
        ["Preset", "slow"],
        ["Profile / Level", "High / Auto (4.2 si la velocidad es de 48–60 fps)"],
        ["Tune", "none"],
        ["Rate Control", "Constant Quality, **CRF 18–20** (o Target Bitrate de 12 Mbps)"],
        ["Keyframe Interval", "1–2 segundos"],
        ["HDR10 Metadata", "Off"],
        ["En Resolve", "Output Color Space Rec.709; Data Levels Video; 1920×1080; la velocidad de fotogramas de la línea de tiempo"],
        ["A tener en cuenta", "La recomendación de YouTube para 1080p SDR es del orden de 8 Mbps a 24–30 fps y de 12 Mbps a 48–60 fps; un CRF de 18–20 supera esos valores, lo cual es bueno para la recompresión."],
    ])
    b += recipeES("YouTube SDR, 4K (24–30 fps)", [
        ["Format", "MP4 (Resolve) con AAC, o GDC QuickTime con PCM"],
        ["Codec (Type)", "GDC H.264 (Software x264) o GDC H.265 (Software x265) para archivos más pequeños"],
        ["Preset", "slow"],
        ["Profile / Level", "H.264: High / **5.1** (5.2 a 60 fps). H.265: Main / **5.0** (5.1 a 60 fps)"],
        ["Tune", "none"],
        ["Rate Control", "H.264: **CRF 18–20** (o 35–45 Mbps). H.265: **CRF 21–23** (o 25–35 Mbps)"],
        ["Keyframe Interval", "1–2 segundos"],
        ["HDR10 Metadata", "Off"],
        ["En Resolve", "Output Color Space Rec.709; Data Levels Video; 3840×2160"],
        ["A tener en cuenta", "H.265 en 4K reduce el archivo en aproximadamente un tercio frente a H.264 con una calidad comparable, pero la exportación tarda más."],
    ])
    b += recipeES("YouTube HDR10 (PQ), 4K", [
        ["Format", "**GDC MP4**, **GDC QuickTime** o **GDC Matroska** (los metadatos HDR10 llegan al contenedor)"],
        ["Codec (Type)", "GDC H.265 10-bit (Software x265 Main10)"],
        ["Preset", "slow"],
        ["Profile / Level", "Main 10 (automático) / **5.0** (4K 30 fps) o **5.1** (4K 60 fps)"],
        ["Tune", "none"],
        ["Rate Control", "**CRF 16–18** (o Target Bitrate de 44–56 Mbps en 4K a 24–30 fps, 66–85 Mbps a 48–60 fps)"],
        ["Keyframe Interval", "1–2 segundos"],
        ["HDR10 Metadata", "**On**; Mastering Primaries P3-D65; Mastering Peak = la luminancia de tu monitor (1000 es lo habitual); MaxCLL/MaxFALL medidos, o 0"],
        ["En Resolve", "Output Color Space **Rec.2100 ST2084**; Data Levels Video; 3840×2160"],
        ["Audio", "PCM de 24 bits a 48 kHz en los formatos GDC (comprueba al subir que la plataforma lo acepta)"],
        ["A tener en cuenta", "YouTube identifica el HDR a partir del archivo. Los formatos GDC ponen los metadatos también en el contenedor, que es la opción más segura. Tras subirlo, comprueba que la plataforma marca el vídeo como HDR."],
    ])
    b += recipeES("YouTube HLG, 4K", [
        ["Format", "GDC MP4 o GDC QuickTime"],
        ["Codec (Type)", "GDC H.265 10-bit (Software x265 Main10)"],
        ["Preset / Level", "slow / 5.0 (4K 30 fps) o 5.1 (4K 60 fps)"],
        ["Rate Control", "**CRF 16–18**"],
        ["Keyframe Interval", "1–2 segundos"],
        ["HDR10 Metadata", "**Off** (HLG no usa metadatos estáticos)"],
        ["En Resolve", "Output Color Space **Rec.2100 HLG**; Data Levels Video"],
        ["A tener en cuenta", "Comprueba en una pantalla SDR y en una HDR: HLG se ve aceptablemente en ambas."],
    ])
    return b
}

func es10b() -> [Block] {
    var b: [Block] = [
        .h2("10.3 Facebook, Instagram, TikTok y otras redes"),
        .p("Las redes sociales **recomprimen con fuerza**. No tiene sentido subir un archivo enorme: un archivo de buena calidad, en el formato de imagen correcto y con un bitrate moderado, es el que mejor se comporta. Usa **H.264 SDR de 8 bits**, la opción más segura. Los límites de tamaño, duración y resolución cambian con frecuencia; compruébalos antes de subir."),
        .table(headers: ["Formato de imagen", "Resolución", "Dónde se usa"], rows: [
            ["Vertical 9:16", "1080×1920", "Instagram Reels e Historias, TikTok, Facebook Reels, YouTube Shorts"],
            ["Retrato 4:5", "1080×1350", "Feed de Instagram y Facebook (ocupa más pantalla)"],
            ["Cuadrado 1:1", "1080×1080", "Feed, casos especiales"],
            ["Horizontal 16:9", "1920×1080", "Facebook, YouTube, LinkedIn, X"],
        ], widths: [0.24, 0.20, 0.56]),
    ]
    b += recipeES("Instagram Reels / Historias (vertical)", [
        ["Format", "MP4 (Resolve), audio AAC de 128–256 kbps, 48 kHz"],
        ["Codec (Type)", "GDC H.264 (Software x264)"],
        ["Preset", "slow (o medium para ganar velocidad)"],
        ["Profile / Level", "High / 4.1 (Auto es suficiente)"],
        ["Tune", "none"],
        ["Rate Control", "**CRF 20**; límite opcional en Advanced Params: `vbv-maxrate=12000:vbv-bufsize=24000`"],
        ["Keyframe Interval", "2 segundos"],
        ["HDR10 Metadata", "Off"],
        ["En Resolve", "Output Color Space Rec.709; Data Levels Video; 1080×1920; 30 fps (o la velocidad nativa)"],
        ["A tener en cuenta", "Mantén el texto y los elementos importantes en la zona central; la interfaz de la aplicación tapa los bordes superior e inferior."],
    ])
    b += recipeES("Feed de Instagram / Feed de Facebook (4:5 o 1:1)", [
        ["Format", "MP4 (Resolve), audio AAC de 128–192 kbps"],
        ["Codec (Type)", "GDC H.264 (Software x264)"],
        ["Preset / Profile / Level", "slow / High / Auto"],
        ["Rate Control", "**CRF 20–22** (o Target Bitrate de 8–10 Mbps en 1080p)"],
        ["Keyframe Interval", "2 segundos"],
        ["En Resolve", "Rec.709; Data Levels Video; 1080×1350 (4:5) o 1080×1080 (1:1)"],
    ])
    b += recipeES("Facebook (vídeo horizontal)", [
        ["Format", "MP4 (Resolve), audio AAC estéreo de 128–256 kbps"],
        ["Codec (Type)", "GDC H.264 (Software x264)"],
        ["Preset / Profile / Level", "slow / High / Auto"],
        ["Rate Control", "**CRF 20–22** (o Target Bitrate de 8–12 Mbps en 1080p)"],
        ["Keyframe Interval", "2 segundos"],
        ["En Resolve", "Rec.709; Data Levels Video; 1920×1080; se recomiendan velocidades de hasta 30 fps"],
    ])
    b += recipeES("TikTok", [
        ["Format", "MP4 (Resolve), audio AAC de 128–192 kbps"],
        ["Codec (Type)", "GDC H.264 (Software x264)"],
        ["Preset / Profile / Level", "slow / High / 4.1"],
        ["Rate Control", "**CRF 20**; alternativamente Target Bitrate de 8–12 Mbps"],
        ["Keyframe Interval", "2 segundos"],
        ["En Resolve", "Rec.709; Data Levels Video; 1080×1920; 30 fps"],
        ["A tener en cuenta", "El soporte de HDR al subir difiere de una versión de la aplicación a otra: si quieres HDR, prueba con un clip corto antes de entregar."],
    ])
    b += recipeES("Vimeo", [
        ["Format", "MP4 o QuickTime (Resolve)"],
        ["Codec (Type)", "GDC H.264 (Software x264)"],
        ["Preset / Profile / Level", "slow / High / Auto"],
        ["Rate Control", "**CRF 17–19** (o Target Bitrate de 10–20 Mbps en 1080p)"],
        ["Keyframe Interval", "2 segundos"],
        ["En Resolve", "Rec.709; Data Levels Video; la resolución del proyecto"],
    ])
    b += recipeES("Envío rápido (WhatsApp, Telegram, correo electrónico)", [
        ["Format", "MP4 (Resolve), audio AAC de 128 kbps"],
        ["Codec (Type)", "GDC H.264 (Software x264)"],
        ["Preset", "fast"],
        ["Rate Control", "**CRF 24–26**"],
        ["Keyframe Interval", "2–4 segundos"],
        ["En Resolve", "Rec.709; Data Levels Video; 1280×720 o 1920×1080"],
        ["A tener en cuenta", "Las aplicaciones de mensajería recomprimen y limitan el tamaño; un archivo pequeño llega antes y pierde menos al recomprimirse."],
    ])
    return b
}

func es10c() -> [Block] {
    var b: [Block] = [
        .h2("10.4 Televisor: reproducción desde USB, streamer o Apple TV"),
        .p("En la reproducción en televisor importa el **decodificador por hardware del aparato**, no la calidad del encoder. Los televisores reproducen casi universalmente H.264 de 8 bits 4:2:0 y, en modelos recientes, H.265 Main/Main10 4:2:0. En general **no** reproducen H.264 de 10 bits ni 4:2:2. La regla segura: para televisor, quédate en 4:2:0."),
    ]
    b += recipeES("Televisor SDR, 1080p (USB / DLNA)", [
        ["Format", "MP4 (Resolve) con AAC o AC-3 (compatible con la mayoría de los televisores)"],
        ["Codec (Type)", "GDC H.264 (Software x264), 8 bits"],
        ["Preset / Profile / Level", "slow / High / **4.1** (4.2 a 50/60 fps)"],
        ["Tune", "none"],
        ["Rate Control", "**CRF 17–19** (o Target Bitrate de 15–25 Mbps)"],
        ["Keyframe Interval", "2 segundos"],
        ["En Resolve", "Rec.709; Data Levels Video; 1920×1080"],
        ["A tener en cuenta", "No uses 10 bits ni 4:2:2 para televisor. Si el televisor no reproduce el audio, cambia a AAC estéreo."],
    ])
    b += recipeES("Televisor SDR, 4K", [
        ["Format", "MP4 (Resolve) con AAC"],
        ["Codec (Type)", "GDC H.265 (Software x265), 8 bits (o GDC H.264 si el televisor no reproduce H.265)"],
        ["Preset / Level", "slow / **5.0** (30 fps) o **5.1** (60 fps)"],
        ["Rate Control", "**CRF 20–22** (o Target Bitrate de 30–50 Mbps)"],
        ["Keyframe Interval", "2 segundos"],
        ["En Resolve", "Rec.709; Data Levels Video; 3840×2160"],
    ])
    b += recipeES("Televisor HDR10, 4K (USB / streamer)", [
        ["Format", "**GDC Matroska** o **GDC MP4** (HDR10 en el contenedor, reproducción amplia); GDC QuickTime para el ecosistema Apple"],
        ["Codec (Type)", "GDC H.265 10-bit (Software x265 Main10), 4:2:0"],
        ["Preset / Level", "slow / **5.1**"],
        ["Tune", "none"],
        ["Rate Control", "**CRF 16–18** (o Target Bitrate de 45–80 Mbps)"],
        ["Keyframe Interval", "2 segundos"],
        ["HDR10 Metadata", "**On**; P3-D65; Peak = tu monitor; MaxCLL/MaxFALL medidos o 0"],
        ["En Resolve", "Output Color Space Rec.2100 ST2084; Data Levels Video"],
        ["Audio", "PCM en los formatos GDC; si el televisor no reproduce PCM, prueba GDC Matroska o usa un formato de Resolve con AAC/AC-3 (los metadatos permanecen en el flujo, pero no en el contenedor)"],
        ["A tener en cuenta", "No uses 4:2:2 para televisor. Comprueba en el aparato real que se activa el modo HDR10."],
    ])
    b += recipeES("Televisor HLG", [
        ["Format", "GDC MP4 o GDC Matroska"],
        ["Codec (Type)", "GDC H.265 10-bit (Software x265 Main10)"],
        ["Preset / Level", "slow / 5.1"],
        ["Rate Control", "**CRF 16–18**"],
        ["HDR10 Metadata", "**Off**"],
        ["En Resolve", "Output Color Space Rec.2100 HLG; Data Levels Video"],
    ])
    b += recipeES("Apple TV, iPhone, iPad (reproducción local)", [
        ["Format", "**GDC QuickTime** o **GDC MP4** (etiqueta hvc1, que exige el ecosistema Apple)"],
        ["Codec (Type)", "GDC H.265 10-bit (Software x265 Main10) para HDR; GDC H.265 (x265) de 8 bits para SDR"],
        ["Preset / Level", "slow / 5.1 (4K) o 4.1 (1080p)"],
        ["Rate Control", "**CRF 18–20**"],
        ["HDR10 Metadata", "On para HDR10; Off para SDR/HLG"],
        ["A tener en cuenta", "Evita el 4:2:2 para la reproducción en dispositivos de consumo."],
    ])
    b += [
        .h2("10.5 Televisión (entrega a una cadena)"),
        .p("Las entregas a cadenas de televisión se rigen por el **pliego técnico** de cada cadena. Los requisitos más habituales son XDCAM HD422 (MXF), ProRes 422 HQ, DNxHD/DNxHR o AVC-Intra: códecs nativos de Resolve, no de este plugin. **Sigue siempre el pliego técnico de la cadena.**"),
        .p("El plugin es adecuado cuando la cadena o la plataforma pide explícitamente **H.264 o H.265**, por ejemplo para entregas OTT, copias de archivo de visionado o especificaciones del tipo \"H.264 High 4:2:2 10-bit\". El nivel de sonoridad (por ejemplo EBU R128 o ATSC A/85) se ajusta en Fairlight; el plugin no lo modifica."),
    ]
    b += recipeES("Entrega H.264 4:2:2 10-bit para posproducción / OTT", [
        ["Format", "**GDC QuickTime** (o GDC Matroska)"],
        ["Codec (Type)", "GDC H.264 4:2:2 10-bit (Software x264 High 4:2:2)"],
        ["Preset", "slow"],
        ["Profile / Level", "High 4:2:2 (automático) / 4.1 (1080p 25–30) o 4.2 (1080p 50–60)"],
        ["Tune", "none"],
        ["Rate Control", "**CRF 12–16** (o Target Bitrate de 50–100 Mbps)"],
        ["Keyframe Interval", "1 segundo"],
        ["HDR10 Metadata", "Off (SDR Rec.709)"],
        ["En Resolve", "Output Color Space Rec.709; Data Levels Video; la resolución y la velocidad de fotogramas que exija la especificación"],
        ["Audio", "PCM de 24 bits a 48 kHz"],
        ["A tener en cuenta", "Comprueba en el pliego técnico el perfil exacto (muchas especificaciones de broadcast exigen un perfil intra-only o parámetros fijos, que el CRF no garantiza)."],
    ])
    b += [
        .h2("10.6 Cine, festivales, proyección"),
        .p("Para la proyección en sala se usan **DCP** (JPEG 2000, espacio XYZ) y másteres **ProRes 4444 XQ**, **DPX** o **EXR**, todos nativos en Resolve. El plugin **no** es la herramienta para el máster de cine. Lo usas para archivos de visionado y entrega en línea."),
    ]
    b += recipeES("Screener para festival / envío en línea (1080p)", [
        ["Format", "MP4 (Resolve) con AAC o QuickTime (Resolve)"],
        ["Codec (Type)", "GDC H.264 (Software x264), 8 bits"],
        ["Preset / Profile / Level", "slow / High / 4.1"],
        ["Rate Control", "**CRF 16–18** (o Target Bitrate de 15–25 Mbps)"],
        ["Keyframe Interval", "2 segundos"],
        ["En Resolve", "Rec.709; Data Levels Video; 1920×1080; 24 fps (la velocidad de la película)"],
        ["A tener en cuenta", "Muchos festivales piden H.264 1080p; lee el reglamento antes de exportar."],
    ])
    b += recipeES("Revisión HDR para el cliente o el colorista (con HDR10 en el archivo)", [
        ["Format", "**GDC QuickTime** o **GDC MP4**"],
        ["Codec (Type)", "GDC H.265 10-bit (Software x265 Main10)"],
        ["Preset / Level", "medium / 5.1"],
        ["Rate Control", "**CRF 18–20**"],
        ["HDR10 Metadata", "On; el monitor de masterización real; MaxCLL/MaxFALL medidos o 0"],
        ["En Resolve", "Rec.2100 ST2084; Data Levels Video"],
    ])
    return b
}

func es10d() -> [Block] {
    var b: [Block] = [
        .h2("10.7 Máster ligero / archivo de calidad"),
        .p("Un máster H.264/H.265 de 10 bits es **con pérdidas** incluso con un CRF muy bajo. Para un máster sin pérdidas usa los códecs lossless o intermedios de Resolve (ProRes, DNxHR, FFV1). Las recetas siguientes son para másteres **ligeros**, útiles cuando el espacio importa."),
    ]
    b += recipeES("Máster ligero 4:2:2 10-bit (SDR)", [
        ["Format", "GDC QuickTime"],
        ["Codec (Type)", "GDC H.264 4:2:2 10-bit (x264) o GDC H.265 4:2:2 10-bit (x265)"],
        ["Preset", "slower"],
        ["Rate Control", "H.264: **CRF 10–14**. H.265: **CRF 12–16**"],
        ["Keyframe Interval", "1 segundo"],
        ["Tune", "none (grain si el material tiene grano)"],
        ["En Resolve", "Rec.709; Data Levels Video; resolución nativa"],
        ["Audio", "PCM de 24 bits a 48 kHz"],
    ])
    b += recipeES("Máster ligero HDR10 4:2:2 10-bit", [
        ["Format", "GDC QuickTime o GDC Matroska"],
        ["Codec (Type)", "GDC H.265 4:2:2 10-bit (Software x265 Main 4:2:2 10)"],
        ["Preset", "slower"],
        ["Rate Control", "**CRF 12–16**"],
        ["Keyframe Interval", "1 segundo"],
        ["HDR10 Metadata", "On; el monitor real; MaxCLL/MaxFALL medidos"],
        ["En Resolve", "Rec.2100 ST2084; Data Levels Video"],
        ["A tener en cuenta", "El 4:2:2 no se reproduce en televisores comunes; es para posproducción."],
    ])
    b += [ .h2("10.8 Revisión y dailies") ]
    b += recipeES("Copia de revisión / dailies", [
        ["Format", "MP4 (Resolve), audio AAC de 128 kbps"],
        ["Codec (Type)", "GDC H.264 (Software x264)"],
        ["Preset", "veryfast"],
        ["Rate Control", "**CRF 23–26**"],
        ["Tune", "fastdecode (desplazamiento fluido en ordenadores modestos)"],
        ["Keyframe Interval", "1 segundo (desplazamiento rápido)"],
        ["En Resolve", "Rec.709; 1280×720 o 1920×1080; timecode incluido mediante Data burn-in si hace falta"],
    ])
    b += [ .h2("10.9 El archivo más pequeño posible") ]
    b += recipeES("Tamaño mínimo con calidad aceptable (SDR)", [
        ["Format", "MP4 (Resolve)"],
        ["Codec (Type)", "GDC H.265 (Software x265) de 8 bits"],
        ["Preset", "slow"],
        ["Rate Control", "**CRF 27–30**"],
        ["Keyframe Interval", "4–5 segundos"],
        ["Tune", "none"],
        ["A tener en cuenta", "H.265 ahorra alrededor de un tercio frente a H.264, pero no todos los dispositivos lo reproducen."],
    ])
    b += [ .h2("10.10 Tipos especiales de contenido") ]
    b += recipeES("Animación, gráficos, grabación de pantalla", [
        ["Codec (Type)", "GDC H.264 (x264); para texto de color fino: GDC H.264 4:2:2 10-bit"],
        ["Tune", "**animation**"],
        ["Preset", "slow"],
        ["Rate Control", "**CRF 16–18**"],
        ["Keyframe Interval", "2 segundos"],
        ["A tener en cuenta", "El texto de color sobre fondo de color se ve más limpio en 4:2:2; pero el resultado solo se ve bien en reproductores que decodifican 4:2:2."],
    ])
    b += recipeES("Material con grano de película", [
        ["Codec (Type)", "GDC H.264 (x264) o GDC H.265 10-bit"],
        ["Tune", "**grain**"],
        ["Preset", "slow"],
        ["Rate Control", "x264: **CRF 18–20**; x265: **CRF 20–22**"],
        ["A tener en cuenta", "El grano consume muchos bits; el archivo sale grande. Puedes reducir el grano en Resolve antes de exportar si el tamaño importa."],
    ])
    b += recipeES("Degradados finos y escenas oscuras (evitar el banding)", [
        ["Codec (Type)", "Una variante de **10 bits** (H.265 Main10 o H.264 High10), incluso para SDR"],
        ["Preset", "slow"],
        ["Rate Control", "CRF 16–18 (x265) o 15–17 (x264)"],
        ["Advanced Params", "`aq-mode=3` (favorece las zonas oscuras)"],
        ["A tener en cuenta", "Los 10 bits reducen el banding de forma visible aunque la pantalla de reproducción sea de 8 bits; pero comprueba la compatibilidad de reproducción."],
    ])
    b += [ .h2("10.11 Previsualización rápida con hardware") ]
    b += recipeES("VideoToolbox (Mac) o NVENC (Windows)", [
        ["Codec (Type)", "GDC H.264 (Apple VideoToolbox) / GDC H.265 (Apple VideoToolbox); en Windows, las variantes NVENC"],
        ["Rate Control", "**Target Bitrate** de 8–20 Mbps en 1080p; 25–50 Mbps en 4K"],
        ["Keyframe Interval", "2 segundos"],
        ["A tener en cuenta", "Preset, Level, Tune y los parámetros avanzados no se aplican al hardware. La calidad es más débil con el mismo bitrate que x264/x265: usa el hardware para la revisión, no para la entrega final."],
    ])
    b += [
        .h2("10.12 Velocidad de fotogramas y material entrelazado"),
        .bullets([
            "Conserva la **velocidad de fotogramas de la línea de tiempo**; no la cambies al exportar. Las conversiones de velocidad se hacen en los ajustes del proyecto.",
            "Para la web se recomiendan velocidades progresivas (24, 25, 30, 50, 60 fps). El material entrelazado se convierte en Resolve antes de exportar cuando el destino es la web.",
            "La resolución debe tener el ancho par (y, para 4:2:0, también el alto par).",
        ]),
    ]
    return b
}

func es11() -> [Block] { [
    .h1("11. Parámetros avanzados (x264 y x265)"),
    .p("El campo **Advanced Params** recibe opciones con la forma `clave=valor`, separadas por `:`. El plugin las envía directamente a x264 o x265, según el códec. Están pensadas para usuarios que saben lo que cambian. Prueba siempre con un clip corto."),
    .note(.warn, "Las opciones escritas aquí tienen prioridad sobre las del panel, incluidas `master-display` y `max-cll`. No dupliques aquí los ajustes HDR10 del panel. Un parámetro no válido impide que se inicie la exportación."),
    .h2("11.1 x264 (H.264)"),
    .table(headers: ["Parámetro", "Qué hace", "Ejemplo", "Cuándo"], rows: [
        ["aq-mode", "Asigna bits según la complejidad; 3 favorece las zonas oscuras", "`aq-mode=3`", "Escenas oscuras, degradados"],
        ["aq-strength", "La intensidad de la adaptación", "`aq-strength=0.9`", "Ajuste fino con aq-mode"],
        ["psy-rd", "Conserva el aspecto del detalle (rd, trellis)", "`psy-rd=1.0,0.15`", "Menos artefactos / detalle más natural"],
        ["ref", "Fotogramas de referencia", "`ref=4`", "Mejor calidad; atención al level"],
        ["deblock", "Filtro antibloques (alpha,beta)", "`deblock=-1,-1`", "Imagen algo más nítida"],
        ["rc-lookahead", "Fotogramas analizados por adelantado", "`rc-lookahead=40`", "Mejor reparto de bits"],
        ["vbv-maxrate + vbv-bufsize", "Tope de bitrate (kbps)", "`vbv-maxrate=15000:vbv-bufsize=30000`", "Plataformas con límite de bitrate; CBR aproximado"],
    ], widths: [0.20, 0.34, 0.26, 0.20]),
    .h2("11.2 x265 (H.265)"),
    .table(headers: ["Parámetro", "Qué hace", "Ejemplo", "Cuándo"], rows: [
        ["aq-mode", "Igual que en x264; 3 favorece las zonas oscuras", "`aq-mode=3`", "HDR, escenas oscuras"],
        ["psy-rd / psy-rdoq", "Conserva el detalle y la textura", "`psy-rd=2.0:psy-rdoq=1.0`", "Contenido con textura fina"],
        ["rc-lookahead", "Fotogramas analizados por adelantado", "`rc-lookahead=40`", "Mejor reparto de bits"],
        ["bframes", "Número de fotogramas B", "`bframes=4`", "Mejor eficiencia; más lento"],
        ["no-sao", "Desactiva el filtro SAO (menos brillante)", "`no-sao=1`", "Imagen más nítida, con riesgo de artefactos"],
        ["hdr10-opt", "Ajusta la cuantización para HDR10", "`hdr10-opt=1`", "Exportaciones HDR10 de 10 bits"],
        ["vbv-maxrate + vbv-bufsize", "Tope de bitrate (kbps)", "`vbv-maxrate=50000:vbv-bufsize=100000`", "Plataformas con límite de bitrate"],
    ], widths: [0.20, 0.34, 0.26, 0.20]),
    .h2("11.3 Ejemplos listos para copiar"),
    .p("**CRF con tope de bitrate para redes sociales** (H.264):"),
    .code("vbv-maxrate=12000:vbv-bufsize=24000"),
    .p("**Escenas oscuras y degradados, H.264:**"),
    .code("aq-mode=3:aq-strength=0.9:rc-lookahead=40"),
    .p("**HDR10 de 10 bits, H.265, con optimización de cuantización:**"),
    .code("hdr10-opt=1:aq-mode=3:psy-rd=2.0:psy-rdoq=1.0"),
    .p("**Tope para YouTube HDR 4K 30 fps, H.265:**"),
    .code("vbv-maxrate=60000:vbv-bufsize=120000"),
    .note(.info, "El número de fotogramas B lo fija el plugin en 2; si lo cambias aquí, comprueba el resultado y la compatibilidad."),
] }

func es12() -> [Block] { [
    .h1("12. Elección rápida de ajustes"),
    .table(headers: ["Destino", "Codec (Type)", "Format", "Ajustes clave"], rows: [
        ["YouTube SDR 1080p", "GDC H.264 (x264)", "MP4 (Resolve)", "slow, High, CRF 18–20, Rec.709"],
        ["YouTube SDR 4K", "GDC H.264 o H.265 (x264/x265)", "MP4 (Resolve)", "slow, CRF 18–20 (x264) / 21–23 (x265), Level 5.0–5.2"],
        ["YouTube HDR10", "GDC H.265 10-bit (x265 Main10)", "GDC MP4 / QuickTime", "slow, CRF 16–18, HDR10 On, Rec.2100 ST2084"],
        ["YouTube HLG", "GDC H.265 10-bit", "GDC MP4 / QuickTime", "slow, CRF 16–18, HDR10 Off, Rec.2100 HLG"],
        ["Instagram / TikTok / Facebook", "GDC H.264 (x264)", "MP4 (Resolve)", "slow, High, CRF 20–22, 9:16 o 4:5, Rec.709"],
        ["Vimeo", "GDC H.264 (x264)", "MP4 (Resolve)", "slow, CRF 17–19"],
        ["Televisor SDR 1080p", "GDC H.264 (x264)", "MP4 (Resolve)", "slow, High, Level 4.1, CRF 17–19, AAC"],
        ["Televisor HDR10 4K", "GDC H.265 10-bit", "GDC Matroska / MP4", "slow, Level 5.1, CRF 16–18, HDR10 On"],
        ["Apple TV / iPhone", "GDC H.265 10-bit", "GDC QuickTime / MP4", "hvc1, CRF 18–20, HDR10 On (para HDR)"],
        ["Televisión (cadena con H.264)", "GDC H.264 4:2:2 10-bit", "GDC QuickTime", "slow, CRF 12–16, Keyframe 1 s, PCM de 24 bits"],
        ["Festival / screener", "GDC H.264 (x264)", "MP4 (Resolve)", "slow, High, Level 4.1, CRF 16–18"],
        ["Máster ligero", "GDC 4:2:2 10-bit (x264 o x265)", "GDC QuickTime", "slower, CRF 10–16, Keyframe 1 s"],
        ["Revisión / dailies", "GDC H.264 (x264)", "MP4 (Resolve)", "veryfast, CRF 23–26, tune fastdecode"],
        ["Archivo pequeño", "GDC H.265 (x265) de 8 bits", "MP4 (Resolve)", "slow, CRF 27–30, Keyframe 4–5 s"],
        ["Previsualización rápida", "VideoToolbox / NVENC", "MP4 (Resolve)", "Target Bitrate de 8–20 Mbps"],
    ], widths: [0.22, 0.26, 0.21, 0.31]),
] }

func es13() -> [Block] { [
    .h1("13. Resolución de problemas"),
    .table(headers: ["Problema", "Causas probables", "Solución"], rows: [
        ["No veo los códecs o formatos GDC en Deliver", "Plugin no instalado; Resolve no reiniciado; tienes la versión Free, no Studio; sistema no admitido", "Reinstala el paquete; cierra Resolve, espera al menos 20 segundos y vuelve a abrirlo; comprueba que es la versión Studio"],
        ["La exportación no se inicia", "Licencia sin activar; Advanced Params no válido; ancho o alto impares", "Introduce el código de activación; vacía Advanced Params; usa dimensiones pares"],
        ["La imagen parece deslavada o demasiado contrastada", "Data Levels en Full para un archivo SDR; Output Color Space incorrecto", "Data Levels: Video; comprueba Output Color Space"],
        ["El HDR se ve deslavado en una pantalla SDR", "Comportamiento normal: la pantalla no hace tone mapping", "Comprueba en una pantalla HDR real; para SDR entrega una versión aparte"],
        ["Banding en el cielo o en los degradados", "Cuantización de 8 bits; CRF demasiado alto", "Usa la variante de 10 bits; baja el CRF; añade `aq-mode=3`; añade algo de grano en Resolve"],
        ["Archivo demasiado grande", "CRF demasiado bajo; contenido con grano; fotogramas clave demasiado frecuentes", "Sube el CRF; preset slower; usa x265; keyframe de 2–4 s"],
        ["Archivo demasiado pequeño o con pérdidas visibles", "CRF demasiado alto; preset demasiado rápido", "Baja el CRF; preset slow; revisa Target Bitrate"],
        ["El televisor o el teléfono no reproduce el archivo", "H.264 de 10 bits o 4:2:2; level demasiado alto; audio PCM", "Usa 8 bits 4:2:0 (o H.265 Main10 4:2:0); Level 4.1; audio AAC mediante el formato de Resolve"],
        ["La plataforma no reconoce el HDR", "Formato de Resolve (sin metadatos en el contenedor); Output Color Space no es PQ; HDR10 Metadata en Off", "Usa GDC MP4/QuickTime/Matroska; Rec.2100 ST2084; HDR10 Metadata: On"],
        ["Sin audio al reproducir un MP4", "Audio PCM en MP4 (ipcm), poco soporte", "Usa GDC Matroska o GDC QuickTime; o el MP4 de Resolve con AAC"],
        ["La exportación es muy lenta", "Preset lento; x265; resolución alta", "Preset más rápido; hardware para previsualizaciones; reduce la resolución"],
        ["Las variantes NVENC no aparecen en Mac", "NVENC solo existe con GPU NVIDIA en Windows", "Es normal; usa VideoToolbox en Mac"],
        ["Mensaje \"Cannot add video track to clip\"", "Has elegido un formato GDC con un códec que no es GDC H.264/H.265", "Elige un códec GDC en el formato GDC o usa un formato de Resolve"],
    ], widths: [0.26, 0.34, 0.40]),
    .h2("13.1 Comprobación de un archivo exportado"),
    .p("Con una herramienta gratuita como **MediaInfo** o **ffprobe** puedes comprobar qué contiene el archivo: códec, perfil, profundidad de bits, etiquetas de color (primarios, transferencia, matriz), metadatos HDR (Mastering display, Content light level) y el audio. En una exportación HDR10 correcta deberías ver la transferencia SMPTE ST 2084, los primarios BT.2020 y, en los formatos GDC, también los metadatos de mastering y de nivel de luz."),
    .code("ffprobe -v error -show_entries stream=codec_name,profile,pix_fmt,color_primaries,color_transfer,color_space:stream_side_data archivo.mp4"),
] }

func es14() -> [Block] { [
    .h1("14. Límites conocidos y qué se ha verificado"),
    .p("Esta es la imagen sincera del estado del plugin en la versión 1.7.0. \"Verificado\" significa probado mediante una exportación real en DaVinci Resolve Studio 21.1 sobre macOS Apple Silicon, comprobando el archivo resultante."),
    .table(headers: ["Función", "Estado"], rows: [
        ["x264 y x265, 8 bits 4:2:0", "Verificado"],
        ["Apple VideoToolbox H.264 y H.265", "Verificado"],
        ["NVIDIA NVENC", "Verificado en versiones anteriores en Windows con GPU NVIDIA; no reverificado en la 1.7.0"],
        ["x264 High10 y x265 Main10 (10 bits 4:2:0)", "Verificado"],
        ["x264 y x265 4:2:2 de 10 bits", "Verificado (incluido el orden de los planos de color)"],
        ["Etiquetas PQ, HLG, P3-D65, P3-DCI, Rec.709", "Verificado"],
        ["HDR10 en el flujo (x264 y x265; 4:2:0 y 4:2:2)", "Verificado en las cuatro combinaciones"],
        ["Mastering Primaries: P3-D65", "Verificado"],
        ["Mastering Primaries: Rec.2020", "**Sin probar** en Resolve"],
        ["GDC QuickTime, GDC MP4, GDC Matroska (x265 4:2:2 10-bit, PQ, HDR10)", "Verificado, con HDR en el contenedor y audio PCM"],
        ["Códec H.264 en los formatos GDC", "**Sin probar**"],
        ["\"Export Audio\" desmarcado en los formatos GDC", "**Sin probar**"],
        ["Windows: carga del plugin", "Verificado automáticamente en la publicación"],
        ["Windows: exportación en Resolve, incluidos los formatos GDC", "**Sin probar**"],
        ["Timecode inicial y marcadores en los formatos GDC", "No implementado"],
        ["AAC en los formatos GDC", "No implementado"],
        ["Mac Intel, Linux", "No admitidos"],
    ], widths: [0.62, 0.38]),
    .note(.info, "Lo marcado como \"Sin probar\" no significa que no funcione, sino que no se ha verificado mediante una exportación real. Si lo usas, prueba primero con un clip corto."),
] }

func esAnnex() -> [Block] { [
    .h1("Anexo A. Lista de comprobación antes de exportar"),
    .numbered([
        "La línea de tiempo está terminada; la velocidad de fotogramas y la resolución son las previstas (ancho y alto pares).",
        "Output Color Space se corresponde con el destino (Rec.709, Rec.2100 ST2084 o Rec.2100 HLG).",
        "Has elegido el formato (de Resolve o GDC) adecuado para el audio y los metadatos que necesitas.",
        "Has elegido la variante de códec adecuada: 8 bits 4:2:0 para compatibilidad, 10 bits para HDR, 4:2:2 solo para posproducción.",
        "Preset: slow para la entrega; Level: Auto; Tune: none, salvo que tengas un motivo concreto.",
        "Rate Control: CRF (o Target Bitrate si la plataforma impone un bitrate).",
        "Data Levels: Video.",
        "Para HDR10: HDR10 Metadata On, el monitor de masterización real, MaxCLL/MaxFALL medidos o 0.",
        "Has exportado un fragmento corto y lo has comprobado en el dispositivo de destino (y, si hace falta, con MediaInfo/ffprobe).",
        "Solo entonces exportas la película completa.",
    ]),
    .h1("Anexo B. Glosario"),
    .table(headers: ["Término", "Explicación"], rows: [
        ["CRF", "Constant Rate Factor: modo de codificación con calidad constante; número menor = mejor calidad, archivo mayor"],
        ["QP", "Parámetro de cuantización: cuánto se comprime cada fotograma"],
        ["Fotograma clave / GOP", "Fotograma clave (imagen completa) / grupo de fotogramas entre dos fotogramas clave"],
        ["Fotograma B", "Fotograma codificado a partir de los fotogramas anteriores y posteriores; ayuda a la compresión"],
        ["Profile / Level", "Conjunto de herramientas permitidas / límites de resolución, fotogramas y bitrate; determina la compatibilidad con los dispositivos"],
        ["Croma 4:2:0 / 4:2:2", "Cuánta información de color se conserva respecto a la luminancia; el 4:2:2 conserva más en vertical"],
        ["Rec.709", "Estándar SDR para la televisión HD; gamma 2.4 (BT.1886)"],
        ["Rec.2020", "La gama de color amplia usada para HDR y UHD"],
        ["P3-D65 / P3-DCI", "La gama de color P3 con punto blanco D65 / con el punto blanco de cine DCI"],
        ["PQ (SMPTE ST 2084)", "La función de transferencia HDR basada en luminancia absoluta; la usa HDR10"],
        ["HLG", "Hybrid Log-Gamma: función de transferencia HDR compatible con pantallas SDR; usada en televisión"],
        ["HDR10", "PQ + Rec.2020 + 10 bits + metadatos estáticos (mastering display, MaxCLL, MaxFALL)"],
        ["Mastering display", "Las características del monitor en el que se etalonó (primarios, luminancia)"],
        ["MaxCLL / MaxFALL", "La luminancia máxima de un píxel / la luminancia media máxima de un fotograma, en toda la película, en nits"],
        ["Nit", "Unidad de luminancia (candela por metro cuadrado)"],
        ["SEI", "Un mensaje adicional en el flujo de vídeo; aquí transporta los metadatos HDR"],
        ["mdcv / clli", "Cajas del contenedor que transportan el mastering display y el nivel de luz del contenido"],
        ["Contenedor", "El archivo que empaqueta vídeo y audio (MOV, MP4, MKV)"],
        ["Data Levels (Video/Full)", "El intervalo de valores: Video (16–235 a 8 bits) o Full (0–255)"],
    ], widths: [0.26, 0.74]),
    .h1("Anexo C. Referencia rápida de niveles"),
    .table(headers: ["Resolución y velocidad", "H.264 (Level)", "H.265 (Level)"], rows: [
        ["1280×720, 30 fps", "3.1", "3.1"],
        ["1920×1080, 30 fps", "4.0 / 4.1", "4.0 / 4.1"],
        ["1920×1080, 60 fps", "4.2", "4.1"],
        ["2560×1440, 30 fps", "5.0", "5.0"],
        ["3840×2160, 30 fps", "5.1", "5.0"],
        ["3840×2160, 60 fps", "5.2", "5.1"],
    ], widths: [0.40, 0.30, 0.30]),
    .p("Cuando no estés seguro, deja **Level: Auto**."),
] }
