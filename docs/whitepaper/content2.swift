import Foundation

// Partea a doua: rețete de export, parametri avansați, alegere rapidă, depanare, limite, anexe.

// ─────────────────────────── 10. Rețete: introducere + YouTube ───────────────────────────
func ch10a() -> [Block] {
    var b: [Block] = [
        .h1("10. Rețete de export"),
        .p("Fiecare rețetă listează setările din panoul plugin-ului și din Resolve. Valorile sunt **puncte de plecare**: testează pe un clip scurt de 10–20 secunde, verifică rezultatul pe dispozitivul țintă, apoi exportă filmul. Platformele își schimbă periodic recomandările; verifică specificațiile lor curente înainte de o livrare importantă."),
        .h2("10.1 Cum se citesc rețetele"),
        .bullets([
            "**Format** = lista Format din Deliver. „MP4 (Resolve)” înseamnă formatul nativ; „GDC MP4” înseamnă formatul propriu al pluginului.",
            "**Codec (Type)** = varianta aleasă în panoul plugin-ului.",
            "**În Resolve** = setările din Deliver și Color Management care afectează fișierul.",
            "Dacă un rând lipsește dintr-o rețetă, lasă valoarea implicită.",
        ]),
        .note(.tip, "Pentru orice destinație, exportă întâi un fragment din partea cea mai grea a filmului (mișcare rapidă, degradeuri, întuneric). Dacă acolo arată bine, restul va arăta bine."),
        .h2("10.2 YouTube"),
        .p("YouTube recomprimă tot ce încarci. Scopul este să încarci un fișier de **calitate înaltă**, ca recomprimarea să pornească de la o sursă curată. Valorile de bitrate de mai jos sunt cele recomandate public de YouTube la data redactării, ca ordin de mărime."),
    ]
    b += recipe("YouTube SDR, 1080p (24–30 fps)", [
        ["Format", "MP4 (Resolve) sau QuickTime (Resolve), cu sunet AAC 320 kbps sau PCM"],
        ["Codec (Type)", "GDC H.264 (Software x264)"],
        ["Preset", "slow"],
        ["Profile / Level", "High / Auto (4.2 dacă rata de cadre e 48–60)"],
        ["Tune", "none"],
        ["Rate Control", "Constant Quality, **CRF 18–20** (sau Target Bitrate 12 Mbps)"],
        ["Keyframe Interval", "1–2 secunde"],
        ["HDR10 Metadata", "Off"],
        ["În Resolve", "Output Color Space Rec.709; Data Levels Video; 1920×1080; rata de cadre a timeline-ului"],
        ["De reținut", "Recomandarea YouTube pentru 1080p SDR este de ordinul a 8 Mbps la 24–30 fps și 12 Mbps la 48–60 fps; un CRF 18–20 depășește aceste valori, ceea ce este bine pentru recomprimare."],
    ])
    b += recipe("YouTube SDR, 4K (24–30 fps)", [
        ["Format", "MP4 (Resolve) cu AAC, sau GDC QuickTime cu PCM"],
        ["Codec (Type)", "GDC H.264 (Software x264) sau GDC H.265 (Software x265) pentru fișiere mai mici"],
        ["Preset", "slow"],
        ["Profile / Level", "H.264: High / **5.1** (5.2 la 60 fps). H.265: Main / **5.0** (5.1 la 60 fps)"],
        ["Tune", "none"],
        ["Rate Control", "H.264: **CRF 18–20** (sau 35–45 Mbps). H.265: **CRF 21–23** (sau 25–35 Mbps)"],
        ["Keyframe Interval", "1–2 secunde"],
        ["HDR10 Metadata", "Off"],
        ["În Resolve", "Output Color Space Rec.709; Data Levels Video; 3840×2160"],
        ["De reținut", "H.265 la 4K reduce fișierul cu circa o treime față de H.264 la calitate comparabilă, dar exportul durează mai mult."],
    ])
    b += recipe("YouTube HDR10 (PQ), 4K", [
        ["Format", "**GDC MP4**, **GDC QuickTime** sau **GDC Matroska** (metadata HDR10 ajunge în container)"],
        ["Codec (Type)", "GDC H.265 10-bit (Software x265 Main10)"],
        ["Preset", "slow"],
        ["Profile / Level", "Main 10 (automat) / **5.0** (4K 30 fps) sau **5.1** (4K 60 fps)"],
        ["Tune", "none"],
        ["Rate Control", "**CRF 16–18** (sau Target Bitrate 44–56 Mbps la 4K 24–30 fps, 66–85 Mbps la 48–60 fps)"],
        ["Keyframe Interval", "1–2 secunde"],
        ["HDR10 Metadata", "**On**; Mastering Primaries P3-D65; Mastering Peak = luminanța monitorului tău (1000 tipic); MaxCLL/MaxFALL măsurate, sau 0"],
        ["În Resolve", "Output Color Space **Rec.2100 ST2084**; Data Levels Video; 3840×2160"],
        ["Sunet", "PCM 24-bit 48 kHz în formatele GDC (verifică la încărcare că platforma îl acceptă)"],
        ["De reținut", "YouTube identifică HDR-ul din fișier. Formatele GDC pun metadata și în container, ceea ce este varianta cea mai sigură. Verifică după încărcare că platforma marchează video-ul ca HDR."],
    ])
    b += recipe("YouTube HLG, 4K", [
        ["Format", "GDC MP4 sau GDC QuickTime"],
        ["Codec (Type)", "GDC H.265 10-bit (Software x265 Main10)"],
        ["Preset / Level", "slow / 5.0 (4K 30 fps) sau 5.1 (4K 60 fps)"],
        ["Rate Control", "**CRF 16–18**"],
        ["Keyframe Interval", "1–2 secunde"],
        ["HDR10 Metadata", "**Off** (HLG nu folosește metadata statică)"],
        ["În Resolve", "Output Color Space **Rec.2100 HLG**; Data Levels Video"],
        ["De reținut", "Verifică pe un ecran SDR și pe unul HDR: HLG se vede acceptabil pe ambele."],
    ])
    return b
}

