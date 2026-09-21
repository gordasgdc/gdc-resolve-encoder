import Foundation

// English edition, part 2: export recipes, advanced parameters, quick chooser, troubleshooting, limits, annexes.

func en10a() -> [Block] {
    var b: [Block] = [
        .h1("10. Export recipes"),
        .p("Each recipe lists the settings in the plugin panel and in Resolve. The values are **starting points**: test on a short 10–20 second clip, check the result on the target device, then export the film. Platforms change their recommendations periodically; check their current specifications before an important delivery."),
        .h2("10.1 How to read the recipes"),
        .bullets([
            "**Format** = Deliver's Format list. \"MP4 (Resolve)\" means the native format; \"GDC MP4\" means the plugin's own format.",
            "**Codec (Type)** = the variant chosen in the plugin panel.",
            "**In Resolve** = the Deliver and Color Management settings that affect the file.",
            "If a row is missing from a recipe, leave the default value.",
        ]),
        .note(.tip, "For any destination, first export a fragment from the hardest part of the film (fast motion, gradients, darkness). If it looks good there, the rest will look good."),
        .h2("10.2 YouTube"),
        .p("YouTube recompresses everything you upload. The goal is to upload a **high-quality** file so the recompression starts from a clean source. The bitrate values below are the ones YouTube publicly recommended at the time of writing, as an order of magnitude."),
    ]
    b += recipeEN("YouTube SDR, 1080p (24–30 fps)", [
        ["Format", "MP4 (Resolve) or QuickTime (Resolve), with AAC 320 kbps or PCM audio"],
        ["Codec (Type)", "GDC H.264 (Software x264)"],
        ["Preset", "slow"],
        ["Profile / Level", "High / Auto (4.2 if the frame rate is 48–60)"],
        ["Tune", "none"],
        ["Rate Control", "Constant Quality, **CRF 18–20** (or Target Bitrate 12 Mbps)"],
        ["Keyframe Interval", "1–2 seconds"],
        ["HDR10 Metadata", "Off"],
        ["In Resolve", "Output Color Space Rec.709; Data Levels Video; 1920×1080; the timeline's frame rate"],
        ["Keep in mind", "YouTube's recommendation for 1080p SDR is on the order of 8 Mbps at 24–30 fps and 12 Mbps at 48–60 fps; a CRF of 18–20 exceeds these values, which is good for recompression."],
    ])
    b += recipeEN("YouTube SDR, 4K (24–30 fps)", [
        ["Format", "MP4 (Resolve) with AAC, or GDC QuickTime with PCM"],
        ["Codec (Type)", "GDC H.264 (Software x264) or GDC H.265 (Software x265) for smaller files"],
        ["Preset", "slow"],
        ["Profile / Level", "H.264: High / **5.1** (5.2 at 60 fps). H.265: Main / **5.0** (5.1 at 60 fps)"],
        ["Tune", "none"],
        ["Rate Control", "H.264: **CRF 18–20** (or 35–45 Mbps). H.265: **CRF 21–23** (or 25–35 Mbps)"],
        ["Keyframe Interval", "1–2 seconds"],
        ["HDR10 Metadata", "Off"],
        ["In Resolve", "Output Color Space Rec.709; Data Levels Video; 3840×2160"],
        ["Keep in mind", "H.265 at 4K reduces the file by about a third compared to H.264 at comparable quality, but the export takes longer."],
    ])
    b += recipeEN("YouTube HDR10 (PQ), 4K", [
        ["Format", "**GDC MP4**, **GDC QuickTime** or **GDC Matroska** (HDR10 metadata reaches the container)"],
        ["Codec (Type)", "GDC H.265 10-bit (Software x265 Main10)"],
        ["Preset", "slow"],
        ["Profile / Level", "Main 10 (automatic) / **5.0** (4K 30 fps) or **5.1** (4K 60 fps)"],
        ["Tune", "none"],
        ["Rate Control", "**CRF 16–18** (or Target Bitrate 44–56 Mbps at 4K 24–30 fps, 66–85 Mbps at 48–60 fps)"],
        ["Keyframe Interval", "1–2 seconds"],
        ["HDR10 Metadata", "**On**; Mastering Primaries P3-D65; Mastering Peak = your monitor's luminance (1000 typical); MaxCLL/MaxFALL measured, or 0"],
        ["In Resolve", "Output Color Space **Rec.2100 ST2084**; Data Levels Video; 3840×2160"],
        ["Audio", "24-bit 48 kHz PCM in the GDC formats (check on upload that the platform accepts it)"],
        ["Keep in mind", "YouTube identifies HDR from the file. The GDC formats also put the metadata in the container, which is the safest option. After uploading, check that the platform marks the video as HDR."],
    ])
    b += recipeEN("YouTube HLG, 4K", [
        ["Format", "GDC MP4 or GDC QuickTime"],
        ["Codec (Type)", "GDC H.265 10-bit (Software x265 Main10)"],
        ["Preset / Level", "slow / 5.0 (4K 30 fps) or 5.1 (4K 60 fps)"],
        ["Rate Control", "**CRF 16–18**"],
        ["Keyframe Interval", "1–2 seconds"],
        ["HDR10 Metadata", "**Off** (HLG does not use static metadata)"],
        ["In Resolve", "Output Color Space **Rec.2100 HLG**; Data Levels Video"],
        ["Keep in mind", "Check on both an SDR and an HDR screen: HLG looks acceptable on both."],
    ])
    return b
}

