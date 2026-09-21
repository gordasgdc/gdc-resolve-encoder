import Foundation

// Edición en español, parte 1 (capítulos 1–9). Para clientes: sin nombres internos ni detalles de código.

func recipeES(_ title: String, _ rows: [[String]]) -> [Block] {
    [.h3(title), .table(headers: ["Ajuste", "Valor"], rows: rows, widths: [0.26, 0.74])]
}

func whitepaperBlocksES() -> [Block] {
    var b: [Block] = []
    b += es1(); b += es2(); b += es3(); b += es4(); b += es5(); b += es6()
    b += es7a(); b += es7b(); b += es8(); b += es9()
    b += es10a(); b += es10b(); b += es10c(); b += es10d()
    b += es11(); b += es12(); b += es13(); b += es14(); b += esAnnex()
    return b
}

private func es1() -> [Block] { [
    .h1("1. Resumen ejecutivo"),
    .p("**GDC Resolve Encoder** es un plugin de exportación para **DaVinci Resolve Studio** que añade a la lista de códecs encoders de software **H.264 (x264)** y **H.265 (x265)** con control fino de la calidad, exportación en **10 bits**, croma **4:2:2**, **metadatos HDR10** (mastering display, MaxCLL, MaxFALL) y tres **formatos propios** (GDC QuickTime, GDC MP4, GDC Matroska) que escriben la información HDR directamente en el archivo, no solo en el flujo de vídeo."),
    .p("El plugin no sustituye a los códecs nativos de Resolve (ProRes, DNxHR, XDCAM, DCP, EXR). Los complementa allí donde necesitas **H.264/H.265 controlado**: entregas para YouTube, redes sociales, televisores, plataformas de streaming, másteres ligeros y copias de revisión. El color no se reinterpreta: el plugin recibe de Resolve la imagen ya etalonada y la codifica, etiquetándola correctamente (Rec.709, Rec.2020, P3-D65, P3-DCI, PQ, HLG)."),
    .h2("En resumen"),
    .table(headers: ["Aspecto", "Qué ofrece"], rows: [
        ["Tipo", "Plugin de exportación (IO Encode Plugin) para DaVinci Resolve Studio 21.x"],
        ["Encoders", "x264 y x265 (software); Apple VideoToolbox (Mac); NVIDIA NVENC (Windows con GPU NVIDIA)"],
        ["Profundidad de bits", "8 y 10 bits"],
        ["Croma", "4:2:0 (8 y 10 bits) y 4:2:2 (10 bits)"],
        ["Color", "Rec.709, Rec.2020, P3-D65, P3-DCI; transferencia SDR, PQ (HDR10) y HLG"],
        ["HDR", "HDR10 estático: mastering display, MaxCLL, MaxFALL (en el flujo y, en los formatos GDC, en el contenedor)"],
        ["Controles", "Preset, Profile, Level, Tune, CRF / bitrate / QP constante, intervalo de fotograma clave, parámetros expertos x264/x265"],
        ["Formatos", "QuickTime, MP4 y MKV de Resolve + GDC QuickTime, GDC MP4, GDC Matroska"],
        ["Plataformas", "macOS en Apple Silicon (arm64); Windows de 64 bits"],
        ["Dependencias", "Nada que instalar: FFmpeg y las bibliotecas necesarias vienen incluidos en el paquete"],
    ], widths: [0.24, 0.76]),
    .note(.info, "Este documento describe qué hace el plugin, cómo funciona y cómo configurarlo para destinos concretos. El capítulo 14 indica explícitamente qué se ha verificado en DaVinci Resolve y qué aún no se ha probado."),
] }