// ─────────────────────────── 10. Social ───────────────────────────
func ch10b() -> [Block] {
    var b: [Block] = [
        .h2("10.3 Facebook, Instagram, TikTok și alte rețele"),
        .p("Rețelele sociale **recomprimă puternic**. Nu are rost să încarci un fișier uriaș: un fișier de calitate bună, în formatul corect de cadru și cu bitrate moderat, se comportă cel mai bine. Folosește **H.264 SDR pe 8 biți**, cea mai sigură alegere. Limitele de dimensiune, durată și rezoluție se schimbă des; verifică-le înainte de încărcare."),
        .table(headers: ["Format de cadru", "Rezoluție", "Unde se folosește"], rows: [
            ["Vertical 9:16", "1080×1920", "Instagram Reels și Stories, TikTok, Facebook Reels, YouTube Shorts"],
            ["Portret 4:5", "1080×1350", "Instagram și Facebook Feed (ocupă mai mult ecran)"],
            ["Pătrat 1:1", "1080×1080", "Feed, cazuri speciale"],
            ["Orizontal 16:9", "1920×1080", "Facebook, YouTube, LinkedIn, X"],
        ], widths: [0.24, 0.20, 0.56]),
    ]
    b += recipe("Instagram Reels / Stories (vertical)", [
        ["Format", "MP4 (Resolve), sunet AAC 128–256 kbps, 48 kHz"],
        ["Codec (Type)", "GDC H.264 (Software x264)"],
        ["Preset", "slow (sau medium pentru viteză)"],
        ["Profile / Level", "High / 4.1 (Auto e suficient)"],
        ["Tune", "none"],
        ["Rate Control", "**CRF 20**; opțional plafon în Advanced Params: `vbv-maxrate=12000:vbv-bufsize=24000`"],
        ["Keyframe Interval", "2 secunde"],
        ["HDR10 Metadata", "Off"],
        ["În Resolve", "Output Color Space Rec.709; Data Levels Video; 1080×1920; 30 fps (sau rata nativă)"],
        ["De reținut", "Păstrează textul și elementele importante în zona centrală; interfața aplicației acoperă marginile de sus și de jos."],
    ])
    b += recipe("Instagram Feed / Facebook Feed (4:5 sau 1:1)", [
        ["Format", "MP4 (Resolve), sunet AAC 128–192 kbps"],
        ["Codec (Type)", "GDC H.264 (Software x264)"],
        ["Preset / Profile / Level", "slow / High / Auto"],
        ["Rate Control", "**CRF 20–22** (sau Target Bitrate 8–10 Mbps la 1080p)"],
        ["Keyframe Interval", "2 secunde"],
        ["În Resolve", "Rec.709; Data Levels Video; 1080×1350 (4:5) sau 1080×1080 (1:1)"],
    ])
    b += recipe("Facebook (video orizontal)", [
        ["Format", "MP4 (Resolve), sunet AAC stereo 128–256 kbps"],
        ["Codec (Type)", "GDC H.264 (Software x264)"],
        ["Preset / Profile / Level", "slow / High / Auto"],
        ["Rate Control", "**CRF 20–22** (sau Target Bitrate 8–12 Mbps la 1080p)"],
        ["Keyframe Interval", "2 secunde"],
        ["În Resolve", "Rec.709; Data Levels Video; 1920×1080; rata de cadre de până la 30 fps recomandată"],
    ])
    b += recipe("TikTok", [
        ["Format", "MP4 (Resolve), sunet AAC 128–192 kbps"],
        ["Codec (Type)", "GDC H.264 (Software x264)"],
        ["Preset / Profile / Level", "slow / High / 4.1"],
        ["Rate Control", "**CRF 20**; alternativ Target Bitrate 8–12 Mbps"],
        ["Keyframe Interval", "2 secunde"],
        ["În Resolve", "Rec.709; Data Levels Video; 1080×1920; 30 fps"],
        ["De reținut", "Suportul pentru HDR la încărcare diferă de la versiune la versiune a aplicației: dacă vrei HDR, testează pe un clip scurt înainte de a livra."],
    ])
    b += recipe("Vimeo", [
        ["Format", "MP4 sau QuickTime (Resolve)"],
        ["Codec (Type)", "GDC H.264 (Software x264)"],
        ["Preset / Profile / Level", "slow / High / Auto"],
        ["Rate Control", "**CRF 17–19** (sau Target Bitrate 10–20 Mbps la 1080p)"],
        ["Keyframe Interval", "2 secunde"],
        ["În Resolve", "Rec.709; Data Levels Video; rezoluția proiectului"],
    ])
    b += recipe("Trimitere rapidă (WhatsApp, Telegram, e-mail)", [
        ["Format", "MP4 (Resolve), sunet AAC 128 kbps"],
        ["Codec (Type)", "GDC H.264 (Software x264)"],
        ["Preset", "fast"],
        ["Rate Control", "**CRF 24–26**"],
        ["Keyframe Interval", "2–4 secunde"],
        ["În Resolve", "Rec.709; Data Levels Video; 1280×720 sau 1920×1080"],
        ["De reținut", "Aplicațiile de mesagerie recomprimă și limitează dimensiunea; un fișier mic ajunge mai repede și pierde mai puțin la recomprimare."],
    ])
    return b
}