func en10b() -> [Block] {
    var b: [Block] = [
        .h2("10.3 Facebook, Instagram, TikTok and other networks"),
        .p("Social networks **recompress heavily**. There is no point in uploading a huge file: a good-quality file, in the right frame format and with a moderate bitrate, behaves best. Use **8-bit SDR H.264**, the safest choice. Size, duration and resolution limits change often; check them before uploading."),
        .table(headers: ["Frame format", "Resolution", "Where it is used"], rows: [
            ["Vertical 9:16", "1080×1920", "Instagram Reels and Stories, TikTok, Facebook Reels, YouTube Shorts"],
            ["Portrait 4:5", "1080×1350", "Instagram and Facebook Feed (takes more screen)"],
            ["Square 1:1", "1080×1080", "Feed, special cases"],
            ["Landscape 16:9", "1920×1080", "Facebook, YouTube, LinkedIn, X"],
        ], widths: [0.24, 0.20, 0.56]),
    ]
    b += recipeEN("Instagram Reels / Stories (vertical)", [
        ["Format", "MP4 (Resolve), AAC audio 128–256 kbps, 48 kHz"],
        ["Codec (Type)", "GDC H.264 (Software x264)"],
        ["Preset", "slow (or medium for speed)"],
        ["Profile / Level", "High / 4.1 (Auto is enough)"],
        ["Tune", "none"],
        ["Rate Control", "**CRF 20**; optional cap in Advanced Params: `vbv-maxrate=12000:vbv-bufsize=24000`"],
        ["Keyframe Interval", "2 seconds"],
        ["HDR10 Metadata", "Off"],
        ["In Resolve", "Output Color Space Rec.709; Data Levels Video; 1080×1920; 30 fps (or native rate)"],
        ["Keep in mind", "Keep text and important elements in the central area; the app's interface covers the top and bottom edges."],
    ])
    b += recipeEN("Instagram Feed / Facebook Feed (4:5 or 1:1)", [
        ["Format", "MP4 (Resolve), AAC audio 128–192 kbps"],
        ["Codec (Type)", "GDC H.264 (Software x264)"],
        ["Preset / Profile / Level", "slow / High / Auto"],
        ["Rate Control", "**CRF 20–22** (or Target Bitrate 8–10 Mbps at 1080p)"],
        ["Keyframe Interval", "2 seconds"],
        ["In Resolve", "Rec.709; Data Levels Video; 1080×1350 (4:5) or 1080×1080 (1:1)"],
    ])
    b += recipeEN("Facebook (landscape video)", [
        ["Format", "MP4 (Resolve), AAC stereo audio 128–256 kbps"],
        ["Codec (Type)", "GDC H.264 (Software x264)"],
        ["Preset / Profile / Level", "slow / High / Auto"],
        ["Rate Control", "**CRF 20–22** (or Target Bitrate 8–12 Mbps at 1080p)"],
        ["Keyframe Interval", "2 seconds"],
        ["In Resolve", "Rec.709; Data Levels Video; 1920×1080; frame rates up to 30 fps recommended"],
    ])
    b += recipeEN("TikTok", [
        ["Format", "MP4 (Resolve), AAC audio 128–192 kbps"],
        ["Codec (Type)", "GDC H.264 (Software x264)"],
        ["Preset / Profile / Level", "slow / High / 4.1"],
        ["Rate Control", "**CRF 20**; alternatively Target Bitrate 8–12 Mbps"],
        ["Keyframe Interval", "2 seconds"],
        ["In Resolve", "Rec.709; Data Levels Video; 1080×1920; 30 fps"],
        ["Keep in mind", "HDR support on upload differs from one app version to another: if you want HDR, test on a short clip before delivering."],
    ])
    b += recipeEN("Vimeo", [
        ["Format", "MP4 or QuickTime (Resolve)"],
        ["Codec (Type)", "GDC H.264 (Software x264)"],
        ["Preset / Profile / Level", "slow / High / Auto"],
        ["Rate Control", "**CRF 17–19** (or Target Bitrate 10–20 Mbps at 1080p)"],
        ["Keyframe Interval", "2 seconds"],
        ["In Resolve", "Rec.709; Data Levels Video; the project's resolution"],
    ])
    b += recipeEN("Quick sharing (WhatsApp, Telegram, e-mail)", [
        ["Format", "MP4 (Resolve), AAC audio 128 kbps"],
        ["Codec (Type)", "GDC H.264 (Software x264)"],
        ["Preset", "fast"],
        ["Rate Control", "**CRF 24–26**"],
        ["Keyframe Interval", "2–4 seconds"],
        ["In Resolve", "Rec.709; Data Levels Video; 1280×720 or 1920×1080"],
        ["Keep in mind", "Messaging apps recompress and limit size; a small file arrives faster and loses less on recompression."],
    ])
    return b
}