private func es2() -> [Block] { [
    .h1("2. Qué es GDC Resolve Encoder"),
    .h2("2.1 El problema que resuelve"),
    .p("Un colorista o un editor llega, al final, a la misma pregunta: ¿con qué ajustes exporto para que el archivo se vea bien, tenga un tamaño razonable y la plataforma de destino lo reconozca correctamente? H.264 y H.265 tienen decenas de parámetros, y la diferencia entre un buen ajuste y uno pobre se nota en el banding, en la pérdida de detalle, en el tamaño del archivo y, en HDR, en si el televisor o la plataforma reconoce la imagen como HDR."),
    .p("El plugin lleva a Resolve los encoders x264 y x265, muy extendidos en la industria, con sus parámetros expuestos en el panel de exportación, además de la exportación en 10 bits y 4:2:2 y la escritura correcta de los metadatos HDR10."),
    .h2("2.2 Qué aporta"),
    .bullets([
        "**Control fino de la calidad**: CRF (calidad constante), bitrate objetivo o QP constante, con preset, level y tune.",
        "**10 bits** para HDR y para SDR sin banding, además de **4:2:2** para másteres y entregas con croma completo en vertical.",
        "**Etiquetas de color correctas** en el archivo, leídas de los ajustes del proyecto: Rec.709, Rec.2020, P3-D65, P3-DCI, PQ, HLG.",
        "**HDR10 estático**: mastering display y MaxCLL/MaxFALL, escritos en el flujo de vídeo y, mediante los formatos GDC, también en el contenedor.",
        "**Formatos propios** (GDC QuickTime, GDC MP4, GDC Matroska) seleccionables directamente en la lista Format de Deliver.",
        "**Parámetros expertos**: un campo donde puedes pasar opciones x264/x265 directamente para casos especiales.",
    ]),
    .h2("2.3 A quién va dirigido"),
    .bullets([
        "Coloristas y editores que entregan en **YouTube, Instagram, Facebook, TikTok, Vimeo** y quieren control sobre la calidad.",
        "Quienes producen **contenido HDR10 o HLG** y necesitan que los metadatos lleguen al archivo.",
        "Quienes entregan **archivos para televisor** (USB, streamer, Apple TV) y buscan la máxima compatibilidad.",
        "Estudios que quieren **másteres ligeros H.264/H.265 4:2:2 10-bit** o copias de revisión consistentes.",
    ]),
    .h2("2.4 Requisitos y compatibilidad"),
    .table(headers: ["Requisito", "Detalles"], rows: [
        ["DaVinci Resolve", "Versión **Studio** (el SDK de plugins de exportación funciona en Studio). Verificado en Studio 21.1."],
        ["Mac", "macOS en **Apple Silicon** (M1/M2/M3/M4...). Los Mac Intel no son el objetivo de esta versión."],
        ["Windows", "Windows 10/11, de 64 bits. La codificación por hardware NVENC requiere GPU NVIDIA y un controlador actual."],
        ["Linux", "No se ofrece."],
        ["Instalación en Mac", "Paquete `.pkg` firmado y notarizado por Apple, que se instala con doble clic en la carpeta IOPlugins de Resolve."],
        ["Instalación en Windows", "Archivo con script de instalación; copia el plugin en la carpeta IOPlugins de Resolve."],
        ["Dependencias", "FFmpeg y las bibliotecas necesarias están incluidos en el paquete; no hay que instalar nada más."],
        ["Licencia", "Código de activación vinculado al Machine ID (véase el capítulo 3.6)."],
    ], widths: [0.24, 0.76]),
] }

private func es3() -> [Block] { [
    .h1("3. Cómo funciona"),
    .h2("3.1 El flujo de una exportación"),
    .p("Cuando eliges un códec GDC en Deliver y empiezas el render, Resolve procesa la línea de tiempo (etalonaje, efectos, escalado) y entrega cada fotograma ya terminado al plugin. El plugin lo codifica y envía los paquetes de vídeo al contenedor, que los escribe en el archivo junto con el audio."),
    .code("Línea de tiempo de Resolve  →  fotogramas YUV terminados\n      ↓\n  Plugin GDC: conversión (16 → 10 bits si procede) + etiquetas de color\n      ↓\n  Encoder: x264 / x265 (software)  o  VideoToolbox / NVENC (hardware)\n      ↓\n  Paquetes H.264 / H.265\n      ↓\n  Contenedor: QuickTime / MP4 / MKV (Resolve)  o  GDC QuickTime / GDC MP4 / GDC Matroska\n      ↓\n  Archivo final"),
    .h2("3.2 Qué recibe el plugin de Resolve"),
    .p("Resolve envía la imagen como **planos YUV**. A 8 bits, cada muestra ocupa un byte. A 10 bits, Resolve entrega cada muestra en un contenedor de **16 bits**, con el valor desplazado 6 bits (es decir, en la escala completa de 16 bits). El plugin convierte a 10 bits con **redondeo** y limitación a 1023, por lo que no introduce pérdidas más allá de las propias del códec."),
    .note(.info, "No tienes que hacer nada al respecto: la conversión es automática. Solo es útil saberlo si analizas archivos con herramientas externas y te preguntas por qué los valores de entrada están en 16 bits."),
    .h2("3.3 Los encoders"),
    .table(headers: ["Encoder", "Tipo", "Puntos fuertes", "Puntos débiles"], rows: [
        ["x264 (H.264)", "Software", "Calidad excelente con bitrate bajo, control muy fino, compatibilidad máxima", "Más lento que el hardware; el H.264 en 10 bits o 4:2:2 no lo reproducen muchos televisores"],
        ["x265 (H.265/HEVC)", "Software", "Archivos más pequeños con la misma calidad, 10 bits y HDR, 4K", "El más lento; algunas plataformas o dispositivos antiguos no lo reproducen"],
        ["Apple VideoToolbox", "Hardware (Mac)", "Muy rápido, adecuado para previsualizaciones", "Menor calidad con el mismo bitrate que x264/x265; solo 8 bits, 4:2:0"],
        ["NVIDIA NVENC", "Hardware (Windows)", "Muy rápido en GPU NVIDIA", "Igual que el anterior; solo con GPU NVIDIA"],
    ], widths: [0.19, 0.14, 0.34, 0.33]),
    .h2("3.4 El etiquetado del color"),
    .p("Cada archivo contiene, además de la imagen, **etiquetas** que indican al reproductor en qué espacio de color se codificó (primarios, función de transferencia, matriz). El plugin las lee de los ajustes del proyecto de Resolve (Output Color Space) y las escribe en el archivo. Si Resolve no envía ningún valor o envía uno desconocido, se usa **Rec.709**: el plugin no adivina el espacio de color a partir de la profundidad de bits."),
    .table(headers: ["Output Color Space en Resolve", "Primarios", "Transferencia", "Matriz"], rows: [
        ["Rec.709 (Scene)", "Rec.709 (1)", "Rec.709 (1)", "Rec.709 (1)"],
        ["Rec.2100 ST2084 (PQ)", "Rec.2020 (9)", "SMPTE ST 2084 / PQ (16)", "Rec.2020 nc (9)"],
        ["Rec.2100 HLG", "Rec.2020 (9)", "ARIB STD-B67 / HLG (18)", "Rec.2020 nc (9)"],
        ["P3-D65", "SMPTE EG 432 / P3-D65 (12)", "SMPTE ST 428 (17)", "Rec.709 (1)"],
        ["P3-DCI", "SMPTE RP 431 / P3-DCI (11)", "SMPTE ST 428 (17)", "Rec.709 (1)"],
    ], widths: [0.32, 0.24, 0.26, 0.18]),
    .note(.info, "La tabla refleja lo que envía Resolve 21.1 y lo que escribe el plugin (los valores entre paréntesis son los códigos estándar CICP). En HLG se escribe la etiqueta de transferencia, pero no hay metadatos estáticos de tipo HDR10."),
    .h2("3.5 Los contenedores"),
    .p("Hay dos familias de formatos en la lista Format de Deliver:"),
    .bullets([
        "**Los formatos de Resolve** (QuickTime, MP4, MKV): Resolve empaqueta el archivo y se ocupa de todo el audio (PCM, AAC, etc.). Los códecs GDC aparecen aquí como una opción de códec. El contenedor de Resolve **no escribe** los metadatos HDR10 en el contenedor; permanecen en el flujo de vídeo.",
        "**Los formatos GDC** (GDC QuickTime, GDC MP4, GDC Matroska): el plugin empaqueta el archivo. Escribe las etiquetas de color, el **mastering display** y **MaxCLL/MaxFALL** directamente en el contenedor, y el audio es **PCM** sin comprimir.",
    ]),
    .h2("3.6 El licenciamiento"),
    .p("El plugin requiere un **código de activación** vinculado al **Machine ID** del ordenador (que se muestra en el panel del plugin). El código se introduce una sola vez; tras la activación, el campo desaparece del panel. La verificación es local, sin conexión a internet. La activación se obtiene apoyando el proyecto mediante una donación. Sin una licencia activa, la exportación no se inicia."),
] }