// ─────────────────────────── 10. Televizor, broadcast, cinema ───────────────────────────
func ch10c() -> [Block] {
    var b: [Block] = [
        .h2("10.4 Televizor: redare de pe USB, streamer sau Apple TV"),
        .p("La redarea pe televizor contează **decodorul hardware al aparatului**, nu calitatea encoderului. Televizoarele redau aproape universal H.264 8-bit 4:2:0 și, la modelele recente, H.265 Main/Main10 4:2:0. **Nu** redau, în general, H.264 10-bit sau 4:2:2. Regula sigură: pentru televizor rămâi la 4:2:0."),
    ]
    b += recipe("Televizor SDR, 1080p (USB / DLNA)", [
        ["Format", "MP4 (Resolve) cu AAC sau AC-3 (compatibil cu cele mai multe televizoare)"],
        ["Codec (Type)", "GDC H.264 (Software x264), 8 biți"],
        ["Preset / Profile / Level", "slow / High / **4.1** (4.2 la 50/60 fps)"],
        ["Tune", "none"],
        ["Rate Control", "**CRF 17–19** (sau Target Bitrate 15–25 Mbps)"],
        ["Keyframe Interval", "2 secunde"],
        ["În Resolve", "Rec.709; Data Levels Video; 1920×1080"],
        ["De reținut", "Nu folosi 10 biți sau 4:2:2 pentru televizor. Dacă televizorul nu redă sunetul, schimbă la AAC stereo."],
    ])
    b += recipe("Televizor SDR, 4K", [
        ["Format", "MP4 (Resolve) cu AAC"],
        ["Codec (Type)", "GDC H.265 (Software x265), 8 biți (sau GDC H.264 dacă televizorul nu redă H.265)"],
        ["Preset / Level", "slow / **5.0** (30 fps) sau **5.1** (60 fps)"],
        ["Rate Control", "**CRF 20–22** (sau Target Bitrate 30–50 Mbps)"],
        ["Keyframe Interval", "2 secunde"],
        ["În Resolve", "Rec.709; Data Levels Video; 3840×2160"],
    ])
    b += recipe("Televizor HDR10, 4K (USB / streamer)", [
        ["Format", "**GDC Matroska** sau **GDC MP4** (HDR10 în container, redare largă); GDC QuickTime pentru ecosistemul Apple"],
        ["Codec (Type)", "GDC H.265 10-bit (Software x265 Main10), 4:2:0"],
        ["Preset / Level", "slow / **5.1**"],
        ["Tune", "none"],
        ["Rate Control", "**CRF 16–18** (sau Target Bitrate 45–80 Mbps)"],
        ["Keyframe Interval", "2 secunde"],
        ["HDR10 Metadata", "**On**; P3-D65; Peak = monitorul tău; MaxCLL/MaxFALL măsurate sau 0"],
        ["În Resolve", "Output Color Space Rec.2100 ST2084; Data Levels Video"],
        ["Sunet", "PCM în formatele GDC; dacă televizorul nu redă PCM, încearcă GDC Matroska sau folosește un format Resolve cu AAC/AC-3 (metadata rămâne în flux, dar nu în container)"],
        ["De reținut", "Nu folosi 4:2:2 pentru televizor. Verifică pe aparatul real că se activează modul HDR10."],
    ])
    b += recipe("Televizor HLG", [
        ["Format", "GDC MP4 sau GDC Matroska"],
        ["Codec (Type)", "GDC H.265 10-bit (Software x265 Main10)"],
        ["Preset / Level", "slow / 5.1"],
        ["Rate Control", "**CRF 16–18**"],
        ["HDR10 Metadata", "**Off**"],
        ["În Resolve", "Output Color Space Rec.2100 HLG; Data Levels Video"],
    ])
    b += recipe("Apple TV, iPhone, iPad (redare locală)", [
        ["Format", "**GDC QuickTime** sau **GDC MP4** (etichetă hvc1, cerută de ecosistemul Apple)"],
        ["Codec (Type)", "GDC H.265 10-bit (Software x265 Main10) pentru HDR; GDC H.265 (x265) 8 biți pentru SDR"],
        ["Preset / Level", "slow / 5.1 (4K) sau 4.1 (1080p)"],
        ["Rate Control", "**CRF 18–20**"],
        ["HDR10 Metadata", "On pentru HDR10; Off pentru SDR/HLG"],
        ["De reținut", "Evită 4:2:2 pentru redarea pe dispozitive de consum."],
    ])
    b += [
        .h2("10.5 Televiziune (livrare către un post)"),
        .p("Livrările către posturi de televiziune sunt reglementate de un **caiet de sarcini** al fiecărui post. Cele mai frecvente cerințe sunt XDCAM HD422 (MXF), ProRes 422 HQ, DNxHD/DNxHR sau AVC-Intra: codecuri native în Resolve, nu în acest plugin. **Respectă întotdeauna caietul de sarcini al postului.**"),
        .p("Pluginul e potrivit când postul sau platforma cere explicit **H.264 sau H.265**, de exemplu pentru livrări OTT, pentru copii de arhivă de vizionare sau pentru specificații de tip „H.264 High 4:2:2 10-bit”. Loudness-ul (de exemplu EBU R128 sau ATSC A/85) se reglează în Fairlight; pluginul nu îl modifică."),
    ]
    b += recipe("Livrare H.264 4:2:2 10-bit pentru post-producție / OTT", [
        ["Format", "**GDC QuickTime** (sau GDC Matroska)"],
        ["Codec (Type)", "GDC H.264 4:2:2 10-bit (Software x264 High 4:2:2)"],
        ["Preset", "slow"],
        ["Profile / Level", "High 4:2:2 (automat) / 4.1 (1080p 25–30) sau 4.2 (1080p 50–60)"],
        ["Tune", "none"],
        ["Rate Control", "**CRF 12–16** (sau Target Bitrate 50–100 Mbps)"],
        ["Keyframe Interval", "1 secundă"],
        ["HDR10 Metadata", "Off (SDR Rec.709)"],
        ["În Resolve", "Output Color Space Rec.709; Data Levels Video; rezoluția și rata de cadre cerute de specificație"],
        ["Sunet", "PCM 24-bit 48 kHz"],
        ["De reținut", "Verifică în caietul de sarcini profilul exact (multe specificații de broadcast cer un profil intra-only sau parametri fixi, pe care CRF nu îi garantează)."],
    ])
    b += [
        .h2("10.6 Cinematografie, festivaluri, proiecție"),
        .p("Pentru proiecție în sală se folosesc **DCP** (JPEG 2000, spațiu XYZ) și mastere **ProRes 4444 XQ**, **DPX** sau **EXR**, toate native în Resolve. Pluginul **nu** este instrumentul pentru masterul de cinema. Îl folosești pentru fișiere de vizionare și livrare online."),
    ]
    b += recipe("Screener pentru festival / trimitere online (1080p)", [
        ["Format", "MP4 (Resolve) cu AAC sau QuickTime (Resolve)"],
        ["Codec (Type)", "GDC H.264 (Software x264), 8 biți"],
        ["Preset / Profile / Level", "slow / High / 4.1"],
        ["Rate Control", "**CRF 16–18** (sau Target Bitrate 15–25 Mbps)"],
        ["Keyframe Interval", "2 secunde"],
        ["În Resolve", "Rec.709; Data Levels Video; 1920×1080; 24 fps (rata filmului)"],
        ["De reținut", "Multe festivaluri cer H.264 1080p; citește regulamentul înainte de a exporta."],
    ])
    b += recipe("Revizuire HDR pentru client sau colorist (cu HDR10 în fișier)", [
        ["Format", "**GDC QuickTime** sau **GDC MP4**"],
        ["Codec (Type)", "GDC H.265 10-bit (Software x265 Main10)"],
        ["Preset / Level", "medium / 5.1"],
        ["Rate Control", "**CRF 18–20**"],
        ["HDR10 Metadata", "On; monitorul real de mastering; MaxCLL/MaxFALL măsurate sau 0"],
        ["În Resolve", "Rec.2100 ST2084; Data Levels Video"],
    ])
    return b
}