func en10c() -> [Block] {
    var b: [Block] = [
        .h2("10.4 Television: playback from USB, streamer or Apple TV"),
        .p("For TV playback, what matters is the **device's hardware decoder**, not the encoder's quality. TVs play H.264 8-bit 4:2:0 almost universally and, on recent models, H.265 Main/Main10 4:2:0. They generally **do not** play 10-bit or 4:2:2 H.264. The safe rule: for TV, stay with 4:2:0."),
    ]
    b += recipeEN("SDR TV, 1080p (USB / DLNA)", [
        ["Format", "MP4 (Resolve) with AAC or AC-3 (compatible with most TVs)"],
        ["Codec (Type)", "GDC H.264 (Software x264), 8-bit"],
        ["Preset / Profile / Level", "slow / High / **4.1** (4.2 at 50/60 fps)"],
        ["Tune", "none"],
        ["Rate Control", "**CRF 17–19** (or Target Bitrate 15–25 Mbps)"],
        ["Keyframe Interval", "2 seconds"],
        ["In Resolve", "Rec.709; Data Levels Video; 1920×1080"],
        ["Keep in mind", "Do not use 10-bit or 4:2:2 for TV. If the TV does not play the audio, switch to stereo AAC."],
    ])
    b += recipeEN("SDR TV, 4K", [
        ["Format", "MP4 (Resolve) with AAC"],
        ["Codec (Type)", "GDC H.265 (Software x265), 8-bit (or GDC H.264 if the TV does not play H.265)"],
        ["Preset / Level", "slow / **5.0** (30 fps) or **5.1** (60 fps)"],
        ["Rate Control", "**CRF 20–22** (or Target Bitrate 30–50 Mbps)"],
        ["Keyframe Interval", "2 seconds"],
        ["In Resolve", "Rec.709; Data Levels Video; 3840×2160"],
    ])
    b += recipeEN("HDR10 TV, 4K (USB / streamer)", [
        ["Format", "**GDC Matroska** or **GDC MP4** (HDR10 in the container, wide playback); GDC QuickTime for the Apple ecosystem"],
        ["Codec (Type)", "GDC H.265 10-bit (Software x265 Main10), 4:2:0"],
        ["Preset / Level", "slow / **5.1**"],
        ["Tune", "none"],
        ["Rate Control", "**CRF 16–18** (or Target Bitrate 45–80 Mbps)"],
        ["Keyframe Interval", "2 seconds"],
        ["HDR10 Metadata", "**On**; P3-D65; Peak = your monitor; MaxCLL/MaxFALL measured or 0"],
        ["In Resolve", "Output Color Space Rec.2100 ST2084; Data Levels Video"],
        ["Audio", "PCM in the GDC formats; if the TV does not play PCM, try GDC Matroska or use a Resolve format with AAC/AC-3 (the metadata stays in the stream, but not in the container)"],
        ["Keep in mind", "Do not use 4:2:2 for TV. Check on the real device that HDR10 mode is activated."],
    ])
    b += recipeEN("HLG TV", [
        ["Format", "GDC MP4 or GDC Matroska"],
        ["Codec (Type)", "GDC H.265 10-bit (Software x265 Main10)"],
        ["Preset / Level", "slow / 5.1"],
        ["Rate Control", "**CRF 16–18**"],
        ["HDR10 Metadata", "**Off**"],
        ["In Resolve", "Output Color Space Rec.2100 HLG; Data Levels Video"],
    ])
    b += recipeEN("Apple TV, iPhone, iPad (local playback)", [
        ["Format", "**GDC QuickTime** or **GDC MP4** (hvc1 tag, required by the Apple ecosystem)"],
        ["Codec (Type)", "GDC H.265 10-bit (Software x265 Main10) for HDR; GDC H.265 (x265) 8-bit for SDR"],
        ["Preset / Level", "slow / 5.1 (4K) or 4.1 (1080p)"],
        ["Rate Control", "**CRF 18–20**"],
        ["HDR10 Metadata", "On for HDR10; Off for SDR/HLG"],
        ["Keep in mind", "Avoid 4:2:2 for playback on consumer devices."],
    ])
    b += [
        .h2("10.5 Broadcast television (delivery to a station)"),
        .p("Deliveries to television stations are governed by each station's **technical specification**. The most common requirements are XDCAM HD422 (MXF), ProRes 422 HQ, DNxHD/DNxHR or AVC-Intra: native codecs in Resolve, not in this plugin. **Always follow the station's specification.**"),
        .p("The plugin fits when the station or platform explicitly asks for **H.264 or H.265**, for example for OTT deliveries, viewing archive copies or specifications of the \"H.264 High 4:2:2 10-bit\" kind. Loudness (for example EBU R128 or ATSC A/85) is set in Fairlight; the plugin does not modify it."),
    ]
    b += recipeEN("H.264 4:2:2 10-bit delivery for post-production / OTT", [
        ["Format", "**GDC QuickTime** (or GDC Matroska)"],
        ["Codec (Type)", "GDC H.264 4:2:2 10-bit (Software x264 High 4:2:2)"],
        ["Preset", "slow"],
        ["Profile / Level", "High 4:2:2 (automatic) / 4.1 (1080p 25–30) or 4.2 (1080p 50–60)"],
        ["Tune", "none"],
        ["Rate Control", "**CRF 12–16** (or Target Bitrate 50–100 Mbps)"],
        ["Keyframe Interval", "1 second"],
        ["HDR10 Metadata", "Off (SDR Rec.709)"],
        ["In Resolve", "Output Color Space Rec.709; Data Levels Video; the resolution and frame rate required by the specification"],
        ["Audio", "24-bit 48 kHz PCM"],
        ["Keep in mind", "Check the exact profile in the specification (many broadcast specifications require an intra-only profile or fixed parameters, which CRF does not guarantee)."],
    ])
    b += [
        .h2("10.6 Cinema, festivals, projection"),
        .p("For theatrical projection, **DCP** (JPEG 2000, XYZ space) and **ProRes 4444 XQ**, **DPX** or **EXR** masters are used, all native in Resolve. The plugin is **not** the tool for the cinema master. You use it for viewing files and online delivery."),
    ]
    b += recipeEN("Festival screener / online submission (1080p)", [
        ["Format", "MP4 (Resolve) with AAC or QuickTime (Resolve)"],
        ["Codec (Type)", "GDC H.264 (Software x264), 8-bit"],
        ["Preset / Profile / Level", "slow / High / 4.1"],
        ["Rate Control", "**CRF 16–18** (or Target Bitrate 15–25 Mbps)"],
        ["Keyframe Interval", "2 seconds"],
        ["In Resolve", "Rec.709; Data Levels Video; 1920×1080; 24 fps (the film's rate)"],
        ["Keep in mind", "Many festivals ask for 1080p H.264; read the rules before exporting."],
    ])
    b += recipeEN("HDR review for a client or colorist (with HDR10 in the file)", [
        ["Format", "**GDC QuickTime** or **GDC MP4**"],
        ["Codec (Type)", "GDC H.265 10-bit (Software x265 Main10)"],
        ["Preset / Level", "medium / 5.1"],
        ["Rate Control", "**CRF 18–20**"],
        ["HDR10 Metadata", "On; the real mastering monitor; MaxCLL/MaxFALL measured or 0"],
        ["In Resolve", "Rec.2100 ST2084; Data Levels Video"],
    ])
    return b
}

