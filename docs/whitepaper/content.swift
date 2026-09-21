import Foundation

// Conținutul whitepaper-ului. Adresat clienților: fără nume interne, fără detalii de cod.
// Valorile de export sunt puncte de plecare orientative; ce e verificat și ce nu e spus explicit în capitolul 14.

func recipe(_ title: String, _ rows: [[String]]) -> [Block] {
    [.h3(title), .table(headers: ["Setare", "Valoare"], rows: rows, widths: [0.26, 0.74])]
}

func whitepaperBlocks() -> [Block] {
    var b: [Block] = []
    b += ch1(); b += ch2(); b += ch3(); b += ch4(); b += ch5(); b += ch6()
    b += ch7a(); b += ch7b(); b += ch8(); b += ch9()
    b += ch10a(); b += ch10b(); b += ch10c(); b += ch10d()
    b += ch11(); b += ch12(); b += ch13(); b += ch14(); b += annex()
    return b
}

// ─────────────────────────── 1. Rezumat ───────────────────────────
private func ch1() -> [Block] { [
    .h1("1. Rezumat executiv"),
    .p("**GDC Resolve Encoder** este un plugin de export pentru **DaVinci Resolve Studio** care adaugă în lista de codecuri encodere software **H.264 (x264)** și **H.265 (x265)** cu control fin al calității, export pe **10 biți**, crominanță **4:2:2**, **metadata HDR10** (mastering display, MaxCLL, MaxFALL) și trei **formate proprii** (GDC QuickTime, GDC MP4, GDC Matroska) care scriu informația HDR direct în fișier, nu doar în fluxul video."),
    .p("Pluginul nu înlocuiește codecurile native ale lui Resolve (ProRes, DNxHR, XDCAM, DCP, EXR). Le completează acolo unde ai nevoie de **H.264/H.265 controlat**: livrări pentru YouTube, rețele sociale, televizoare, platforme de streaming, mastere ușoare și copii de revizuire. Culoarea nu este reinterpretată: pluginul primește imaginea gata etalonată de la Resolve și o codează, etichetând-o corect (Rec.709, Rec.2020, P3-D65, P3-DCI, PQ, HLG)."),
    .h2("Pe scurt"),
    .table(headers: ["Aspect", "Ce oferă"], rows: [
        ["Tip", "Plugin de export (IO Encode Plugin) pentru DaVinci Resolve Studio 21.x"],
        ["Encodere", "x264 și x265 (software); Apple VideoToolbox (Mac); NVIDIA NVENC (Windows cu GPU NVIDIA)"],
        ["Adâncime de culoare", "8 biți și 10 biți"],
        ["Crominanță", "4:2:0 (8 și 10 biți) și 4:2:2 (10 biți)"],
        ["Culoare", "Rec.709, Rec.2020, P3-D65, P3-DCI; transfer SDR, PQ (HDR10) și HLG"],
        ["HDR", "HDR10 static: mastering display, MaxCLL, MaxFALL (în flux și, în formatele GDC, în container)"],
        ["Controale", "Preset, Profile, Level, Tune, CRF / bitrate / QP constant, interval de keyframe, parametri expert x264/x265"],
        ["Formate", "QuickTime, MP4 și MKV ale lui Resolve + GDC QuickTime, GDC MP4, GDC Matroska"],
        ["Platforme", "macOS pe Apple Silicon (arm64); Windows 64-bit"],
        ["Dependențe", "Niciuna de instalat: FFmpeg și bibliotecile necesare sunt incluse în pachet"],
    ], widths: [0.24, 0.76]),
    .note(.info, "Acest document descrie ce face pluginul, cum funcționează și cum îl configurezi pentru destinații concrete. Capitolul 14 spune explicit ce a fost verificat în DaVinci Resolve și ce nu a fost încă testat."),
] }