// ─────────────────────────── 10. Master, revizuire, cazuri speciale ───────────────────────────
func ch10d() -> [Block] {
    var b: [Block] = [
        .h2("10.7 Master ușor / arhivă de calitate"),
        .p("Un master H.264/H.265 pe 10 biți este **cu pierderi** chiar la CRF foarte mic. Pentru un master fără pierderi folosește codecurile lossless sau intermediare ale lui Resolve (ProRes, DNxHR, FFV1). Rețetele de mai jos sunt pentru mastere **ușoare**, utile când spațiul contează."),
    ]
    b += recipe("Master ușor 4:2:2 10-bit (SDR)", [
        ["Format", "GDC QuickTime"],
        ["Codec (Type)", "GDC H.264 4:2:2 10-bit (x264) sau GDC H.265 4:2:2 10-bit (x265)"],
        ["Preset", "slower"],
        ["Rate Control", "H.264: **CRF 10–14**. H.265: **CRF 12–16**"],
        ["Keyframe Interval", "1 secundă"],
        ["Tune", "none (grain dacă materialul are grăunte)"],
        ["În Resolve", "Rec.709; Data Levels Video; rezoluția nativă"],
        ["Sunet", "PCM 24-bit 48 kHz"],
    ])
    b += recipe("Master ușor HDR10 4:2:2 10-bit", [
        ["Format", "GDC QuickTime sau GDC Matroska"],
        ["Codec (Type)", "GDC H.265 4:2:2 10-bit (Software x265 Main 4:2:2 10)"],
        ["Preset", "slower"],
        ["Rate Control", "**CRF 12–16**"],
        ["Keyframe Interval", "1 secundă"],
        ["HDR10 Metadata", "On; monitorul real; MaxCLL/MaxFALL măsurate"],
        ["În Resolve", "Rec.2100 ST2084; Data Levels Video"],
        ["De reținut", "4:2:2 nu se redă pe televizoare obișnuite; e pentru post-producție."],
    ])
    b += [ .h2("10.8 Revizuire și dailies") ]
    b += recipe("Copie de revizuire / dailies", [
        ["Format", "MP4 (Resolve), sunet AAC 128 kbps"],
        ["Codec (Type)", "GDC H.264 (Software x264)"],
        ["Preset", "veryfast"],
        ["Rate Control", "**CRF 23–26**"],
        ["Tune", "fastdecode (derulare fluidă pe calculatoare slabe)"],
        ["Keyframe Interval", "1 secundă (derulare rapidă)"],
        ["În Resolve", "Rec.709; 1280×720 sau 1920×1080; timecode inclus prin Data burn-in dacă e nevoie"],
    ])
    b += [ .h2("10.9 Fișier cât mai mic") ]
    b += recipe("Dimensiune minimă la calitate acceptabilă (SDR)", [
        ["Format", "MP4 (Resolve)"],
        ["Codec (Type)", "GDC H.265 (Software x265) 8 biți"],
        ["Preset", "slow"],
        ["Rate Control", "**CRF 27–30**"],
        ["Keyframe Interval", "4–5 secunde"],
        ["Tune", "none"],
        ["De reținut", "H.265 economisește circa o treime față de H.264, dar nu toate dispozitivele îl redau."],
    ])
    b += [ .h2("10.10 Tipuri speciale de conținut") ]
    b += recipe("Animație, grafică, ecran (screen recording)", [
        ["Codec (Type)", "GDC H.264 (x264); pentru text colorat fin: GDC H.264 4:2:2 10-bit"],
        ["Tune", "**animation**"],
        ["Preset", "slow"],
        ["Rate Control", "**CRF 16–18**"],
        ["Keyframe Interval", "2 secunde"],
        ["De reținut", "Textul colorat pe fundal colorat se vede mai curat în 4:2:2; dar rezultatul se vede corect doar pe playere care decodează 4:2:2."],
    ])
    b += recipe("Material cu grăunte de film", [
        ["Codec (Type)", "GDC H.264 (x264) sau GDC H.265 10-bit"],
        ["Tune", "**grain**"],
        ["Preset", "slow"],
        ["Rate Control", "x264: **CRF 18–20**; x265: **CRF 20–22**"],
        ["De reținut", "Grăuntele consumă multă biți; fișierul iese mare. Poți reduce granulația în Resolve înainte de export dacă dimensiunea contează."],
    ])
    b += recipe("Degradeuri fine și scene întunecate (evitarea benzii)", [
        ["Codec (Type)", "Varianta **10-bit** (H.265 Main10 sau H.264 High10), chiar și pentru SDR"],
        ["Preset", "slow"],
        ["Rate Control", "CRF 16–18 (x265) sau 15–17 (x264)"],
        ["Advanced Params", "`aq-mode=3` (favorizează zonele întunecate)"],
        ["De reținut", "10 biți reduce banda vizibil chiar dacă ecranul de redare e de 8 biți; dar verifică compatibilitatea redării."],
    ])
    b += [ .h2("10.11 Previzualizare rapidă cu hardware") ]
    b += recipe("VideoToolbox (Mac) sau NVENC (Windows)", [
        ["Codec (Type)", "GDC H.264 (Apple VideoToolbox) / GDC H.265 (Apple VideoToolbox); pe Windows variantele NVENC"],
        ["Rate Control", "**Target Bitrate** 8–20 Mbps la 1080p; 25–50 Mbps la 4K"],
        ["Keyframe Interval", "2 secunde"],
        ["De reținut", "Preset, Level, Tune și parametrii avansați nu se aplică la hardware. Calitatea e mai slabă la același bitrate decât x264/x265: folosește hardware pentru revizuire, nu pentru livrarea finală."],
    ])
    b += [
        .h2("10.12 Rata de cadre și material întrețesut"),
        .bullets([
            "Păstrează **rata de cadre a timeline-ului**; nu o schimba la export. Convertirile de rată se fac în setările proiectului.",
            "Pentru web se recomandă rate progresive (24, 25, 30, 50, 60 fps). Materialul întrețesut se convertește în Resolve înainte de export, când destinația e web.",
            "Rezoluția trebuie să aibă lățimea pară (pentru 4:2:0 și înălțimea pară).",
        ]),
    ]
    return b
}