func en10d() -> [Block] {
    var b: [Block] = [
        .h2("10.7 Light master / quality archive"),
        .p("A 10-bit H.264/H.265 master is **lossy** even at a very low CRF. For a lossless master use Resolve's lossless or intermediate codecs (ProRes, DNxHR, FFV1). The recipes below are for **light** masters, useful when space matters."),
    ]
    b += recipeEN("Light 4:2:2 10-bit master (SDR)", [
        ["Format", "GDC QuickTime"],
        ["Codec (Type)", "GDC H.264 4:2:2 10-bit (x264) or GDC H.265 4:2:2 10-bit (x265)"],
        ["Preset", "slower"],
        ["Rate Control", "H.264: **CRF 10–14**. H.265: **CRF 12–16**"],
        ["Keyframe Interval", "1 second"],
        ["Tune", "none (grain if the material has grain)"],
        ["In Resolve", "Rec.709; Data Levels Video; native resolution"],
        ["Audio", "24-bit 48 kHz PCM"],
    ])
    b += recipeEN("Light HDR10 4:2:2 10-bit master", [
        ["Format", "GDC QuickTime or GDC Matroska"],
        ["Codec (Type)", "GDC H.265 4:2:2 10-bit (Software x265 Main 4:2:2 10)"],
        ["Preset", "slower"],
        ["Rate Control", "**CRF 12–16**"],
        ["Keyframe Interval", "1 second"],
        ["HDR10 Metadata", "On; the real monitor; MaxCLL/MaxFALL measured"],
        ["In Resolve", "Rec.2100 ST2084; Data Levels Video"],
        ["Keep in mind", "4:2:2 does not play on ordinary TVs; it is for post-production."],
    ])
    b += [ .h2("10.8 Review and dailies") ]
    b += recipeEN("Review copy / dailies", [
        ["Format", "MP4 (Resolve), AAC audio 128 kbps"],
        ["Codec (Type)", "GDC H.264 (Software x264)"],
        ["Preset", "veryfast"],
        ["Rate Control", "**CRF 23–26**"],
        ["Tune", "fastdecode (smooth scrubbing on weak computers)"],
        ["Keyframe Interval", "1 second (fast scrubbing)"],
        ["In Resolve", "Rec.709; 1280×720 or 1920×1080; timecode included through Data burn-in if needed"],
    ])
    b += [ .h2("10.9 Smallest possible file") ]
    b += recipeEN("Minimum size at acceptable quality (SDR)", [
        ["Format", "MP4 (Resolve)"],
        ["Codec (Type)", "GDC H.265 (Software x265) 8-bit"],
        ["Preset", "slow"],
        ["Rate Control", "**CRF 27–30**"],
        ["Keyframe Interval", "4–5 seconds"],
        ["Tune", "none"],
        ["Keep in mind", "H.265 saves about a third compared to H.264, but not all devices play it."],
    ])
    b += [ .h2("10.10 Special kinds of content") ]
    b += recipeEN("Animation, graphics, screen recording", [
        ["Codec (Type)", "GDC H.264 (x264); for fine colored text: GDC H.264 4:2:2 10-bit"],
        ["Tune", "**animation**"],
        ["Preset", "slow"],
        ["Rate Control", "**CRF 16–18**"],
        ["Keyframe Interval", "2 seconds"],
        ["Keep in mind", "Colored text on a colored background looks cleaner in 4:2:2; but the result looks right only on players that decode 4:2:2."],
    ])
    b += recipeEN("Film-grain material", [
        ["Codec (Type)", "GDC H.264 (x264) or GDC H.265 10-bit"],
        ["Tune", "**grain**"],
        ["Preset", "slow"],
        ["Rate Control", "x264: **CRF 18–20**; x265: **CRF 20–22**"],
        ["Keep in mind", "Grain consumes many bits; the file comes out large. You can reduce the grain in Resolve before export if size matters."],
    ])
    b += recipeEN("Fine gradients and dark scenes (avoiding banding)", [
        ["Codec (Type)", "A **10-bit** variant (H.265 Main10 or H.264 High10), even for SDR"],
        ["Preset", "slow"],
        ["Rate Control", "CRF 16–18 (x265) or 15–17 (x264)"],
        ["Advanced Params", "`aq-mode=3` (favors dark areas)"],
        ["Keep in mind", "10-bit reduces banding visibly even if the playback screen is 8-bit; but check playback compatibility."],
    ])
    b += [ .h2("10.11 Fast preview with hardware") ]
    b += recipeEN("VideoToolbox (Mac) or NVENC (Windows)", [
        ["Codec (Type)", "GDC H.264 (Apple VideoToolbox) / GDC H.265 (Apple VideoToolbox); on Windows the NVENC variants"],
        ["Rate Control", "**Target Bitrate** 8–20 Mbps at 1080p; 25–50 Mbps at 4K"],
        ["Keyframe Interval", "2 seconds"],
        ["Keep in mind", "Preset, Level, Tune and advanced parameters do not apply to hardware. Quality is weaker at the same bitrate than x264/x265: use hardware for review, not for final delivery."],
    ])
    b += [
        .h2("10.12 Frame rate and interlaced material"),
        .bullets([
            "Keep the **timeline's frame rate**; do not change it at export. Rate conversions are done in the project settings.",
            "For web, progressive rates are recommended (24, 25, 30, 50, 60 fps). Interlaced material is converted in Resolve before export when the destination is web.",
            "The resolution must have an even width (for 4:2:0 also an even height).",
        ]),
    ]
    return b
}