private func es4() -> [Block] { [
    .h1("4. Qué hace y qué no hace"),
    .h2("4.1 Qué hace"),
    .table(headers: ["Capacidad", "Detalles"], rows: [
        ["Codificación H.264 y H.265", "x264 y x265 a 8 y 10 bits; 4:2:0 (8/10 bits) y 4:2:2 (10 bits)"],
        ["Control de la calidad", "CRF, bitrate objetivo, QP constante; preset, level, tune, intervalo de fotograma clave"],
        ["Parámetros expertos", "Cadena libre de opciones x264/x265 (por ejemplo aq-mode, psy-rd, vbv-maxrate)"],
        ["Etiquetas de color", "Rec.709, Rec.2020, P3-D65, P3-DCI; SDR, PQ, HLG; rango Video o Full"],
        ["HDR10 estático", "Mastering display (P3-D65 o Rec.2020, luminancia de pico), MaxCLL, MaxFALL"],
        ["Formatos propios", "GDC QuickTime, GDC MP4, GDC Matroska, con HDR en el contenedor"],
        ["Audio", "En los formatos GDC: PCM de 16/24/32 bits, escrito sin cambios (probado con un tono de 1 kHz)"],
        ["Hardware", "VideoToolbox (Mac) y NVENC (Windows, GPU NVIDIA) para previsualizaciones rápidas"],
        ["Compatibilidad", "Los códecs siguen disponibles también en el QuickTime, MP4 y MKV de Resolve"],
    ], widths: [0.26, 0.74]),
    .h2("4.2 Qué no hace"),
    .table(headers: ["No hace", "Qué hacer en su lugar"], rows: [
        ["ProRes, DNxHR/DNxHD, XDCAM, DCP, EXR, DPX", "Usa los códecs nativos de Resolve"],
        ["4:4:4; 4:2:2 a 8 bits", "El 4:2:2 existe solo a 10 bits; para 4:4:4 usa ProRes 4444 u otro códec nativo"],
        ["Codificación en dos pasadas (2-pass)", "Usa CRF o bitrate objetivo con VBV (véase el capítulo 11)"],
        ["HDR10+ y Dolby Vision", "El plugin escribe solo HDR10 estático; HLG solo se etiqueta"],
        ["AAC / AC-3 en los formatos GDC", "En los formatos GDC el audio es PCM; para AAC usa el MP4 o QuickTime de Resolve con un códec GDC"],
        ["Timecode inicial y marcadores en los formatos GDC", "Aún no se escriben; en los formatos de Resolve se aplican los de Resolve"],
        ["AV1 y VP9", "No están incluidos"],
        ["Conversión de espacio de color", "El color management lo hace Resolve; el plugin solo etiqueta"],
        ["CBR estricto desde el panel", "Se puede aproximar con vbv-maxrate/vbv-bufsize en los parámetros avanzados"],
        ["Linux y Mac Intel", "No son objetivos de esta versión"],
    ], widths: [0.42, 0.58]),
] }

