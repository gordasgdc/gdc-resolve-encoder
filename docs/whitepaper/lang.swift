import Foundation

// Texte ale motorului (copertă, subsol, cuprins, etichete) pentru fiecare limbă.
struct Strings {
    var toc: String, page: String, info: String, warn: String, tip: String
    var coverSub: String, coverDesc: String, coverVer: String, disclaimer: String
    var docTitle: String, outName: String
    var sectionsFound: String, pagesLbl: String, noText: String, outMargins: String, forbiddenLbl: String
    var forbidden: [String]
    var required: [String]
}

let commonForbidden = ["Cristi", "\\.cpp", "\\.swift", "CLAUDE"]

let roStrings = Strings(
    toc: "Cuprins", page: "pagina", info: "De reținut", warn: "Atenție", tip: "Sfat",
    coverSub: "Whitepaper tehnic și ghid complet de configurare",
    coverDesc: "Codecuri H.264 și H.265 (x264 / x265), 10-bit, 4:2:2, HDR10 și formate proprii\npentru DaVinci Resolve Studio",
    coverVer: "Versiunea %@  ·  21 septembrie 2026",
    disclaimer: "Document informativ. Valorile de export sunt puncte de plecare; verifică specificațiile curente ale fiecărei platforme înainte de livrare.",
    docTitle: "GDC Resolve Encoder — Whitepaper tehnic", outName: "GDC_Resolve_Encoder_Whitepaper_RO.pdf",
    sectionsFound: "Secțiuni obligatorii", pagesLbl: "Pagini", noText: "Pagini fără text", outMargins: "Pagini cu text în afara marginilor", forbiddenLbl: "Cuvinte/șabloane interzise găsite",
    forbidden: ["preț", "cumpăr", "vânzare", "\\bprice\\b", "\\bbuy\\b", "\\bsale\\b"] + commonForbidden,
    required: ["HDR10", "MaxCLL", "YouTube", "TikTok", "Instagram", "Facebook", "GDC MP4", "x265"])

let enStrings = Strings(
    toc: "Contents", page: "page", info: "Note", warn: "Warning", tip: "Tip",
    coverSub: "Technical whitepaper and complete configuration guide",
    coverDesc: "H.264 and H.265 codecs (x264 / x265), 10-bit, 4:2:2, HDR10 and own formats\nfor DaVinci Resolve Studio",
    coverVer: "Version %@  ·  September 21, 2026",
    disclaimer: "Informational document. Export values are starting points; check each platform's current specifications before delivery.",
    docTitle: "GDC Resolve Encoder — Technical whitepaper", outName: "GDC_Resolve_Encoder_Whitepaper_EN.pdf",
    sectionsFound: "Required sections", pagesLbl: "Pages", noText: "Pages without text", outMargins: "Pages with text outside margins", forbiddenLbl: "Forbidden words/patterns found",
    forbidden: ["\\bprice\\b", "\\bpricing\\b", "\\bbuy\\b", "\\bpurchase\\b", "\\bsale\\b", "\\bsales\\b"] + commonForbidden,
    required: ["HDR10", "MaxCLL", "YouTube", "TikTok", "Instagram", "Facebook", "GDC MP4", "x265"])

let esStrings = Strings(
    toc: "Contenido", page: "página", info: "A tener en cuenta", warn: "Atención", tip: "Consejo",
    coverSub: "Whitepaper técnico y guía completa de configuración",
    coverDesc: "Códecs H.264 y H.265 (x264 / x265), 10-bit, 4:2:2, HDR10 y formatos propios\npara DaVinci Resolve Studio",
    coverVer: "Versión %@  ·  21 de septiembre de 2026",
    disclaimer: "Documento informativo. Los valores de exportación son puntos de partida; comprueba las especificaciones vigentes de cada plataforma antes de entregar.",
    docTitle: "GDC Resolve Encoder — Whitepaper técnico", outName: "GDC_Resolve_Encoder_Whitepaper_ES.pdf",
    sectionsFound: "Secciones obligatorias", pagesLbl: "Páginas", noText: "Páginas sin texto", outMargins: "Páginas con texto fuera de los márgenes", forbiddenLbl: "Palabras/patrones prohibidos encontrados",
    forbidden: ["\\bprecio\\b", "\\bprecios\\b", "\\bcomprar\\b", "\\bcompra\\b", "\\bventa\\b", "\\bventas\\b"] + commonForbidden,
    required: ["HDR10", "MaxCLL", "YouTube", "TikTok", "Instagram", "Facebook", "GDC MP4", "x265"])

var L = roStrings

func setLanguage(_ lang: String) -> [Block] {
    switch lang {
    case "en": L = enStrings; return whitepaperBlocksEN()
    case "es": L = esStrings; return whitepaperBlocksES()
    default:   L = roStrings; return whitepaperBlocks()
    }
}