func en11() -> [Block] { [
    .h1("11. Advanced parameters (x264 and x265)"),
    .p("The **Advanced Params** field takes options in the form `key=value`, separated by `:`. The plugin passes them straight to x264 or x265, depending on the codec. They are meant for users who know what they change. Always test on a short clip."),
    .note(.warn, "Options written here take priority over those in the panel, including `master-display` and `max-cll`. Do not duplicate the panel's HDR10 settings here. An invalid parameter prevents the export from starting."),
    .h2("11.1 x264 (H.264)"),
    .table(headers: ["Parameter", "What it does", "Example", "When"], rows: [
        ["aq-mode", "Allocates bits by complexity; 3 favors dark areas", "`aq-mode=3`", "Dark scenes, gradients"],
        ["aq-strength", "Strength of the adaptation", "`aq-strength=0.9`", "Fine tuning with aq-mode"],
        ["psy-rd", "Preserves the look of detail (rd, trellis)", "`psy-rd=1.0,0.15`", "Fewer artifacts / more natural detail"],
        ["ref", "Reference frames", "`ref=4`", "Better quality; watch the level"],
        ["deblock", "Deblocking filter (alpha,beta)", "`deblock=-1,-1`", "A slightly sharper image"],
        ["rc-lookahead", "Frames analyzed ahead", "`rc-lookahead=40`", "Better bit distribution"],
        ["vbv-maxrate + vbv-bufsize", "Bitrate cap (kbps)", "`vbv-maxrate=15000:vbv-bufsize=30000`", "Platforms with a bitrate limit; approximate CBR"],
    ], widths: [0.20, 0.34, 0.26, 0.20]),
    .h2("11.2 x265 (H.265)"),
    .table(headers: ["Parameter", "What it does", "Example", "When"], rows: [
        ["aq-mode", "As in x264; 3 favors dark areas", "`aq-mode=3`", "HDR, dark scenes"],
        ["psy-rd / psy-rdoq", "Preserves detail and texture", "`psy-rd=2.0:psy-rdoq=1.0`", "Finely textured content"],
        ["rc-lookahead", "Frames analyzed ahead", "`rc-lookahead=40`", "Better bit distribution"],
        ["bframes", "Number of B-frames", "`bframes=4`", "Better efficiency; slower"],
        ["no-sao", "Disables the SAO filter (less glossy)", "`no-sao=1`", "A sharper image, with artifact risk"],
        ["hdr10-opt", "Adjusts quantization for HDR10", "`hdr10-opt=1`", "10-bit HDR10 exports"],
        ["vbv-maxrate + vbv-bufsize", "Bitrate cap (kbps)", "`vbv-maxrate=50000:vbv-bufsize=100000`", "Platforms with a bitrate limit"],
    ], widths: [0.20, 0.34, 0.26, 0.20]),
    .h2("11.3 Ready-to-copy examples"),
    .p("**CRF with a bitrate cap for social media** (H.264):"),
    .code("vbv-maxrate=12000:vbv-bufsize=24000"),
    .p("**Dark scenes and gradients, H.264:**"),
    .code("aq-mode=3:aq-strength=0.9:rc-lookahead=40"),
    .p("**10-bit HDR10, H.265, with quantization optimization:**"),
    .code("hdr10-opt=1:aq-mode=3:psy-rd=2.0:psy-rdoq=1.0"),
    .p("**Cap for YouTube HDR 4K 30 fps, H.265:**"),
    .code("vbv-maxrate=60000:vbv-bufsize=120000"),
    .note(.info, "The number of B-frames is set by the plugin to 2; if you change it here, check the result and compatibility."),
] }