// ─────────────────────────── 2. Ce este ───────────────────────────
private func ch2() -> [Block] { [
    .h1("2. Ce este GDC Resolve Encoder"),
    .h2("2.1 Problema pe care o rezolvă"),
    .p("Un colorist sau un editor ajunge, la final, la aceeași întrebare: cu ce setări exportez fișierul ca să arate bine, să aibă dimensiune rezonabilă și să fie recunoscut corect de platforma de destinație? Codecurile H.264 și H.265 au zeci de parametri, iar diferențele dintre o setare bună și una slabă se văd în bandă (banding), în pierderea detaliilor, în dimensiunea fișierului și, la HDR, în faptul că televizorul sau platforma recunoaște sau nu imaginea ca HDR."),
    .p("Pluginul aduce în Resolve encoderele x264 și x265, folosite pe scară largă în industrie, cu parametrii lor expuși în panoul de export, plus exportul pe 10 biți și 4:2:2 și scrierea corectă a metadatei HDR10."),
    .h2("2.2 Ce aduce în plus"),
    .bullets([
        "**Control fin al calității**: CRF (calitate constantă), bitrate țintă sau QP constant, cu preset, level și tune.",
        "**10 biți** pentru HDR și pentru SDR fără bandă, plus **4:2:2** pentru mastere și livrări cu crominanță completă pe verticală.",
        "**Etichete de culoare corecte** în fișier, citite din setările proiectului: Rec.709, Rec.2020, P3-D65, P3-DCI, PQ, HLG.",
        "**HDR10 static**: mastering display și MaxCLL/MaxFALL, scrise în fluxul video și, prin formatele GDC, și în container.",
        "**Formate proprii** (GDC QuickTime, GDC MP4, GDC Matroska) selectabile direct în lista Format din Deliver.",
        "**Parametri expert**: un câmp în care poți trimite direct opțiuni x264/x265 pentru situații speciale.",
    ]),
    .h2("2.3 Cui se adresează"),
    .bullets([
        "Coloriști și editori care livrează pe **YouTube, Instagram, Facebook, TikTok, Vimeo** și vor control asupra calității.",
        "Cei care fac **conținut HDR10 sau HLG** și au nevoie ca metadata să ajungă în fișier.",
        "Cei care livrează **fișiere pentru televizor** (USB, streamer, Apple TV) și vor compatibilitate maximă.",
        "Studiouri care vor **mastere H.264/H.265 4:2:2 10-bit** ușoare sau copii de revizuire consistente.",
    ]),
    .h2("2.4 Cerințe și compatibilitate"),
    .table(headers: ["Cerință", "Detalii"], rows: [
        ["DaVinci Resolve", "Versiunea **Studio** (SDK-ul de plugin-uri de export funcționează în Studio). Verificat pe Studio 21.1."],
        ["Mac", "macOS pe **Apple Silicon** (M1/M2/M3/M4...). Mac-urile Intel nu sunt ținta acestei versiuni."],
        ["Windows", "Windows 10/11, 64-bit. Codarea hardware NVENC necesită GPU NVIDIA și driver actual."],
        ["Linux", "Nu este oferit."],
        ["Instalare Mac", "Pachet `.pkg` semnat și notarizat de Apple, instalat cu dublu-clic în folderul IOPlugins al lui Resolve."],
        ["Instalare Windows", "Arhivă cu script de instalare; copiază pluginul în folderul IOPlugins al lui Resolve."],
        ["Dependențe", "FFmpeg și bibliotecile necesare sunt incluse în pachet; nu trebuie instalat nimic separat."],
        ["Licență", "Cod de activare legat de Machine ID (vezi capitolul 3.6)."],
    ], widths: [0.24, 0.76]),
] }

// ─────────────────────────── 3. Cum funcționează ───────────────────────────
private func ch3() -> [Block] { [
    .h1("3. Cum funcționează"),
    .h2("3.1 Fluxul unui export"),
    .p("Când alegi un codec GDC în Deliver și pornești randarea, Resolve procesează timeline-ul (etalonare, efecte, redimensionare), apoi livrează fiecare cadru gata finalizat către plugin. Pluginul îl codează și trimite pachetele video către container, care le scrie în fișier împreună cu sunetul."),
    .code("Timeline Resolve  →  cadre YUV finalizate\n      ↓\n  Plugin GDC: conversie (16 → 10 biți dacă e cazul) + etichete de culoare\n      ↓\n  Encoder: x264 / x265 (software)  sau  VideoToolbox / NVENC (hardware)\n      ↓\n  Pachete H.264 / H.265\n      ↓\n  Container: QuickTime / MP4 / MKV (Resolve)  sau  GDC QuickTime / GDC MP4 / GDC Matroska\n      ↓\n  Fișier final"),
    .h2("3.2 Ce primește pluginul de la Resolve"),
    .p("Resolve trimite imaginea ca **planuri YUV**. La 8 biți, fiecare eșantion ocupă un octet. La 10 biți, Resolve livrează fiecare eșantion într-un container de **16 biți**, cu valoarea deplasată cu 6 biți (adică pe scala completă de 16 biți). Pluginul convertește la 10 biți cu **rotunjire** și limitare la 1023, deci nu introduce pierderi în afara celor inerente codecului."),
    .note(.info, "Nu trebuie să faci nimic pentru asta: conversia este automată. E util de știut doar dacă analizezi fișierele cu unelte externe și vrei să înțelegi de ce valorile de intrare sunt pe 16 biți."),
    .h2("3.3 Encoderii"),
    .table(headers: ["Encoder", "Tip", "Puncte forte", "Puncte slabe"], rows: [
        ["x264 (H.264)", "Software", "Calitate excelentă la bitrate mic, control foarte fin, compatibilitate maximă", "Mai lent decât hardware; H.264 pe 10 biți/4:2:2 nu e redat de multe televizoare"],
        ["x265 (H.265/HEVC)", "Software", "Fișiere mai mici la aceeași calitate, 10 biți și HDR, 4K", "Cel mai lent; unele platforme/dispozitive mai vechi nu îl redau"],
        ["Apple VideoToolbox", "Hardware (Mac)", "Foarte rapid, potrivit pentru previzualizări", "Calitate mai slabă la același bitrate decât x264/x265; doar 8 biți, 4:2:0"],
        ["NVIDIA NVENC", "Hardware (Windows)", "Foarte rapid pe GPU NVIDIA", "Ca mai sus; disponibil doar cu GPU NVIDIA"],
    ], widths: [0.19, 0.14, 0.34, 0.33]),
    .h2("3.4 Etichetarea culorii"),
    .p("Fiecare fișier conține, pe lângă imagine, **etichete** care spun playerului în ce spațiu de culoare a fost codată (primare, funcție de transfer, matrice). Pluginul le citește din setările proiectului Resolve (Output Color Space) și le scrie în fișier. Dacă Resolve nu trimite nicio valoare sau trimite una necunoscută, se folosește **Rec.709**: pluginul nu ghicește spațiul de culoare din adâncimea de biți."),
    .table(headers: ["Output Color Space în Resolve", "Primare", "Transfer", "Matrice"], rows: [
        ["Rec.709 (Scene)", "Rec.709 (1)", "Rec.709 (1)", "Rec.709 (1)"],
        ["Rec.2100 ST2084 (PQ)", "Rec.2020 (9)", "SMPTE ST 2084 / PQ (16)", "Rec.2020 nc (9)"],
        ["Rec.2100 HLG", "Rec.2020 (9)", "ARIB STD-B67 / HLG (18)", "Rec.2020 nc (9)"],
        ["P3-D65", "SMPTE EG 432 / P3-D65 (12)", "SMPTE ST 428 (17)", "Rec.709 (1)"],
        ["P3-DCI", "SMPTE RP 431 / P3-DCI (11)", "SMPTE ST 428 (17)", "Rec.709 (1)"],
    ], widths: [0.32, 0.24, 0.26, 0.18]),
    .note(.info, "Tabelul reflectă ce trimite Resolve 21.1 și ce scrie pluginul (valorile din paranteze sunt codurile standard CICP). Pentru HLG, eticheta de transfer este scrisă, dar nu există metadata statică de tip HDR10."),
    .h2("3.5 Containerele"),
    .p("Există două familii de formate în lista Format din Deliver:"),
    .bullets([
        "**Formatele lui Resolve** (QuickTime, MP4, MKV): Resolve împachetează fișierul și se ocupă de tot sunetul (PCM, AAC etc.). Codecurile GDC apar aici ca alegere de codec. Containerul Resolve **nu scrie** metadata HDR10 în container; ea rămâne în fluxul video.",
        "**Formatele GDC** (GDC QuickTime, GDC MP4, GDC Matroska): pluginul împachetează fișierul. Scrie etichetele de culoare, **mastering display** și **MaxCLL/MaxFALL** direct în container, iar sunetul este **PCM** necomprimat.",
    ]),
    .h2("3.6 Licențierea"),
    .p("Pluginul necesită un **cod de activare** legat de **Machine ID**-ul calculatorului (afișat în panoul plugin-ului). Codul se introduce o singură dată; după activare, câmpul dispare din panou. Verificarea se face local, fără conexiune la internet. Activarea se obține prin susținerea proiectului printr-o donație. Fără licență activă, exportul nu pornește."),
] }