private func es5() -> [Block] { [
    .h1("5. Ventajas y desventajas"),
    .h2("5.1 Ventajas"),
    .bullets([
        "**Mejor relación calidad/tamaño que los encoders por hardware**: x264 y x265 producen archivos más pequeños con la misma calidad visual.",
        "**10 bits y 4:2:2**: menos banding en los degradados, croma más limpio en gráficos y texto de color.",
        "**HDR10 completo**: etiquetas + mastering display + MaxCLL/MaxFALL, también en el contenedor (formatos GDC).",
        "**Control granular** sin salir de Resolve: preset, level, tune, VBV, parámetros expertos.",
        "**Sin instalaciones adicionales**: FFmpeg y las bibliotecas vienen en el paquete.",
        "**Compatible** con tu flujo actual: los códecs funcionan también en los formatos nativos de Resolve.",
        "**Reproducible**: los mismos ajustes dan el mismo resultado, útil para entregas repetidas.",
    ]),
    .h2("5.2 Desventajas y límites"),
    .bullets([
        "**Velocidad**: x265 y los presets lentos (slower, veryslow) tardan mucho; el hardware es rápido, pero más débil en calidad.",
        "**Audio**: solo PCM en los formatos GDC; el PCM en MP4 tiene poco soporte en algunos reproductores.",
        "**Compatibilidad de reproducción**: el H.264 en 10 bits y 4:2:2 no lo reproducen muchos televisores y teléfonos; el H.265 no se acepta en todas partes.",
        "**Sin timecode ni marcadores** en los formatos GDC.",
        "**Requiere Resolve Studio** y una licencia activada.",
        "**No cubre** las entregas que exigen ProRes, DNxHR, XDCAM o DCP; esas siguen con los códecs nativos.",
    ]),
    .h2("5.3 Cuándo NO usar el plugin"),
    .bullets([
        "Cuando el destino exige un códec concreto de broadcast o de cine (ProRes, DNxHR, XDCAM, DCP, DPX/EXR).",
        "Cuando necesitas el timecode inicial y los marcadores en el archivo exportado pero quieres el formato GDC: usa un formato de Resolve.",
        "Cuando el destino exige AAC y además quieres los metadatos HDR en el contenedor: ahora mismo no se pueden tener ambos en un solo archivo.",
        "Cuando necesitas Dolby Vision o HDR10+.",
    ]),
] }

private func es6() -> [Block] { [
    .h1("6. Las variantes de códec"),
    .p("En Deliver, en Codec eliges **GDC Encoder** y después, en **Type**, una de las variantes siguientes (en los formatos GDC propios del plugin, las mismas variantes aparecen directamente como códec). Las variantes por hardware aparecen solo si el equipo dispone del encoder correspondiente."),
    .table(headers: ["Variante (Type)", "Bits", "Croma", "Perfil", "Recomendado para"], rows: [
        ["GDC H.264 (Software x264)", "8", "4:2:0", "Baseline / Main / High (High por defecto)", "Web, redes sociales, televisores, máxima compatibilidad"],
        ["GDC H.265 (Software x265)", "8", "4:2:0", "Main", "SDR 4K, archivos pequeños"],
        ["GDC H.264 (Apple VideoToolbox)", "8", "4:2:0", "—", "Previsualizaciones rápidas en Mac"],
        ["GDC H.265 (Apple VideoToolbox)", "8", "4:2:0", "—", "Previsualizaciones rápidas en Mac"],
        ["GDC H.264 (NVIDIA NVENC)", "8", "4:2:0", "—", "Previsualizaciones rápidas en Windows con NVIDIA"],
        ["GDC H.265 (NVIDIA NVENC)", "8", "4:2:0", "—", "Previsualizaciones rápidas en Windows con NVIDIA"],
        ["GDC H.264 10-bit (Software x264 High10)", "10", "4:2:0", "High 10", "SDR de 10 bits sin banding; reproducción limitada en TV/teléfono"],
        ["GDC H.265 10-bit (Software x265 Main10)", "10", "4:2:0", "Main 10", "HDR10, HLG, 4K, entregas modernas"],
        ["GDC H.264 4:2:2 10-bit (Software x264 High 4:2:2)", "10", "4:2:2", "High 4:2:2", "Másteres ligeros, entregas de posproducción"],
        ["GDC H.265 4:2:2 10-bit (Software x265 Main 4:2:2 10)", "10", "4:2:2", "Main 4:2:2 10 (Rext)", "Másteres HDR 4:2:2, gráficos con texto de color"],
    ], widths: [0.34, 0.06, 0.08, 0.22, 0.30]),
    .note(.warn, "Las variantes de 10 bits y 4:2:2 están pensadas para la posproducción y las plataformas modernas. Muchos televisores, teléfonos y reproductores por hardware no decodifican H.264 en 10 bits o 4:2:2. Para reproducir en televisor usa 8 bits 4:2:0 (SDR) o H.265 Main10 4:2:0 (HDR)."),
] }