func en12() -> [Block] { [
    .h1("12. Quick settings chooser"),
    .table(headers: ["Destination", "Codec (Type)", "Format", "Key settings"], rows: [
        ["YouTube SDR 1080p", "GDC H.264 (x264)", "MP4 (Resolve)", "slow, High, CRF 18–20, Rec.709"],
        ["YouTube SDR 4K", "GDC H.264 or H.265 (x264/x265)", "MP4 (Resolve)", "slow, CRF 18–20 (x264) / 21–23 (x265), Level 5.0–5.2"],
        ["YouTube HDR10", "GDC H.265 10-bit (x265 Main10)", "GDC MP4 / QuickTime", "slow, CRF 16–18, HDR10 On, Rec.2100 ST2084"],
        ["YouTube HLG", "GDC H.265 10-bit", "GDC MP4 / QuickTime", "slow, CRF 16–18, HDR10 Off, Rec.2100 HLG"],
        ["Instagram / TikTok / Facebook", "GDC H.264 (x264)", "MP4 (Resolve)", "slow, High, CRF 20–22, 9:16 or 4:5, Rec.709"],
        ["Vimeo", "GDC H.264 (x264)", "MP4 (Resolve)", "slow, CRF 17–19"],
        ["SDR TV 1080p", "GDC H.264 (x264)", "MP4 (Resolve)", "slow, High, Level 4.1, CRF 17–19, AAC"],
        ["HDR10 TV 4K", "GDC H.265 10-bit", "GDC Matroska / MP4", "slow, Level 5.1, CRF 16–18, HDR10 On"],
        ["Apple TV / iPhone", "GDC H.265 10-bit", "GDC QuickTime / MP4", "hvc1, CRF 18–20, HDR10 On (for HDR)"],
        ["Television (station with H.264)", "GDC H.264 4:2:2 10-bit", "GDC QuickTime", "slow, CRF 12–16, Keyframe 1 s, 24-bit PCM"],
        ["Festival / screener", "GDC H.264 (x264)", "MP4 (Resolve)", "slow, High, Level 4.1, CRF 16–18"],
        ["Light master", "GDC 4:2:2 10-bit (x264 or x265)", "GDC QuickTime", "slower, CRF 10–16, Keyframe 1 s"],
        ["Review / dailies", "GDC H.264 (x264)", "MP4 (Resolve)", "veryfast, CRF 23–26, tune fastdecode"],
        ["Small file", "GDC H.265 (x265) 8-bit", "MP4 (Resolve)", "slow, CRF 27–30, Keyframe 4–5 s"],
        ["Fast preview", "VideoToolbox / NVENC", "MP4 (Resolve)", "Target Bitrate 8–20 Mbps"],
    ], widths: [0.22, 0.26, 0.21, 0.31]),
] }