// ─────────────────────────── 4. Ce face / nu face ───────────────────────────
private func ch4() -> [Block] { [
    .h1("4. Ce face și ce nu face"),
    .h2("4.1 Ce face"),
    .table(headers: ["Capacitate", "Detalii"], rows: [
        ["Codare H.264 și H.265", "x264 și x265 la 8 și 10 biți; 4:2:0 (8/10 biți) și 4:2:2 (10 biți)"],
        ["Controlul calității", "CRF, bitrate țintă, QP constant; preset, level, tune, interval de keyframe"],
        ["Parametri expert", "Șir liber de opțiuni x264/x265 (de exemplu aq-mode, psy-rd, vbv-maxrate)"],
        ["Etichete de culoare", "Rec.709, Rec.2020, P3-D65, P3-DCI; SDR, PQ, HLG; Video sau Full range"],
        ["HDR10 static", "Mastering display (P3-D65 sau Rec.2020, luminanță de vârf), MaxCLL, MaxFALL"],
        ["Formate proprii", "GDC QuickTime, GDC MP4, GDC Matroska, cu HDR în container"],
        ["Sunet", "În formatele GDC: PCM 16/24/32 biți, scris neschimbat (testat cu ton de 1 kHz)"],
        ["Hardware", "VideoToolbox (Mac) și NVENC (Windows, GPU NVIDIA) pentru previzualizări rapide"],
        ["Compatibilitate", "Codecurile rămân disponibile și în QuickTime, MP4 și MKV ale lui Resolve"],
    ], widths: [0.26, 0.74]),
    .h2("4.2 Ce nu face"),
    .table(headers: ["Nu face", "Ce faci în schimb"], rows: [
        ["ProRes, DNxHR/DNxHD, XDCAM, DCP, EXR, DPX", "Folosește codecurile native ale lui Resolve"],
        ["4:4:4; 4:2:2 la 8 biți", "4:2:2 există doar pe 10 biți; pentru 4:4:4 folosește ProRes 4444 sau alt codec nativ"],
        ["Codare în două treceri (2-pass)", "Folosește CRF sau bitrate țintă cu VBV (vezi capitolul 11)"],
        ["HDR10+ și Dolby Vision", "Pluginul scrie doar HDR10 static; HLG este doar etichetat"],
        ["AAC / AC-3 în formatele GDC", "În formatele GDC sunetul e PCM; pentru AAC folosește MP4 sau QuickTime din Resolve cu codec GDC"],
        ["Timecode de start și markere în formatele GDC", "Nu sunt scrise încă; în formatele Resolve rămân cele ale lui Resolve"],
        ["AV1 și VP9", "Nu sunt incluse"],
        ["Conversie de spațiu de culoare", "Color management-ul îl face Resolve; pluginul doar etichetează"],
        ["CBR strict din panou", "Se poate aproxima cu vbv-maxrate/vbv-bufsize în parametri avansați"],
        ["Linux și Mac Intel", "Nu sunt ținte ale acestei versiuni"],
    ], widths: [0.42, 0.58]),
] }