// ─────────────────────────── 11. Parametri avansați ───────────────────────────
func ch11() -> [Block] { [
    .h1("11. Parametri avansați (x264 și x265)"),
    .p("Câmpul **Advanced Params** primește opțiuni în forma `cheie=valoare`, separate prin `:`. Pluginul le trimite direct către x264 sau x265, în funcție de codec. Sunt destinate utilizatorilor care știu ce schimbă. Testează întotdeauna pe un clip scurt."),
    .note(.warn, "Opțiunile scrise aici au prioritate față de cele din panou, inclusiv `master-display` și `max-cll`. Nu duplica setările HDR10 din panou aici. Un parametru invalid împiedică pornirea exportului."),
    .h2("11.1 x264 (H.264)"),
    .table(headers: ["Parametru", "Ce face", "Exemplu", "Când"], rows: [
        ["aq-mode", "Alocă biți în funcție de complexitate; 3 favorizează zonele întunecate", "`aq-mode=3`", "Scene întunecate, degradeuri"],
        ["aq-strength", "Intensitatea adaptării", "`aq-strength=0.9`", "Reglaj fin cu aq-mode"],
        ["psy-rd", "Păstrează aspectul detaliilor (rd, trellis)", "`psy-rd=1.0,0.15`", "Reducere de artefacte / detaliu mai natural"],
        ["ref", "Cadre de referință", "`ref=4`", "Calitate mai bună; atenție la level"],
        ["deblock", "Filtru anti-blocuri (alpha,beta)", "`deblock=-1,-1`", "Imagine puțin mai clară"],
        ["rc-lookahead", "Cadre analizate în avans", "`rc-lookahead=40`", "Distribuție mai bună a biților"],
        ["vbv-maxrate + vbv-bufsize", "Plafon de bitrate (kbps)", "`vbv-maxrate=15000:vbv-bufsize=30000`", "Platforme cu limită de bitrate; CBR aproximativ"],
    ], widths: [0.20, 0.34, 0.26, 0.20]),
    .h2("11.2 x265 (H.265)"),
    .table(headers: ["Parametru", "Ce face", "Exemplu", "Când"], rows: [
        ["aq-mode", "Ca la x264; 3 favorizează zonele întunecate", "`aq-mode=3`", "HDR, scene întunecate"],
        ["psy-rd / psy-rdoq", "Păstrează detaliul și textura", "`psy-rd=2.0:psy-rdoq=1.0`", "Conținut cu textură fină"],
        ["rc-lookahead", "Cadre analizate în avans", "`rc-lookahead=40`", "Distribuție mai bună a biților"],
        ["bframes", "Numărul de cadre B", "`bframes=4`", "Eficiență mai bună; mai lent"],
        ["no-sao", "Dezactivează filtrul SAO (mai puțin lucios)", "`no-sao=1`", "Imagine mai clară, cu risc de artefacte"],
        ["hdr10-opt", "Ajustează cuantizarea pentru HDR10", "`hdr10-opt=1`", "Exporturi HDR10 pe 10 biți"],
        ["vbv-maxrate + vbv-bufsize", "Plafon de bitrate (kbps)", "`vbv-maxrate=50000:vbv-bufsize=100000`", "Platforme cu limită de bitrate"],
    ], widths: [0.20, 0.34, 0.26, 0.20]),
    .h2("11.3 Exemple gata de copiat"),
    .p("**CRF cu plafon de bitrate pentru social media** (H.264):"),
    .code("vbv-maxrate=12000:vbv-bufsize=24000"),
    .p("**Scene întunecate și degradeuri, H.264:**"),
    .code("aq-mode=3:aq-strength=0.9:rc-lookahead=40"),
    .p("**HDR10 pe 10 biți, H.265, cu optimizare de cuantizare:**"),
    .code("hdr10-opt=1:aq-mode=3:psy-rd=2.0:psy-rdoq=1.0"),
    .p("**Plafon pentru YouTube HDR 4K 30 fps, H.265:**"),
    .code("vbv-maxrate=60000:vbv-bufsize=120000"),
    .note(.info, "Numărul de cadre B este stabilit de plugin la 2; dacă îl schimbi aici, verifică rezultatul și compatibilitatea."),
] }