func en13() -> [Block] { [
    .h1("13. Troubleshooting"),
    .table(headers: ["Problem", "Probable causes", "Fix"], rows: [
        ["I do not see the GDC codecs or formats in Deliver", "Plugin not installed; Resolve not restarted; you have the Free version, not Studio; unsupported system", "Reinstall the package; close Resolve, wait at least 20 seconds, then reopen it; check for the Studio version"],
        ["The export does not start", "License not activated; invalid Advanced Params; odd width or height", "Enter the activation code; clear Advanced Params; use even dimensions"],
        ["The image looks washed out or too contrasty", "Data Levels on Full for an SDR file; wrong Output Color Space", "Data Levels: Video; check Output Color Space"],
        ["HDR looks washed out on an SDR screen", "Normal behavior: the screen does no tone mapping", "Check on a real HDR screen; for SDR deliver a separate version"],
        ["Banding in the sky or gradients", "8-bit quantization; CRF too high", "Use the 10-bit variant; lower CRF; add `aq-mode=3`; add a little grain in Resolve"],
        ["File too large", "CRF too low; grainy content; keyframes too frequent", "Raise CRF; preset slower; use x265; keyframe 2–4 s"],
        ["File too small or with visible loss", "CRF too high; preset too fast", "Lower CRF; preset slow; check Target Bitrate"],
        ["The TV or phone does not play the file", "10-bit or 4:2:2 H.264; level too high; PCM audio", "Use 8-bit 4:2:0 (or H.265 Main10 4:2:0); Level 4.1; AAC audio through Resolve's format"],
        ["The platform does not recognize the HDR", "Resolve format (no metadata in the container); Output Color Space is not PQ; HDR10 Metadata Off", "Use GDC MP4/QuickTime/Matroska; Rec.2100 ST2084; HDR10 Metadata: On"],
        ["No audio when playing an MP4", "PCM audio in MP4 (ipcm), weak support", "Use GDC Matroska or GDC QuickTime; or Resolve's MP4 with AAC"],
        ["The export is very slow", "Slow preset; x265; high resolution", "Faster preset; hardware for previews; lower the resolution"],
        ["NVENC variants do not appear on Mac", "NVENC exists only with an NVIDIA GPU on Windows", "Normal; use VideoToolbox on Mac"],
        ["\"Cannot add video track to clip\" message", "You chose a GDC format with a codec that is not GDC H.264/H.265", "Choose a GDC codec in the GDC format or use a Resolve format"],
    ], widths: [0.26, 0.34, 0.40]),
    .h2("13.1 Checking an exported file"),
    .p("With a free tool such as **MediaInfo** or **ffprobe** you can check what the file contains: codec, profile, bit depth, color tags (primaries, transfer, matrix), HDR metadata (Mastering display, Content light level) and the audio. For a correct HDR10 export you should see the SMPTE ST 2084 transfer, BT.2020 primaries and, in the GDC formats, the mastering and light-level metadata as well."),
    .code("ffprobe -v error -show_entries stream=codec_name,profile,pix_fmt,color_primaries,color_transfer,color_space:stream_side_data file.mp4"),
] }