// ─────────────────────────── 5. Avantaje / dezavantaje ───────────────────────────
private func ch5() -> [Block] { [
    .h1("5. Avantaje și dezavantaje"),
    .h2("5.1 Avantaje"),
    .bullets([
        "**Raport calitate/dimensiune superior encoderelor hardware**: x264 și x265 produc fișiere mai mici la aceeași calitate vizuală.",
        "**10 biți și 4:2:2**: mai puțină bandă în degradeuri, crominanță mai curată pe grafică și text colorat.",
        "**HDR10 complet**: etichete + mastering display + MaxCLL/MaxFALL, inclusiv în container (formatele GDC).",
        "**Control granular** fără a părăsi Resolve: preset, level, tune, VBV, parametri expert.",
        "**Fără instalări suplimentare**: FFmpeg și bibliotecile vin în pachet.",
        "**Compatibil** cu fluxul existent: codecurile funcționează și în formatele native ale lui Resolve.",
        "**Reproductibil**: aceleași setări dau același rezultat, util pentru livrări repetate.",
    ]),
    .h2("5.2 Dezavantaje și limite"),
    .bullets([
        "**Viteză**: x265 și presetările lente (slower, veryslow) durează mult; hardware-ul e rapid, dar mai slab la calitate.",
        "**Sunet**: în formatele GDC doar PCM; în MP4 PCM are suport slab în unele playere.",
        "**Compatibilitatea redării**: H.264 pe 10 biți și 4:2:2 nu sunt redate de multe televizoare și telefoane; H.265 nu e acceptat peste tot.",
        "**Fără timecode și markere** în formatele GDC.",
        "**Necesită Resolve Studio** și licență activată.",
        "**Nu acoperă** livrările care cer ProRes, DNxHR, XDCAM sau DCP; acestea rămân la codecurile native.",
    ]),
    .h2("5.3 Când să NU folosești pluginul"),
    .bullets([
        "Când destinația cere un codec specific de broadcast sau cinema (ProRes, DNxHR, XDCAM, DCP, DPX/EXR).",
        "Când ai nevoie de timecode de start și markere în fișierul exportat, dar vrei formatul GDC: folosește formatul Resolve.",
        "Când destinația cere AAC obligatoriu și vrei metadata HDR în container: acum nu se pot avea ambele într-un singur fișier.",
        "Când ai nevoie de Dolby Vision sau HDR10+.",
    ]),
] }

// ─────────────────────────── 6. Variante de codec ───────────────────────────
private func ch6() -> [Block] { [
    .h1("6. Variantele de codec"),
    .p("În Deliver, la Codec alegi **GDC Encoder**, apoi la **Type** una dintre variantele de mai jos (în formatele GDC ale pluginului, aceleași variante apar direct la codec). Variantele hardware apar doar dacă mașina are encoderul respectiv."),
    .table(headers: ["Variantă (Type)", "Biți", "Croma", "Profil", "Recomandat pentru"], rows: [
        ["GDC H.264 (Software x264)", "8", "4:2:0", "Baseline / Main / High (High implicit)", "Web, social, televizoare, compatibilitate maximă"],
        ["GDC H.265 (Software x265)", "8", "4:2:0", "Main", "SDR 4K, fișiere mici"],
        ["GDC H.264 (Apple VideoToolbox)", "8", "4:2:0", "—", "Previzualizări rapide pe Mac"],
        ["GDC H.265 (Apple VideoToolbox)", "8", "4:2:0", "—", "Previzualizări rapide pe Mac"],
        ["GDC H.264 (NVIDIA NVENC)", "8", "4:2:0", "—", "Previzualizări rapide pe Windows cu NVIDIA"],
        ["GDC H.265 (NVIDIA NVENC)", "8", "4:2:0", "—", "Previzualizări rapide pe Windows cu NVIDIA"],
        ["GDC H.264 10-bit (Software x264 High10)", "10", "4:2:0", "High 10", "SDR 10-bit fără bandă; redare limitată pe TV/telefon"],
        ["GDC H.265 10-bit (Software x265 Main10)", "10", "4:2:0", "Main 10", "HDR10, HLG, 4K, livrări moderne"],
        ["GDC H.264 4:2:2 10-bit (Software x264 High 4:2:2)", "10", "4:2:2", "High 4:2:2", "Mastere ușoare, livrări de post-producție"],
        ["GDC H.265 4:2:2 10-bit (Software x265 Main 4:2:2 10)", "10", "4:2:2", "Main 4:2:2 10 (Rext)", "Mastere HDR 4:2:2, grafică cu text colorat"],
    ], widths: [0.34, 0.06, 0.08, 0.22, 0.30]),
    .note(.warn, "Variantele pe 10 biți și 4:2:2 sunt destinate post-producției și platformelor moderne. Multe televizoare, telefoane și playere hardware nu decodează H.264 10-bit sau 4:2:2. Pentru redare pe televizor folosește 8 biți 4:2:0 (SDR) sau H.265 Main10 4:2:0 (HDR)."),
] }