// ─────────────────────────── 12. Alegere rapidă ───────────────────────────
func ch12() -> [Block] { [
    .h1("12. Alegerea rapidă a setărilor"),
    .table(headers: ["Destinație", "Codec (Type)", "Format", "Setări-cheie"], rows: [
        ["YouTube SDR 1080p", "GDC H.264 (x264)", "MP4 (Resolve)", "slow, High, CRF 18–20, Rec.709"],
        ["YouTube SDR 4K", "GDC H.264 sau H.265 (x264/x265)", "MP4 (Resolve)", "slow, CRF 18–20 (x264) / 21–23 (x265), Level 5.0–5.2"],
        ["YouTube HDR10", "GDC H.265 10-bit (x265 Main10)", "GDC MP4 / QuickTime", "slow, CRF 16–18, HDR10 On, Rec.2100 ST2084"],
        ["YouTube HLG", "GDC H.265 10-bit", "GDC MP4 / QuickTime", "slow, CRF 16–18, HDR10 Off, Rec.2100 HLG"],
        ["Instagram / TikTok / Facebook", "GDC H.264 (x264)", "MP4 (Resolve)", "slow, High, CRF 20–22, 9:16 sau 4:5, Rec.709"],
        ["Vimeo", "GDC H.264 (x264)", "MP4 (Resolve)", "slow, CRF 17–19"],
        ["Televizor SDR 1080p", "GDC H.264 (x264)", "MP4 (Resolve)", "slow, High, Level 4.1, CRF 17–19, AAC"],
        ["Televizor HDR10 4K", "GDC H.265 10-bit", "GDC Matroska / MP4", "slow, Level 5.1, CRF 16–18, HDR10 On"],
        ["Apple TV / iPhone", "GDC H.265 10-bit", "GDC QuickTime / MP4", "hvc1, CRF 18–20, HDR10 On (pentru HDR)"],
        ["Televiziune (post cu H.264)", "GDC H.264 4:2:2 10-bit", "GDC QuickTime", "slow, CRF 12–16, Keyframe 1 s, PCM 24-bit"],
        ["Festival / screener", "GDC H.264 (x264)", "MP4 (Resolve)", "slow, High, Level 4.1, CRF 16–18"],
        ["Master ușor", "GDC 4:2:2 10-bit (x264 sau x265)", "GDC QuickTime", "slower, CRF 10–16, Keyframe 1 s"],
        ["Revizuire / dailies", "GDC H.264 (x264)", "MP4 (Resolve)", "veryfast, CRF 23–26, tune fastdecode"],
        ["Fișier mic", "GDC H.265 (x265) 8 biți", "MP4 (Resolve)", "slow, CRF 27–30, Keyframe 4–5 s"],
        ["Previzualizare rapidă", "VideoToolbox / NVENC", "MP4 (Resolve)", "Target Bitrate 8–20 Mbps"],
    ], widths: [0.22, 0.26, 0.21, 0.31]),
] }