private func es7a() -> [Block] { [
    .h1("7. Referencia completa de los ajustes"),
    .p("Los ajustes del plugin (\"Plugin Settings\") aparecen bajo la selección del códec. Los marcados como \"solo software\" no aparecen en las variantes por hardware."),
    .h2("7.1 Preset (solo software)"),
    .p("El preset elige **cuánto esfuerzo** dedica el encoder a comprimir de forma eficiente. Un preset más lento produce, con el mismo CRF, un archivo más pequeño o de mejor calidad, pero tarda más. No cambia \"qué tipo\" de imagen obtienes, sino lo bien que se comprime."),
    .table(headers: ["Preset", "Velocidad", "Eficiencia", "Cuándo"], rows: [
        ["ultrafast", "Máxima", "Muy baja (archivos grandes)", "Pruebas, previsualizaciones de urgencia"],
        ["superfast", "Muy alta", "Baja", "Revisión rápida"],
        ["veryfast", "Alta", "Media-baja", "Dailies, copias de trabajo"],
        ["faster", "Buena", "Media", "Copias de trabajo con calidad aceptable"],
        ["fast", "Buena", "Media-buena", "Entregas rápidas"],
        ["**medium** (por defecto)", "Equilibrada", "Buena", "Uso general"],
        ["slow", "Más lenta", "Muy buena", "**Recomendado para la entrega final**"],
        ["slower", "Lenta", "Excelente", "Entrega final, cuando hay tiempo"],
        ["veryslow", "Muy lenta", "Máxima", "Ganancia pequeña sobre \"slower\"; rara vez se justifica"],
    ], widths: [0.20, 0.16, 0.26, 0.38]),
    .note(.tip, "Regla práctica: elige **slow** para la entrega final y **veryfast** para la revisión. La diferencia entre slower y veryslow suele ser pequeña frente al tiempo adicional."),
    .h2("7.2 Profile (solo software, H.264 de 8 bits)"),
    .table(headers: ["Perfil", "Qué significa", "Cuándo"], rows: [
        ["baseline", "Conjunto restringido de herramientas, sin fotogramas B; menor calidad con el mismo bitrate", "Solo dispositivos muy antiguos"],
        ["main", "Amplia compatibilidad, menos herramientas que High", "Reproductores antiguos que no aceptan High"],
        ["**high** (por defecto)", "El conjunto completo para 8 bits; la mejor eficiencia", "Casi cualquier destino moderno"],
    ], widths: [0.20, 0.50, 0.30]),
    .p("En H.265, a 10 bits y a 4:2:2 el perfil lo elige automáticamente el encoder (Main, Main 10, Main 4:2:2 10, High 10, High 4:2:2)."),
    .h2("7.3 Level (solo software)"),
    .p("El level limita la resolución, la velocidad de fotogramas y el bitrate máximo para que el archivo pueda reproducirse en determinados dispositivos. **Auto** (por defecto) deja que el encoder elija según la resolución; sirve en la mayoría de los casos. Lo fijas solo cuando un dispositivo concreto exige un level máximo."),
    .table(headers: ["Level", "H.264: adecuado para", "H.265: adecuado para"], rows: [
        ["3.0 / 3.1", "SD y 720p", "720p"],
        ["4.0 / 4.1", "1080p hasta 30 fps", "1080p hasta 30 fps (4.0), 1080p60 (4.1)"],
        ["4.2", "1080p60", "1080p60 y superior"],
        ["5.0", "Resoluciones grandes, pocos fotogramas por segundo", "**4K hasta 30 fps**"],
        ["5.1", "**4K hasta 30 fps**", "**4K hasta 60 fps**"],
        ["5.2", "**4K hasta 60 fps**", "4K hasta 120 fps"],
    ], widths: [0.14, 0.43, 0.43]),
    .note(.info, "Un level demasiado bajo para la resolución elegida hace que el encoder rechace la combinación o limite el bitrate. Un level demasiado alto no perjudica, pero puede hacer que el archivo no se pueda decodificar en dispositivos que se detienen en un level menor."),
    .h2("7.4 Tune (solo software)"),
    .p("El tune optimiza el encoder para un tipo de contenido. \"none\" (por defecto) es bueno en la mayoría de los casos."),
    .table(headers: ["Tune", "Qué hace", "Cuándo", "Disponible"], rows: [
        ["none", "Sin optimización especial", "Uso general", "H.264, H.265"],
        ["film", "Conserva el detalle fino en contenido filmado, bitrate alto", "Películas, contenido con textura fina", "Solo H.264"],
        ["animation", "Optimizado para zonas planas y contornos nítidos", "Animación, gráficos, dibujos", "H.264, H.265"],
        ["grain", "Conserva la estructura del grano y la mantiene uniforme", "Material con grano de película", "H.264, H.265"],
        ["stillimage", "Optimizado para imágenes casi estáticas", "Presentaciones, pases de diapositivas", "Solo H.264"],
        ["psnr / ssim", "Optimiza métricas objetivas, no el aspecto", "Comparaciones técnicas, no entrega", "H.264, H.265"],
        ["fastdecode", "Simplifica el flujo para que se decodifique con facilidad", "Dispositivos débiles; reduce la eficiencia de la compresión", "H.264, H.265"],
        ["zerolatency", "Sin retardo de codificación (sin fotogramas B ni lookahead)", "Streaming en directo; no para archivos de entrega", "H.264, H.265"],
    ], widths: [0.14, 0.34, 0.34, 0.18]),
    .note(.warn, "fastdecode y zerolatency reducen la eficiencia de la compresión: la misma calidad exige un archivo mayor. No los uses en entregas habituales."),
] }