// ─────────────────────────── 7. Referință setări ───────────────────────────
private func ch7a() -> [Block] { [
    .h1("7. Referința completă a setărilor"),
    .p("Setările din panoul plugin-ului („Plugin Settings”) apar sub selecția codecului. Cele marcate „doar software” nu apar pentru variantele hardware."),
    .h2("7.1 Preset (doar software)"),
    .p("Presetul alege **cât efort** depune encoderul pentru a comprima eficient. Un preset mai lent produce, la același CRF, un fișier mai mic sau o calitate mai bună, dar durează mai mult. Nu schimbă „ce fel” de imagine obții, ci cât de bine e comprimată."),
    .table(headers: ["Preset", "Viteză", "Eficiență", "Când"], rows: [
        ["ultrafast", "Maximă", "Foarte slabă (fișiere mari)", "Teste, previzualizări de urgență"],
        ["superfast", "Foarte mare", "Slabă", "Revizuire rapidă"],
        ["veryfast", "Mare", "Medie-slabă", "Dailies, copii de lucru"],
        ["faster", "Bună", "Medie", "Copii de lucru cu calitate ok"],
        ["fast", "Bună", "Medie-bună", "Livrări rapide"],
        ["**medium** (implicit)", "Echilibrat", "Bună", "Uz general"],
        ["slow", "Mai lent", "Foarte bună", "**Livrare finală recomandată**"],
        ["slower", "Lent", "Excelentă", "Livrare finală, când ai timp"],
        ["veryslow", "Foarte lent", "Maximă", "Câștig mic peste „slower”; rar justificat"],
    ], widths: [0.20, 0.16, 0.26, 0.38]),
    .note(.tip, "Regula practică: alege **slow** pentru livrare finală și **veryfast** pentru revizuire. Diferența dintre slower și veryslow e de obicei mică față de timpul suplimentar."),
    .h2("7.2 Profile (doar software, H.264 8-bit)"),
    .table(headers: ["Profil", "Ce înseamnă", "Când"], rows: [
        ["baseline", "Set restrâns de unelte, fără B-frames; calitate mai slabă la bitrate egal", "Doar dispozitive foarte vechi"],
        ["main", "Compatibilitate largă, mai puține unelte decât High", "Playere mai vechi care nu acceptă High"],
        ["**high** (implicit)", "Setul complet pentru 8 biți; cea mai bună eficiență", "Aproape orice destinație modernă"],
    ], widths: [0.20, 0.50, 0.30]),
    .p("Pentru H.265, pe 10 biți și pe 4:2:2 profilul este ales automat de encoder (Main, Main 10, Main 4:2:2 10, High 10, High 4:2:2)."),
    .h2("7.3 Level (doar software)"),
    .p("Level-ul limitează rezoluția, rata de cadre și bitrate-ul maxim ca fișierul să poată fi redat de anumite dispozitive. **Auto** (implicit) lasă encoderul să aleagă în funcție de rezoluție; e potrivit în majoritatea cazurilor. Îl fixezi doar când un dispozitiv anume cere un level maxim."),
    .table(headers: ["Level", "H.264: potrivit pentru", "H.265: potrivit pentru"], rows: [
        ["3.0 / 3.1", "SD și 720p", "720p"],
        ["4.0 / 4.1", "1080p până la 30 fps", "1080p până la 30 fps (4.0), 1080p60 (4.1)"],
        ["4.2", "1080p60", "1080p60 și peste"],
        ["5.0", "Rezoluții mari, cadre reduse", "**4K până la 30 fps**"],
        ["5.1", "**4K până la 30 fps**", "**4K până la 60 fps**"],
        ["5.2", "**4K până la 60 fps**", "4K până la 120 fps"],
    ], widths: [0.14, 0.43, 0.43]),
    .note(.info, "Un level prea mic pentru rezoluția aleasă face ca encoderul să refuze combinația sau să limiteze bitrate-ul. Un level prea mare nu strică, dar poate face fișierul nedecodabil pe dispozitive care se opresc la un level mai mic."),
    .h2("7.4 Tune (doar software)"),
    .p("Tune-ul optimizează encoderul pentru un anumit tip de conținut. „none” (implicit) e bun în majoritatea cazurilor."),
    .table(headers: ["Tune", "Ce face", "Când", "Disponibil"], rows: [
        ["none", "Fără optimizare specială", "Uz general", "H.264, H.265"],
        ["film", "Păstrează detaliile fine la conținut filmat, bitrate mare", "Filme, conținut cu textură fină", "Doar H.264"],
        ["animation", "Optimizat pentru zone plate, contururi clare", "Animație, grafică, desene", "H.264, H.265"],
        ["grain", "Păstrează structura granulației, o menține uniformă", "Material cu grăunte de film", "H.264, H.265"],
        ["stillimage", "Optimizat pentru imagini aproape statice", "Prezentări, slideshow", "Doar H.264"],
        ["psnr / ssim", "Optimizează metrici obiective, nu aspectul", "Comparații tehnice, nu livrare", "H.264, H.265"],
        ["fastdecode", "Simplifică fluxul ca să se decodeze ușor", "Dispozitive slabe; scade eficiența compresiei", "H.264, H.265"],
        ["zerolatency", "Fără întârziere de codare (fără cadre B/lookahead)", "Streaming live; nu pentru fișiere de livrare", "H.264, H.265"],
    ], widths: [0.14, 0.34, 0.34, 0.18]),
    .note(.warn, "fastdecode și zerolatency reduc eficiența compresiei: aceeași calitate cere un fișier mai mare. Nu le folosi pentru livrări obișnuite."),
] }