// ─────────────────────────── 13. Depanare ───────────────────────────
func ch13() -> [Block] { [
    .h1("13. Depanare"),
    .table(headers: ["Problemă", "Cauze probabile", "Rezolvare"], rows: [
        ["Nu văd codecurile sau formatele GDC în Deliver", "Pluginul nu e instalat; Resolve nu a fost repornit; ai versiunea Free, nu Studio; sistem neacceptat", "Reinstalează pachetul; închide Resolve, așteaptă cel puțin 20 secunde, apoi redeschide-l; verifică versiunea Studio"],
        ["Exportul nu pornește", "Licență neactivată; Advanced Params invalid; lățime sau înălțime impară", "Introdu codul de activare; golește Advanced Params; folosește dimensiuni pare"],
        ["Imaginea pare spălată sau prea contrastată", "Data Levels pe Full pentru un fișier SDR; Output Color Space greșit", "Data Levels: Video; verifică Output Color Space"],
        ["HDR-ul arată spălat pe un ecran SDR", "Comportament normal: ecranul nu face tone mapping", "Verifică pe un ecran HDR real; pentru SDR livrează o versiune separată"],
        ["Bandă (banding) în cer sau degradeuri", "Cuantizare pe 8 biți; CRF prea mare", "Folosește varianta 10-bit; scade CRF; adaugă `aq-mode=3`; adaugă puțin grăunte în Resolve"],
        ["Fișier prea mare", "CRF prea mic; conținut cu grăunte; keyframe prea frecvent", "Crește CRF; preset slower; folosește x265; keyframe 2–4 s"],
        ["Fișier prea mic sau cu pierderi vizibile", "CRF prea mare; preset prea rapid", "Scade CRF; preset slow; verifică Target Bitrate"],
        ["Televizorul sau telefonul nu redă fișierul", "H.264 10-bit sau 4:2:2; level prea mare; sunet PCM", "Folosește 8 biți 4:2:0 (sau H.265 Main10 4:2:0); Level 4.1; sunet AAC prin formatul Resolve"],
        ["Platforma nu recunoaște HDR-ul", "Format Resolve (fără metadata în container); Output Color Space nu e PQ; HDR10 Metadata pe Off", "Folosește GDC MP4/QuickTime/Matroska; Rec.2100 ST2084; HDR10 Metadata: On"],
        ["Fără sunet la redarea MP4", "Sunet PCM în MP4 (ipcm), suport slab", "Folosește GDC Matroska sau GDC QuickTime; sau MP4 din Resolve cu AAC"],
        ["Exportul este foarte lent", "Preset lent; x265; rezoluție mare", "Preset mai rapid; hardware pentru previzualizări; scade rezoluția"],
        ["Variantele NVENC nu apar pe Mac", "NVENC există doar cu GPU NVIDIA pe Windows", "Normal; folosește VideoToolbox pe Mac"],
        ["Mesaj „Cannot add video track to clip”", "Ai ales un format GDC cu un codec care nu e GDC H.264/H.265", "Alege un codec GDC în formatul GDC sau folosește un format Resolve"],
    ], widths: [0.26, 0.34, 0.40]),
    .h2("13.1 Verificarea unui fișier exportat"),
    .p("Cu o unealtă gratuită precum **MediaInfo** sau **ffprobe** poți verifica ce conține fișierul: codec, profil, adâncime de biți, etichete de culoare (primare, transfer, matrice), metadata HDR (Mastering display, Content light level) și sunetul. Pentru un export HDR10 corect ar trebui să vezi transferul SMPTE ST 2084, primarele BT.2020, iar în formatele GDC și metadata de mastering și de nivel de lumină."),
    .code("ffprobe -v error -show_entries stream=codec_name,profile,pix_fmt,color_primaries,color_transfer,color_space:stream_side_data fisier.mp4"),
] }

// ─────────────────────────── 14. Limite și verificări ───────────────────────────
func ch14() -> [Block] { [
    .h1("14. Limite cunoscute și ce a fost verificat"),
    .p("Aceasta este imaginea cinstită a stării pluginului la versiunea 1.7.0. „Verificat” înseamnă testat prin export real în DaVinci Resolve Studio 21.1 pe macOS Apple Silicon, cu verificarea fișierului rezultat."),
    .table(headers: ["Funcție", "Stare"], rows: [
        ["x264 și x265, 8 biți 4:2:0", "Verificat"],
        ["Apple VideoToolbox H.264 și H.265", "Verificat"],
        ["NVIDIA NVENC", "Verificat în versiuni anterioare pe Windows cu GPU NVIDIA; nereverificat la 1.7.0"],
        ["x264 High10 și x265 Main10 (10 biți 4:2:0)", "Verificat"],
        ["x264 și x265 4:2:2 10 biți", "Verificat (inclusiv ordinea planurilor de culoare)"],
        ["Etichete PQ, HLG, P3-D65, P3-DCI, Rec.709", "Verificat"],
        ["HDR10 în flux (x264 și x265; 4:2:0 și 4:2:2)", "Verificat pe toate cele patru combinații"],
        ["Mastering Primaries: P3-D65", "Verificat"],
        ["Mastering Primaries: Rec.2020", "**Netestat** în Resolve"],
        ["GDC QuickTime, GDC MP4, GDC Matroska (x265 4:2:2 10-bit, PQ, HDR10)", "Verificat, cu HDR în container și sunet PCM"],
        ["Codec H.264 în formatele GDC", "**Netestat**"],
        ["„Export Audio” debifat în formatele GDC", "**Netestat**"],
        ["Windows: încărcarea pluginului", "Verificat automat la publicare"],
        ["Windows: exportul în Resolve, inclusiv formatele GDC", "**Netestat**"],
        ["Timecode de start și markere în formatele GDC", "Neimplementat"],
        ["AAC în formatele GDC", "Neimplementat"],
        ["Mac Intel, Linux", "Neacceptate"],
    ], widths: [0.62, 0.38]),
    .note(.info, "Ce este marcat „Netestat” nu înseamnă că nu funcționează, ci că nu a fost verificat prin export real. Dacă îl folosești, testează întâi pe un clip scurt."),
] }