private func es7b() -> [Block] { [
    .h2("7.5 Rate Control: cómo eliges la calidad"),
    .p("Tienes tres modos. La elección determina si controlas la **calidad** o el **tamaño**."),
    .table(headers: ["Modo", "Qué controlas", "Ventaja", "Inconveniente", "Cuándo"], rows: [
        ["**Constant Quality (CRF)** (por defecto)", "La calidad: número de 0 a 51, menor = mejor", "Calidad constante en toda la película; el más eficiente", "El tamaño final no se conoce de antemano", "Casi siempre"],
        ["**Target Bitrate**", "El tamaño: kbps (500–100000)", "Tamaño previsible", "Calidad variable: las escenas difíciles pueden salir flojas", "Cuando la plataforma exige un bitrate; hardware"],
        ["**Constant QP**", "La cuantización de cada fotograma", "Comportamiento predecible, sin adaptación", "Ineficiente; archivos grandes", "Pruebas, análisis, casos especiales"],
    ], widths: [0.19, 0.20, 0.22, 0.21, 0.18]),
    .note(.tip, "La regla: si no tienes un requisito de bitrate, usa **CRF**. Si la plataforma impone un tope, usa CRF **más** un límite VBV (véase el capítulo 11)."),
    .note(.info, "Las variantes por hardware (VideoToolbox, NVENC) no tienen CRF nativo: si eliges CRF, el plugin usa un bitrate por defecto de unos 12 Mbps. Para hardware elige **Target Bitrate**."),
    .h2("7.6 Quality (CRF): valores recomendados"),
    .p("Los valores siguientes son **puntos de partida** para contenido filmado habitual; el contenido muy detallado o con grano exige un CRF menor. x265 usa una escala algo distinta: para la misma calidad visual, el CRF de x265 suele ser **3–5 unidades mayor** que el de x264 (regla empírica)."),
    .table(headers: ["Propósito", "x264 (H.264)", "x265 (H.265)", "Observaciones"], rows: [
        ["Máster / archivo ligero", "14–16", "16–18", "Archivos grandes; se recomiendan 10 bits"],
        ["Entrega de alta calidad", "17–19", "19–22", "Cliente exigente, festivales"],
        ["Entrega estándar (YouTube, Vimeo)", "18–21", "21–24", "La plataforma recomprime; deja margen"],
        ["Redes sociales (Instagram, TikTok, Facebook)", "20–23", "23–26", "La plataforma recomprime con fuerza"],
        ["Revisión / proxy", "24–28", "27–30", "Tamaño pequeño, calidad suficiente"],
        ["Archivo muy pequeño", "26–30", "28–32", "Pérdidas visibles en el detalle"],
    ], widths: [0.30, 0.16, 0.16, 0.38]),
    .h2("7.7 Bit Rate (Target Bitrate)"),
    .p("Un deslizador entre **500 y 100000 kbps**, en pasos de 100. Los valores siguientes son orientativos para H.264 SDR; en H.265 puedes usar aproximadamente el **60–70 %** de estos valores con una calidad comparable (regla empírica)."),
    .table(headers: ["Resolución / velocidad de fotogramas", "H.264 SDR", "H.265 / HDR (orientativo)"], rows: [
        ["720p 24–30", "5–7,5 Mbps", "4–6 Mbps"],
        ["1080p 24–30", "8–12 Mbps", "6–9 Mbps"],
        ["1080p 48–60", "12–18 Mbps", "9–13 Mbps"],
        ["1440p 24–30", "16 Mbps", "12 Mbps"],
        ["4K 24–30", "35–45 Mbps", "25–35 Mbps (HDR: 44–56 Mbps recomendado por algunas plataformas)"],
        ["4K 48–60", "53–68 Mbps", "40–50 Mbps (HDR: 66–85 Mbps recomendado por algunas plataformas)"],
    ], widths: [0.34, 0.24, 0.42]),
    .h2("7.8 Keyframe Interval (sec)"),
    .p("La distancia entre dos fotogramas clave (imágenes completas), entre **1 y 10 segundos**, por defecto **2 segundos**. El plugin la convierte en fotogramas usando la velocidad real del proyecto. Un intervalo corto significa desplazamiento rápido y buena recuperación ante errores, pero un archivo algo mayor; uno largo, un archivo algo menor pero un desplazamiento más lento."),
    .table(headers: ["Propósito", "Valor"], rows: [
        ["Streaming / web (por defecto)", "2 segundos"],
        ["Redes sociales, plataformas que recomprimen", "1–2 segundos"],
        ["Entregas de posproducción, edición posterior", "1 segundo"],
        ["Archivo pequeño para un archivo de visionado", "4–5 segundos"],
    ], widths: [0.62, 0.38]),
    .p("El número de fotogramas B está fijado en **2**; no se cambia desde el panel."),
    .h2("7.9 Advanced Params (x264/x265)"),
    .p("Un campo de texto donde escribes opciones directas para el encoder, con la forma `clave=valor:clave=valor` (por ejemplo `aq-mode=3:psy-rd=1.0,0.15`). Se envían directamente a x264 o x265, según la variante elegida. Detalles y ejemplos en el capítulo 11."),
    .note(.warn, "Una cadena no válida hace que el encoder se niegue a iniciar la exportación. Si la exportación no se inicia tras rellenar el campo, vacíalo y vuelve a intentarlo. Las opciones que escribes aquí tienen prioridad sobre las del panel (incluido HDR10)."),
    .h2("7.10 HDR10 Metadata (solo software)"),
    .p("El grupo de ajustes que escribe los metadatos estáticos HDR10. Está **desactivado** por defecto. Se aplica solo cuando la exportación es **PQ** (Output Color Space: Rec.2100 ST2084)."),
    .table(headers: ["Ajuste", "Valores", "Qué significa"], rows: [
        ["HDR10 Metadata", "Off / On (PQ exports only)", "Off: no se escribe nada. On: se escriben los datos siguientes, solo si la exportación es PQ."],
        ["Mastering Primaries", "P3-D65 / Rec.2020", "La gama del **monitor en el que etalonaste** (no el espacio de color de la imagen). P3-D65 es el caso habitual."],
        ["Mastering Peak", "100–10000 nits (por defecto 1000)", "La luminancia máxima del monitor de masterización."],
        ["MaxCLL", "0–10000 nits (0 = no señalizado)", "El píxel más luminoso de toda la película."],
        ["MaxFALL", "0–4000 nits (0 = no señalizado)", "La mayor luminancia media de un fotograma de toda la película."],
    ], widths: [0.20, 0.30, 0.50]),
    .p("La luminancia mínima del display de masterización está fijada en 0,005 nits. Más sobre HDR en el capítulo 8."),
    .h2("7.11 Ajustes de Resolve que influyen en la exportación"),
    .table(headers: ["Ajuste de Resolve", "Recomendación", "Por qué"], rows: [
        ["Output Color Space (Color Management)", "Rec.709 para SDR; Rec.2100 ST2084 para HDR10; Rec.2100 HLG para HLG", "De aquí salen las etiquetas de color escritas en el archivo"],
        ["Data Levels (Advanced Settings)", "**Video** para casi cualquier entrega", "Full range hace que algunos reproductores muestren la imagen deslavada o demasiado contrastada"],
        ["Color Space Tag / Gamma Tag", "Same as project", "Deja que el etiquetado siga al proyecto"],
        ["Retain sub-black and super-white data", "Desmarcado para la entrega", "Solo para flujos intermedios"],
        ["Resolution", "Ancho y alto **pares**", "El plugin rechaza las dimensiones impares"],
        ["Frame rate", "La de la línea de tiempo", "Cambiar la velocidad al exportar provoca tirones"],
        ["Export Audio", "Marcado, o desmarcado si trabajas por separado", "Los formatos GDC escriben PCM"],
    ], widths: [0.31, 0.37, 0.32]),
    .h2("7.12 Comportamientos fijos"),
    .bullets([
        "Fotogramas B: 2. El encoder usa automáticamente el número de hilos adecuado al procesador (hasta 32).",
        "La codificación no mantiene todo el archivo en memoria: los fotogramas se codifican uno a uno, por lo que el consumo de memoria es estable incluso en exportaciones largas.",
        "Las variantes por hardware NVENC intentan iniciarse hasta 3 veces, porque la sesión de la GPU puede estar ocupada temporalmente.",
    ]),
] }