private func ch7b() -> [Block] { [
    .h2("7.5 Rate Control: cum alegi calitatea"),
    .p("Ai trei moduri. Alegerea determină dacă controlezi **calitatea** sau **dimensiunea**."),
    .table(headers: ["Mod", "Ce controlezi", "Avantaj", "Dezavantaj", "Când"], rows: [
        ["**Constant Quality (CRF)** (implicit)", "Calitatea: număr 0–51, mai mic = mai bun", "Calitate constantă pe tot filmul; cel mai eficient", "Dimensiunea finală nu e cunoscută dinainte", "Aproape oricând"],
        ["**Target Bitrate**", "Dimensiunea: kbps (500–100000)", "Dimensiune previzibilă", "Calitate variabilă: scene grele pot ieși slabe", "Când platforma cere un bitrate; hardware"],
        ["**Constant QP**", "Cuantizarea fiecărui cadru", "Comportament predictibil, fără adaptare", "Ineficient; fișiere mari", "Teste, analize, cazuri speciale"],
    ], widths: [0.19, 0.20, 0.22, 0.21, 0.18]),
    .note(.tip, "Regula: dacă nu ai o cerință de bitrate, folosește **CRF**. Dacă platforma impune un plafon, folosește CRF **plus** un plafon VBV (vezi capitolul 11)."),
    .note(.info, "Variantele hardware (VideoToolbox, NVENC) nu au CRF nativ: dacă alegi CRF, pluginul folosește un bitrate implicit de aproximativ 12 Mbps. Pentru hardware alege **Target Bitrate**."),
    .h2("7.6 Quality (CRF): valori recomandate"),
    .p("Valorile de mai jos sunt **puncte de plecare** pentru conținut filmat obișnuit; conținutul foarte detaliat sau cu grăunte cere un CRF mai mic. x265 folosește o scară puțin diferită: pentru aceeași calitate vizuală, CRF-ul x265 este de obicei cu **3–5 unități mai mare** decât cel x264 (regulă empirică)."),
    .table(headers: ["Scop", "x264 (H.264)", "x265 (H.265)", "Observații"], rows: [
        ["Master / arhivă ușoară", "14–16", "16–18", "Fișiere mari; 10 biți recomandat"],
        ["Livrare de calitate înaltă", "17–19", "19–22", "Client exigent, festivaluri"],
        ["Livrare standard (YouTube, Vimeo)", "18–21", "21–24", "Platforma recomprimă; păstrează marjă"],
        ["Social (Instagram, TikTok, Facebook)", "20–23", "23–26", "Platforma recomprimă puternic"],
        ["Revizuire / proxy", "24–28", "27–30", "Dimensiune mică, calitate suficientă"],
        ["Fișier foarte mic", "26–30", "28–32", "Pierderi vizibile pe detalii"],
    ], widths: [0.30, 0.16, 0.16, 0.38]),
    .h2("7.7 Bit Rate (Target Bitrate)"),
    .p("Slider între **500 și 100000 kbps**, în pași de 100. Valorile de mai jos sunt orientative pentru H.264 SDR; pentru H.265 poți folosi aproximativ **60–70%** din aceste valori la calitate comparabilă (regulă empirică)."),
    .table(headers: ["Rezoluție / rată de cadre", "H.264 SDR", "H.265 / HDR (indicativ)"], rows: [
        ["720p 24–30", "5–7,5 Mbps", "4–6 Mbps"],
        ["1080p 24–30", "8–12 Mbps", "6–9 Mbps"],
        ["1080p 48–60", "12–18 Mbps", "9–13 Mbps"],
        ["1440p 24–30", "16 Mbps", "12 Mbps"],
        ["4K 24–30", "35–45 Mbps", "25–35 Mbps (HDR: 44–56 Mbps recomandat de unele platforme)"],
        ["4K 48–60", "53–68 Mbps", "40–50 Mbps (HDR: 66–85 Mbps recomandat de unele platforme)"],
    ], widths: [0.34, 0.24, 0.42]),
    .h2("7.8 Keyframe Interval (sec)"),
    .p("Distanța dintre două cadre cheie (imagini complete), între **1 și 10 secunde**, implicit **2 secunde**. Pluginul o convertește în cadre folosind rata reală a proiectului. Un interval scurt înseamnă derulare rapidă și recuperare bună la erori, dar fișier puțin mai mare; unul lung înseamnă fișier puțin mai mic, dar derulare mai lentă."),
    .table(headers: ["Scop", "Valoare"], rows: [
        ["Streaming / web (implicit)", "2 secunde"],
        ["Social, platforme care recomprimă", "1–2 secunde"],
        ["Livrări de post-producție, editare ulterioară", "1 secundă"],
        ["Fișier mic pentru arhivă de vizionare", "4–5 secunde"],
    ], widths: [0.62, 0.38]),
    .p("Numărul de cadre B este fixat la **2**; nu se schimbă din panou."),
    .h2("7.9 Advanced Params (x264/x265)"),
    .p("Câmp de text în care scrii opțiuni brute pentru encoder, sub forma `cheie=valoare:cheie=valoare` (de exemplu `aq-mode=3:psy-rd=1.0,0.15`). Sunt trimise direct către x264 sau x265, în funcție de varianta aleasă. Detalii și exemple în capitolul 11."),
    .note(.warn, "Un șir invalid face ca encoderul să refuze pornirea exportului. Dacă exportul nu pornește după ce ai completat câmpul, golește-l și reia. Opțiunile pe care le scrii aici au prioritate față de cele din panou (inclusiv HDR10)."),
    .h2("7.10 HDR10 Metadata (doar software)"),
    .p("Grupul de setări care scrie metadata statică HDR10. Este **oprit** implicit. Se aplică numai când exportul este **PQ** (Output Color Space: Rec.2100 ST2084)."),
    .table(headers: ["Setare", "Valori", "Ce înseamnă"], rows: [
        ["HDR10 Metadata", "Off / On (PQ exports only)", "Off: nu se scrie nimic. On: se scriu datele de mai jos, doar dacă exportul e PQ."],
        ["Mastering Primaries", "P3-D65 / Rec.2020", "Gama **monitorului pe care ai etalonat** (nu spațiul imaginii). P3-D65 e cazul obișnuit."],
        ["Mastering Peak", "100–10000 nits (implicit 1000)", "Luminanța maximă a monitorului de mastering."],
        ["MaxCLL", "0–10000 nits (0 = nesemnalat)", "Cel mai luminos pixel din tot filmul."],
        ["MaxFALL", "0–4000 nits (0 = nesemnalat)", "Cea mai mare luminanță medie a unui cadru din tot filmul."],
    ], widths: [0.20, 0.30, 0.50]),
    .p("Luminanța minimă a display-ului de mastering este fixată la 0,005 nits. Mai multe despre HDR în capitolul 8."),
    .h2("7.11 Setările Resolve care influențează exportul"),
    .table(headers: ["Setare Resolve", "Recomandare", "De ce"], rows: [
        ["Output Color Space (Color Management)", "Rec.709 pentru SDR; Rec.2100 ST2084 pentru HDR10; Rec.2100 HLG pentru HLG", "De aici vin etichetele de culoare scrise în fișier"],
        ["Data Levels (Advanced Settings)", "**Video** pentru aproape orice livrare", "Full-range face ca unele playere să afișeze imaginea spălată sau prea contrastată"],
        ["Color Space Tag / Gamma Tag", "Same as project", "Lasă etichetarea să urmeze proiectul"],
        ["Retain sub-black and super-white data", "Debifat pentru livrare", "Doar pentru fluxuri intermediare"],
        ["Resolution", "Lățime și înălțime **pare**", "Dimensiunile impare sunt refuzate de plugin"],
        ["Frame rate", "Cea a timeline-ului", "Schimbarea ratei la export produce sacadare"],
        ["Export Audio", "Bifat, sau debifat dacă lucrezi separat", "Formatele GDC scriu PCM"],
    ], widths: [0.31, 0.37, 0.32]),
    .h2("7.12 Comportamente fixe"),
    .bullets([
        "Cadre B: 2. Encoderul folosește automat numărul de fire de execuție potrivit procesorului (până la 32).",
        "Codarea nu ține în memorie tot fișierul: cadrele sunt codate pe rând, deci consumul de memorie e stabil chiar la exporturi lungi.",
        "Variantele hardware NVENC încearcă de până la 3 ori să pornească, deoarece sesiunea GPU poate fi ocupată temporar.",
    ]),
] }