// ─────────────────────────── Anexe ───────────────────────────
func annex() -> [Block] { [
    .h1("Anexa A. Lista de verificare înainte de export"),
    .numbered([
        "Timeline-ul este finalizat; rata de cadre și rezoluția sunt cele dorite (lățime și înălțime pare).",
        "Output Color Space corespunde destinației (Rec.709, Rec.2100 ST2084 sau Rec.2100 HLG).",
        "Ai ales formatul (Resolve sau GDC) potrivit sunetului și metadatei de care ai nevoie.",
        "Ai ales varianta de codec potrivită: 8 biți 4:2:0 pentru compatibilitate, 10 biți pentru HDR, 4:2:2 doar pentru post-producție.",
        "Preset: slow pentru livrare; Level: Auto; Tune: none, dacă nu ai un motiv anume.",
        "Rate Control: CRF (sau Target Bitrate dacă platforma impune un bitrate).",
        "Data Levels: Video.",
        "Pentru HDR10: HDR10 Metadata On, monitorul real de mastering, MaxCLL/MaxFALL măsurate sau 0.",
        "Ai exportat un fragment scurt și l-ai verificat pe dispozitivul țintă (și, la nevoie, cu MediaInfo/ffprobe).",
        "Abia apoi exporți filmul întreg.",
    ]),
    .h1("Anexa B. Glosar"),
    .table(headers: ["Termen", "Explicație"], rows: [
        ["CRF", "Constant Rate Factor: mod de codare cu calitate constantă; număr mai mic = calitate mai bună, fișier mai mare"],
        ["QP", "Parametru de cuantizare: cât de mult se comprimă fiecare cadru"],
        ["Keyframe / GOP", "Cadru cheie (imagine completă) / grupul de cadre dintre două cadre cheie"],
        ["Cadru B", "Cadru codat pe baza cadrelor dinainte și de după; ajută compresia"],
        ["Profile / Level", "Set de unelte permise / limite de rezoluție, cadre și bitrate; determină compatibilitatea cu dispozitivele"],
        ["Crominanță 4:2:0 / 4:2:2", "Câtă informație de culoare se păstrează față de luminanță; 4:2:2 păstrează mai mult pe verticală"],
        ["Rec.709", "Standard SDR pentru televiziune HD; gama 2.4 (BT.1886)"],
        ["Rec.2020", "Gama largă de culoare folosită pentru HDR și UHD"],
        ["P3-D65 / P3-DCI", "Gama de culoare P3 cu punct alb D65 / cu punct alb cinema DCI"],
        ["PQ (SMPTE ST 2084)", "Funcția de transfer HDR bazată pe luminanță absolută; folosită de HDR10"],
        ["HLG", "Hybrid Log-Gamma: funcție de transfer HDR compatibilă cu ecrane SDR; folosită în televiziune"],
        ["HDR10", "PQ + Rec.2020 + 10 biți + metadata statică (mastering display, MaxCLL, MaxFALL)"],
        ["Mastering display", "Caracteristicile monitorului pe care s-a etalonat (primare, luminanță)"],
        ["MaxCLL / MaxFALL", "Luminanța maximă a unui pixel / luminanța medie maximă a unui cadru, din tot filmul, în nits"],
        ["Nit", "Unitate de luminanță (candela pe metru pătrat)"],
        ["SEI", "Mesaj suplimentar în fluxul video; aici poartă metadata HDR"],
        ["mdcv / clli", "Cutii din container care poartă mastering display și nivelul de lumină al conținutului"],
        ["Container", "Fișierul care împachetează video și audio (MOV, MP4, MKV)"],
        ["Data Levels (Video/Full)", "Intervalul valorilor: Video (16–235 la 8 biți) sau Full (0–255)"],
    ], widths: [0.26, 0.74]),
    .h1("Anexa C. Referință rapidă a nivelurilor"),
    .table(headers: ["Rezoluție și rată", "H.264 (Level)", "H.265 (Level)"], rows: [
        ["1280×720, 30 fps", "3.1", "3.1"],
        ["1920×1080, 30 fps", "4.0 / 4.1", "4.0 / 4.1"],
        ["1920×1080, 60 fps", "4.2", "4.1"],
        ["2560×1440, 30 fps", "5.0", "5.0"],
        ["3840×2160, 30 fps", "5.1", "5.0"],
        ["3840×2160, 60 fps", "5.2", "5.1"],
    ], widths: [0.40, 0.30, 0.30]),
    .p("Pentru cazurile în care nu ești sigur, lasă **Level: Auto**."),
] }