private func es8() -> [Block] { [
    .h1("8. Color y HDR en detalle"),
    .h2("8.1 SDR: Rec.709, gamma 2.4"),
    .p("La entrega estándar para web y televisión SDR: primarios Rec.709, transferencia Rec.709/BT.1886 (gamma 2.4 en un monitor calibrado), rango de niveles **Video** (16–235 a 8 bits). En Resolve, Output Color Space: Rec.709. El plugin escribe las etiquetas 1/1/1 y no añade metadatos HDR."),
    .h2("8.2 HDR10 (PQ)"),
    .p("HDR10 usa la función de transferencia **PQ (SMPTE ST 2084)** y los primarios **Rec.2020**, en **10 bits**, con metadatos estáticos (mastering display, MaxCLL, MaxFALL). Es el formato HDR aceptado por la mayoría de los televisores y plataformas."),
    .bullets([
        "Output Color Space: **Rec.2100 ST2084**.",
        "Códec: una variante H.265 de **10 bits** (Main10) o 4:2:2 10-bit.",
        "HDR10 Metadata: **On**, con el monitor de masterización real.",
        "Formato: **GDC MP4**, **GDC QuickTime** o **GDC Matroska**, para que los metadatos lleguen también al contenedor.",
    ]),
    .h2("8.3 HLG"),
    .p("HLG (Hybrid Log-Gamma) se usa sobre todo en televisión, porque se ve razonablemente también en pantallas SDR. Se exporta con Output Color Space **Rec.2100 HLG**; el plugin escribe la etiqueta de transferencia HLG. HLG **no usa** metadatos estáticos HDR10, así que pon **HDR10 Metadata: Off**."),
    .h2("8.4 P3-D65 y P3-DCI"),
    .p("Si trabajas en P3-D65 (por ejemplo para entregas de Apple o pantallas P3) o en P3-DCI (cine digital), el Output Color Space correspondiente hace que el plugin escriba los primarios P3 en el flujo y en el contenedor. Comprueba que la plataforma de destino interpreta bien P3; muchas plataformas web esperan Rec.709 o Rec.2020."),
    .h2("8.5 Mastering display frente al espacio de color de la imagen"),
    .p("Son dos cosas distintas, que a menudo se confunden:"),
    .table(headers: ["", "El espacio de color de la imagen", "Mastering display"], rows: [
        ["Qué describe", "Cómo se codifican los píxeles (p. ej. Rec.2020 + PQ)", "El monitor en el que etalonaste"],
        ["De dónde viene", "De Output Color Space en Resolve", "Del panel del plugin (Mastering Primaries, Mastering Peak)"],
        ["Quién lo usa", "El reproductor, al decodificar y mostrar", "El televisor, para el tone mapping"],
        ["¿Cambia los píxeles?", "Sí (define su interpretación)", "No; solo informa al televisor"],
    ], widths: [0.20, 0.40, 0.40]),
    .p("Un ejemplo habitual: la imagen está en un contenedor Rec.2020/PQ, mientras que el mastering display es **P3-D65** con un pico de **1000 nits**, porque etalonaste en un monitor P3 que llega a 1000 nits. Elige **Rec.2020** en Mastering Primaries solo si tu monitor cubre casi toda la gama Rec.2020 (algo poco frecuente)."),
    .h2("8.6 MaxCLL y MaxFALL"),
    .bullets([
        "**MaxCLL** (Maximum Content Light Level): la luminancia del píxel más luminoso de toda la película, en nits.",
        "**MaxFALL** (Maximum Frame-Average Light Level): la mayor luminancia media de un fotograma de toda la película, en nits.",
    ]),
    .p("Los valores correctos se **miden** sobre el contenido final. Si no los has medido, deja **0** (no señalizado), que es más correcto que un valor inventado: un MaxCLL demasiado bajo o demasiado alto puede hacer que el tone mapping del televisor se comporte mal."),
    .note(.warn, "Los valores de los ejemplos de este documento (1000 y 400) son solo ilustrativos. No los copies en entregas reales sin medirlos."),
    .h2("8.7 Ejemplo: etalonaje en la pantalla de un portátil con perfil HDR"),
    .p("Si etalonas en la pantalla interna de un portátil Apple con el perfil HDR activo, la pantalla trabaja en P3 con PQ. Ajustes prudentes: **Mastering Primaries: P3-D65**, **Mastering Peak: 1000**, MaxCLL/MaxFALL medidos o 0. La pantalla de un portátil no es un monitor de referencia HDR: para entregas con requisitos estrictos, comprueba también en un televisor HDR. Un monitor externo SDR calibrado en Rec.709 no puede evaluar el HDR; la versión SDR se verifica por separado."),
    .h2("8.8 Qué metadatos HDR no se admiten"),
    .bullets([
        "**HDR10+** (metadatos dinámicos) y **Dolby Vision**: el plugin no los escribe.",
        "**HLG** se etiqueta, pero no tiene metadatos estáticos adicionales.",
    ]),
] }