// ─────────────────────────── 8. Culoare și HDR ───────────────────────────
private func ch8() -> [Block] { [
    .h1("8. Culoare și HDR în detaliu"),
    .h2("8.1 SDR: Rec.709, gama 2.4"),
    .p("Livrarea standard pentru web și televiziune SDR: primare Rec.709, transfer Rec.709/BT.1886 (gama 2.4 pe un monitor calibrat), interval de nivele **Video** (16–235 pe 8 biți). În Resolve, Output Color Space: Rec.709. Pluginul scrie etichetele 1/1/1 și nu adaugă metadata HDR."),
    .h2("8.2 HDR10 (PQ)"),
    .p("HDR10 folosește funcția de transfer **PQ (SMPTE ST 2084)** și primarele **Rec.2020**, pe **10 biți**, cu metadata statică (mastering display, MaxCLL, MaxFALL). Este formatul HDR acceptat de majoritatea televizoarelor și platformelor."),
    .bullets([
        "Output Color Space: **Rec.2100 ST2084**.",
        "Codec: variantă H.265 **10-bit** (Main10) sau 4:2:2 10-bit.",
        "HDR10 Metadata: **On**, cu monitorul de mastering real.",
        "Format: **GDC MP4**, **GDC QuickTime** sau **GDC Matroska**, pentru ca metadata să ajungă și în container.",
    ]),
    .h2("8.3 HLG"),
    .p("HLG (Hybrid Log-Gamma) e folosit mai ales în televiziune, deoarece se vede rezonabil și pe ecrane SDR. Se exportă cu Output Color Space **Rec.2100 HLG**; pluginul scrie eticheta de transfer HLG. HLG **nu folosește** metadata statică HDR10, deci setează **HDR10 Metadata: Off**."),
    .h2("8.4 P3-D65 și P3-DCI"),
    .p("Dacă lucrezi în P3-D65 (de exemplu pentru livrări Apple sau pentru ecrane P3) sau în P3-DCI (cinema digital), Output Color Space corespunzător face ca pluginul să scrie primarele P3 în flux și în container. Verifică dacă platforma de destinație interpretează corect P3; multe platforme web așteaptă Rec.709 sau Rec.2020."),
    .h2("8.5 Mastering display vs spațiul imaginii"),
    .p("Sunt două lucruri diferite, frecvent confundate:"),
    .table(headers: ["", "Spațiul imaginii", "Mastering display"], rows: [
        ["Ce descrie", "Cum sunt codați pixelii (ex. Rec.2020 + PQ)", "Monitorul pe care ai etalonat"],
        ["De unde vine", "Din Output Color Space din Resolve", "Din panoul plugin-ului (Mastering Primaries, Mastering Peak)"],
        ["Cine îl folosește", "Playerul, la decodare și afișare", "Televizorul, la tone mapping"],
        ["Schimbă pixelii?", "Da (definește interpretarea lor)", "Nu; doar informează televizorul"],
    ], widths: [0.20, 0.40, 0.40]),
    .p("Exemplu obișnuit: imaginea este în container Rec.2020/PQ, iar mastering display-ul este **P3-D65** cu vârf de **1000 nits**, deoarece ai etalonat pe un monitor P3 care ajunge la 1000 nits. Alege **Rec.2020** la Mastering Primaries doar dacă monitorul tău acoperă aproape toată gama Rec.2020 (rar)."),
    .h2("8.6 MaxCLL și MaxFALL"),
    .bullets([
        "**MaxCLL** (Maximum Content Light Level): luminanța celui mai luminos pixel din întreg filmul, în nits.",
        "**MaxFALL** (Maximum Frame-Average Light Level): cea mai mare luminanță medie a unui cadru din întreg filmul, în nits.",
    ]),
    .p("Valorile corecte se **măsoară** pe conținutul final. Dacă nu le-ai măsurat, lasă **0** (nesemnalat), care este mai corect decât o valoare inventată: un MaxCLL prea mic sau prea mare poate face tone mapping-ul televizorului să se comporte prost."),
    .note(.warn, "Valorile din exemplele acestui document (1000 și 400) sunt doar ilustrative. Nu le copia în livrări reale fără să le măsori."),
    .h2("8.7 Exemplu: etalonare pe ecranul unui laptop cu profil HDR"),
    .p("Dacă etalonezi pe ecranul intern al unui laptop Apple cu profil HDR activ, ecranul lucrează în P3 cu PQ. Setări prudente: **Mastering Primaries: P3-D65**, **Mastering Peak: 1000**, MaxCLL/MaxFALL măsurate sau 0. Un ecran de laptop nu este un monitor de referință HDR: pentru livrări cu cerințe stricte, verifică și pe un televizor HDR. Un monitor extern SDR calibrat în Rec.709 nu poate evalua HDR-ul; versiunea SDR se verifică separat."),
    .h2("8.8 Ce metadata HDR nu este suportată"),
    .bullets([
        "**HDR10+** (metadata dinamică) și **Dolby Vision**: nu sunt scrise de plugin.",
        "**HLG** este etichetat, dar nu are metadata statică suplimentară.",
    ]),
] }