func en14() -> [Block] { [
    .h1("14. Known limits and what has been verified"),
    .p("This is the honest picture of the plugin's state at version 1.7.0. \"Verified\" means tested through a real export in DaVinci Resolve Studio 21.1 on macOS Apple Silicon, with the resulting file checked."),
    .table(headers: ["Feature", "Status"], rows: [
        ["x264 and x265, 8-bit 4:2:0", "Verified"],
        ["Apple VideoToolbox H.264 and H.265", "Verified"],
        ["NVIDIA NVENC", "Verified in earlier versions on Windows with an NVIDIA GPU; not re-verified at 1.7.0"],
        ["x264 High10 and x265 Main10 (10-bit 4:2:0)", "Verified"],
        ["x264 and x265 4:2:2 10-bit", "Verified (including the order of the color planes)"],
        ["PQ, HLG, P3-D65, P3-DCI, Rec.709 tags", "Verified"],
        ["HDR10 in the stream (x264 and x265; 4:2:0 and 4:2:2)", "Verified on all four combinations"],
        ["Mastering Primaries: P3-D65", "Verified"],
        ["Mastering Primaries: Rec.2020", "**Not tested** in Resolve"],
        ["GDC QuickTime, GDC MP4, GDC Matroska (x265 4:2:2 10-bit, PQ, HDR10)", "Verified, with HDR in the container and PCM audio"],
        ["H.264 codec in the GDC formats", "**Not tested**"],
        ["\"Export Audio\" unchecked in the GDC formats", "**Not tested**"],
        ["Windows: loading the plugin", "Verified automatically at release"],
        ["Windows: export in Resolve, including the GDC formats", "**Not tested**"],
        ["Start timecode and markers in the GDC formats", "Not implemented"],
        ["AAC in the GDC formats", "Not implemented"],
        ["Intel Mac, Linux", "Not supported"],
    ], widths: [0.62, 0.38]),
    .note(.info, "What is marked \"Not tested\" does not mean it does not work, only that it has not been verified through a real export. If you use it, test on a short clip first."),
] }

func enAnnex() -> [Block] { [
    .h1("Annex A. Pre-export checklist"),
    .numbered([
        "The timeline is finished; frame rate and resolution are the intended ones (even width and height).",
        "Output Color Space matches the destination (Rec.709, Rec.2100 ST2084 or Rec.2100 HLG).",
        "You chose the format (Resolve's or GDC) suited to the audio and metadata you need.",
        "You chose the right codec variant: 8-bit 4:2:0 for compatibility, 10-bit for HDR, 4:2:2 only for post-production.",
        "Preset: slow for delivery; Level: Auto; Tune: none, unless you have a specific reason.",
        "Rate Control: CRF (or Target Bitrate if the platform imposes a bitrate).",
        "Data Levels: Video.",
        "For HDR10: HDR10 Metadata On, the real mastering monitor, MaxCLL/MaxFALL measured or 0.",
        "You exported a short fragment and checked it on the target device (and, if needed, with MediaInfo/ffprobe).",
        "Only then do you export the whole film.",
    ]),
    .h1("Annex B. Glossary"),
    .table(headers: ["Term", "Explanation"], rows: [
        ["CRF", "Constant Rate Factor: constant-quality encoding mode; lower number = better quality, larger file"],
        ["QP", "Quantization parameter: how much each frame is compressed"],
        ["Keyframe / GOP", "A keyframe (complete image) / the group of frames between two keyframes"],
        ["B-frame", "A frame coded from the frames before and after it; helps compression"],
        ["Profile / Level", "Set of permitted tools / limits on resolution, frames and bitrate; determines compatibility with devices"],
        ["Chroma 4:2:0 / 4:2:2", "How much color information is kept relative to luminance; 4:2:2 keeps more vertically"],
        ["Rec.709", "SDR standard for HD television; gamma 2.4 (BT.1886)"],
        ["Rec.2020", "The wide color gamut used for HDR and UHD"],
        ["P3-D65 / P3-DCI", "The P3 color gamut with a D65 white point / with the DCI cinema white point"],
        ["PQ (SMPTE ST 2084)", "The HDR transfer function based on absolute luminance; used by HDR10"],
        ["HLG", "Hybrid Log-Gamma: an HDR transfer function compatible with SDR screens; used in television"],
        ["HDR10", "PQ + Rec.2020 + 10-bit + static metadata (mastering display, MaxCLL, MaxFALL)"],
        ["Mastering display", "The characteristics of the monitor you graded on (primaries, luminance)"],
        ["MaxCLL / MaxFALL", "The maximum luminance of any pixel / the maximum average luminance of any frame, over the whole film, in nits"],
        ["Nit", "Unit of luminance (candela per square meter)"],
        ["SEI", "An extra message in the video stream; here it carries the HDR metadata"],
        ["mdcv / clli", "Container boxes that carry the mastering display and the content light level"],
        ["Container", "The file that packages video and audio (MOV, MP4, MKV)"],
        ["Data Levels (Video/Full)", "The value range: Video (16–235 at 8-bit) or Full (0–255)"],
    ], widths: [0.26, 0.74]),
    .h1("Annex C. Quick reference for levels"),
    .table(headers: ["Resolution and rate", "H.264 (Level)", "H.265 (Level)"], rows: [
        ["1280×720, 30 fps", "3.1", "3.1"],
        ["1920×1080, 30 fps", "4.0 / 4.1", "4.0 / 4.1"],
        ["1920×1080, 60 fps", "4.2", "4.1"],
        ["2560×1440, 30 fps", "5.0", "5.0"],
        ["3840×2160, 30 fps", "5.1", "5.0"],
        ["3840×2160, 60 fps", "5.2", "5.1"],
    ], widths: [0.40, 0.30, 0.30]),
    .p("When you are not sure, leave **Level: Auto**."),
] }