private func es9() -> [Block] { [
    .h1("9. Contenedores y audio"),
    .h2("9.1 Los formatos de Resolve frente a los formatos GDC"),
    .table(headers: ["", "Formatos de Resolve (QuickTime / MP4 / MKV)", "Formatos GDC (GDC QuickTime / MP4 / Matroska)"], rows: [
        ["Quién empaqueta", "Resolve", "El plugin (mediante FFmpeg)"],
        ["Audio", "Cualquier códec que ofrezca Resolve (PCM, AAC, etc.)", "PCM de 16/24/32 bits, escrito sin cambios"],
        ["Metadatos HDR10 en el contenedor", "No", "Sí: mastering display y MaxCLL/MaxFALL"],
        ["Etiquetas de color en el contenedor", "Sí, escritas por Resolve", "Sí, escritas por el plugin"],
        ["Timecode inicial / marcadores", "Sí", "No (todavía)"],
        ["Cómo aparece en Deliver", "Format = QuickTime/MP4/MKV, luego Codec = GDC Encoder, luego Type", "Format = GDC ..., luego Type (directamente)"],
    ], widths: [0.24, 0.38, 0.38]),
    .p("Los formatos GDC aparecen en la lista **Format** después de los formatos nativos de Resolve, junto a otros formatos de plugins; su posición en la lista no se puede cambiar."),
    .h2("9.2 El audio"),
    .p("En los formatos GDC, Resolve envía el audio sin comprimir (PCM) y el plugin lo escribe sin cambios. Es la opción profesional para másteres y entregas de posproducción. Para destinos que exigen AAC, usa el formato MP4 o QuickTime de Resolve, con códec de vídeo GDC."),
    .table(headers: ["Contenedor", "Audio PCM", "Observación"], rows: [
        ["GDC QuickTime (.mov)", "Bueno", "Estándar en posproducción"],
        ["GDC Matroska (.mkv)", "Muy bueno", "Amplio soporte para PCM"],
        ["GDC MP4 (.mp4)", "Limitado", "El PCM en MP4 (ipcm) lo reproducen mal algunos reproductores (p. ej. QuickTime/Safari)"],
    ], widths: [0.28, 0.20, 0.52]),
    .note(.info, "Si no necesitas audio en el archivo, desmarca \"Export Audio\" en Deliver; el contenedor no recibirá entonces ninguna pista de audio."),
    .h2("9.3 Qué combinación elegir"),
    .table(headers: ["Propósito", "Formato", "Por qué"], rows: [
        ["HDR10 con metadatos en el archivo + audio PCM", "GDC QuickTime o GDC Matroska", "Metadatos en el contenedor; PCM bien soportado"],
        ["HDR10 para reproductores que exigen MP4", "GDC MP4", "Metadatos en el contenedor; comprueba la reproducción del audio"],
        ["SDR con AAC para web/redes", "MP4 de Resolve + códec GDC", "AAC compatible en todas partes"],
        ["Entrega que exige timecode/marcadores", "Formato de Resolve + códec GDC", "Los escribe Resolve"],
    ], widths: [0.38, 0.30, 0.32]),
] }