// ─────────────────────────── 9. Containere și sunet ───────────────────────────
private func ch9() -> [Block] { [
    .h1("9. Containere și sunet"),
    .h2("9.1 Formatele Resolve vs. formatele GDC"),
    .table(headers: ["", "Formatele Resolve (QuickTime / MP4 / MKV)", "Formatele GDC (GDC QuickTime / MP4 / Matroska)"], rows: [
        ["Cine împachetează", "Resolve", "Pluginul (prin FFmpeg)"],
        ["Sunet", "Orice codec oferit de Resolve (PCM, AAC etc.)", "PCM 16/24/32 biți, scris neschimbat"],
        ["Metadata HDR10 în container", "Nu", "Da: mastering display și MaxCLL/MaxFALL"],
        ["Etichete de culoare în container", "Da, scrise de Resolve", "Da, scrise de plugin"],
        ["Timecode de start / markere", "Da", "Nu (încă)"],
        ["Cum apare în Deliver", "Format = QuickTime/MP4/MKV, apoi Codec = GDC Encoder, apoi Type", "Format = GDC ..., apoi Type (direct)"],
    ], widths: [0.24, 0.38, 0.38]),
    .p("Formatele GDC apar în lista **Format** după formatele native ale lui Resolve, alături de alte formate din plugin-uri; poziția lor în listă nu se poate schimba."),
    .h2("9.2 Sunetul"),
    .p("În formatele GDC, Resolve trimite sunetul necomprimat (PCM) iar pluginul îl scrie neschimbat. Aceasta e alegerea profesională pentru mastere și livrări de post-producție. Pentru destinații care cer AAC, folosește formatul MP4 sau QuickTime din Resolve, cu codec video GDC."),
    .table(headers: ["Container", "Sunet PCM", "Observație"], rows: [
        ["GDC QuickTime (.mov)", "Bun", "Standard în post-producție"],
        ["GDC Matroska (.mkv)", "Foarte bun", "Suport larg pentru PCM"],
        ["GDC MP4 (.mp4)", "Limitat", "PCM în MP4 (ipcm) e redat prost de unele playere (ex. QuickTime/Safari)"],
    ], widths: [0.28, 0.20, 0.52]),
    .note(.info, "Dacă nu ai nevoie de sunet în fișier, debifează „Export Audio” în Deliver; containerul nu va mai primi pistă audio."),
    .h2("9.3 Ce combinații să alegi"),
    .table(headers: ["Scop", "Format", "De ce"], rows: [
        ["HDR10 cu metadata în fișier + sunet PCM", "GDC QuickTime sau GDC Matroska", "Metadata în container; PCM bine suportat"],
        ["HDR10 pentru playere care cer MP4", "GDC MP4", "Metadata în container; verifică redarea sunetului"],
        ["SDR cu AAC pentru web/social", "MP4 din Resolve + codec GDC", "AAC compatibil peste tot"],
        ["Livrare care cere timecode/markere", "Formatul Resolve + codec GDC", "Le scrie Resolve"],
    ], widths: [0.38, 0.30, 0.32]),
] }
