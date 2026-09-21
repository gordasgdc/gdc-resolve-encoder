// Motor de așezare în pagină pentru whitepaper (CoreText + CoreGraphics, fără NSTextBlock:
// paginarea NSLayoutManager intră în buclă infinită pe casete între pagini).
// Rulare: docs/whitepaper/build-whitepaper.sh  (compilează main.swift + content.swift)
import Foundation
import AppKit
import CoreText
import PDFKit

// ───────── model de conținut ─────────
enum Callout { case info, warn, tip }

enum Block {
    case h1(String), h2(String), h3(String)
    case p(String)
    case bullets([String])
    case numbered([String])
    case table(headers: [String], rows: [[String]], widths: [CGFloat])
    case code(String)
    case note(Callout, String)
    case space(CGFloat)
    case pageBreak
}

// ───────── paletă și fonturi (tema „Shift”: cupru/amber) ─────────
func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255, blue: CGFloat(hex & 255) / 255, alpha: a)
}
let cText = rgb(0x1F2328), cMuted = rgb(0x5B6470), cAccent = rgb(0xB4691F), cAmber = rgb(0xE39A2D)
let cDark = rgb(0x14161A), cLine = rgb(0xD9D4CB), cAlt = rgb(0xF7F5F1), cHead = rgb(0x2A2F36)
let cCodeBg = rgb(0xF1EFEA)

func font(_ name: String, _ size: CGFloat) -> NSFont { NSFont(name: name, size: size) ?? NSFont.systemFont(ofSize: size) }
let fBody = "HelveticaNeue", fBold = "HelveticaNeue-Bold", fMono = "Menlo-Regular"

// Markup inline: **bold**, `cod`
func attributed(_ text: String, size: CGFloat, color: NSColor = cText, boldAll: Bool = false, lineSpacing: CGFloat = 2.2,
                headIndent: CGFloat = 0, firstIndent: CGFloat = 0, tab: CGFloat? = nil, align: NSTextAlignment = .left) -> NSAttributedString {
    let out = NSMutableAttributedString()
    let ps = NSMutableParagraphStyle()
    ps.lineSpacing = lineSpacing; ps.alignment = align; ps.lineBreakMode = .byWordWrapping
    ps.headIndent = headIndent; ps.firstLineHeadIndent = firstIndent
    if let t = tab { ps.tabStops = [NSTextTab(textAlignment: .left, location: t, options: [:])] }
    var bold = boldAll, mono = false
    var buf = ""
    func flush() {
        guard !buf.isEmpty else { return }
        let f: NSFont = mono ? font(fMono, size * 0.92) : font(bold ? fBold : fBody, size)
        out.append(NSAttributedString(string: buf, attributes: [
            .font: f, .foregroundColor: mono ? cAccent : color, .paragraphStyle: ps]))
        buf = ""
    }
    var i = text.startIndex
    while i < text.endIndex {
        if text[i...].hasPrefix("**") { flush(); bold.toggle(); i = text.index(i, offsetBy: 2); continue }
        if text[i] == "`" { flush(); mono.toggle(); i = text.index(after: i); continue }
        buf.append(text[i]); i = text.index(after: i)
    }
    flush()
    return out
}

// ───────── randare ─────────
final class Renderer {
    let W: CGFloat = 595.28, H: CGFloat = 841.89
    let mL: CGFloat = 54, mR: CGFloat = 54, mTop: CGFloat = 66, mBottom: CGFloat = 62
    var cw: CGFloat { W - mL - mR }
    var pageBottom: CGFloat { H - mBottom }

    let draw: Bool
    var ctx: CGContext?
    var pageNo = 0
    var y: CGFloat = 0
    var toc: [(level: Int, title: String, page: Int)] = []
    let tocPages: Int
    let docTitle: String, docVersion: String

    init(draw: Bool, url: URL?, tocPages: Int, title: String, version: String) {
        self.draw = draw; self.tocPages = tocPages; self.docTitle = title; self.docVersion = version
        if draw, let url = url {
            var box = CGRect(x: 0, y: 0, width: W, height: H)
            let info: [CFString: Any] = [kCGPDFContextTitle: title, kCGPDFContextAuthor: "GDC", kCGPDFContextCreator: "GDC Resolve Encoder whitepaper generator"]
            ctx = CGContext(url as CFURL, mediaBox: &box, info as CFDictionary)
        }
    }

    // pagini
    func beginPage(dark: Bool = false) {
        pageNo += 1
        guard draw, let c = ctx else { y = mTop; return }
        c.beginPDFPage(nil)
        if dark {
            c.setFillColor(cDark.cgColor); c.fill(CGRect(x: 0, y: 0, width: W, height: H))
        } else {
            // antet + subsol
            let head = attributed(docTitle, size: 8, color: cMuted)
            drawLine(head, x: mL, top: 34, width: cw)
            c.setStrokeColor(cLine.cgColor); c.setLineWidth(0.5)
            c.move(to: CGPoint(x: mL, y: H - 50)); c.addLine(to: CGPoint(x: W - mR, y: H - 50)); c.strokePath()
            c.move(to: CGPoint(x: mL, y: 46)); c.addLine(to: CGPoint(x: W - mR, y: 46)); c.strokePath()
            let foot = attributed("v\(docVersion)  ·  \(L.page) \(pageNo)", size: 8, color: cMuted, align: .right)
            drawLine(foot, x: mL, top: H - 40, width: cw)
        }
        y = mTop
    }
    func endPage() { if draw { ctx?.endPDFPage() } }
    func newPage() { endPage(); beginPage() }

    func drawLine(_ s: NSAttributedString, x: CGFloat, top: CGFloat, width: CGFloat) {
        guard draw, let c = ctx else { return }
        let fs = CTFramesetterCreateWithAttributedString(s)
        let h = CTFramesetterSuggestFrameSizeWithConstraints(fs, CFRange(location: 0, length: 0), nil, CGSize(width: width, height: 1000), nil).height + 2
        let path = CGPath(rect: CGRect(x: 0, y: 0, width: width, height: h), transform: nil)
        let frame = CTFramesetterCreateFrame(fs, CFRange(location: 0, length: 0), path, nil)
        c.saveGState(); c.translateBy(x: x, y: H - top - h); c.textMatrix = .identity
        CTFrameDraw(frame, c); c.restoreGState()
    }

    func height(_ s: NSAttributedString, width: CGFloat) -> CGFloat {
        let fs = CTFramesetterCreateWithAttributedString(s)
        return ceil(CTFramesetterSuggestFrameSizeWithConstraints(fs, CFRange(location: 0, length: 0), nil, CGSize(width: width, height: 100000), nil).height) + 1
    }

    func drawFrame(_ fs: CTFramesetter, range: CFRange, x: CGFloat, top: CGFloat, width: CGFloat, h: CGFloat) {
        guard draw, let c = ctx else { return }
        let path = CGPath(rect: CGRect(x: 0, y: 0, width: width, height: h), transform: nil)
        let frame = CTFramesetterCreateFrame(fs, range, path, nil)
        c.saveGState(); c.translateBy(x: x, y: H - top - h); c.textMatrix = .identity
        CTFrameDraw(frame, c); c.restoreGState()
    }

    // paragraf cu spargere între pagini
    func paragraph(_ s: NSAttributedString, x: CGFloat? = nil, width: CGFloat? = nil, after: CGFloat = 6) {
        let px = x ?? mL, pw = width ?? cw
        var rem = s
        while rem.length > 0 {
            let avail = pageBottom - y
            let fs = CTFramesetterCreateWithAttributedString(rem)
            let full = height(rem, width: pw)
            if full <= avail { drawFrame(fs, range: CFRange(location: 0, length: 0), x: px, top: y, width: pw, h: full); y += full + after; return }
            if avail < 34 { newPage(); continue }
            let path = CGPath(rect: CGRect(x: 0, y: 0, width: pw, height: avail), transform: nil)
            let frame = CTFramesetterCreateFrame(fs, CFRange(location: 0, length: 0), path, nil)
            let vr = CTFrameGetVisibleStringRange(frame)
            if vr.length == 0 { newPage(); continue }
            drawFrame(fs, range: CFRange(location: 0, length: 0), x: px, top: y, width: pw, h: avail)
            rem = rem.attributedSubstring(from: NSRange(location: vr.length, length: rem.length - vr.length))
            newPage()
        }
    }

    func need(_ h: CGFloat) { if pageBottom - y < h { newPage() } }

    // blocuri
    func heading(_ level: Int, _ t: String) {
        if level == 1 { if y > mTop + 1 || pageNo == 0 { newPage() } }
        else { need(level == 2 ? 120 : 90) }
        toc.append((level, t, pageNo))
        switch level {
        case 1:
            let s = attributed(t, size: 22, color: cText, boldAll: true, lineSpacing: 2)
            paragraph(s, after: 4)
            if draw, let c = ctx { c.setFillColor(cAmber.cgColor); c.fill(CGRect(x: mL, y: H - y - 2, width: 64, height: 3)) }
            y += 16
        case 2:
            y += 8
            paragraph(attributed(t, size: 14.5, color: cAccent, boldAll: true), after: 5)
        default:
            y += 4
            paragraph(attributed(t, size: 11.2, color: cText, boldAll: true), after: 3)
        }
    }

    func bulletsBlock(_ items: [String], numbered: Bool) {
        for (i, it) in items.enumerated() {
            let mark = numbered ? "\(i + 1)." : "•"
            paragraph(attributed("\(mark)\t\(it)", size: 10, headIndent: 18, firstIndent: 4, tab: 18), x: mL + 4, width: cw - 4, after: 2.6)
        }
        y += 4
    }

    func tableBlock(_ headers: [String], _ rows: [[String]], _ widths: [CGFloat]) {
        let total = widths.reduce(0, +)
        let cols = widths.map { $0 / total * cw }
        let pad: CGFloat = 4.5, fs: CGFloat = 8.6
        func rowHeight(_ cells: [String], bold: Bool) -> CGFloat {
            var mh: CGFloat = 0
            for (i, t) in cells.enumerated() { mh = max(mh, height(attributed(t, size: fs, boldAll: bold, lineSpacing: 1.4), width: cols[i] - 2 * pad)) }
            return mh + 2 * pad
        }
        func drawRow(_ cells: [String], head: Bool, alt: Bool, h: CGFloat) {
            if draw, let c = ctx {
                c.setFillColor((head ? cHead : (alt ? cAlt : NSColor.white)).cgColor)
                c.fill(CGRect(x: mL, y: H - y - h, width: cw, height: h))
                c.setStrokeColor(cLine.cgColor); c.setLineWidth(0.4)
                c.stroke(CGRect(x: mL, y: H - y - h, width: cw, height: h))
            }
            var cx = mL
            for (i, t) in cells.enumerated() {
                let a = attributed(t, size: fs, color: head ? .white : cText, boldAll: head, lineSpacing: 1.4)
                let f = CTFramesetterCreateWithAttributedString(a)
                drawFrame(f, range: CFRange(location: 0, length: 0), x: cx + pad, top: y + pad, width: cols[i] - 2 * pad, h: h - 2 * pad)
                cx += cols[i]
            }
            y += h
        }
        let hh = rowHeight(headers, bold: true)
        need(hh + 40)
        drawRow(headers, head: true, alt: false, h: hh)
        for (ri, r) in rows.enumerated() {
            let rh = rowHeight(r, bold: false)
            if pageBottom - y < rh { newPage(); drawRow(headers, head: true, alt: false, h: hh) }
            drawRow(r, head: false, alt: ri % 2 == 1, h: rh)
        }
        y += 10
    }

    func codeBlock(_ t: String) {
        let s = attributed(t, size: 9, color: cText, lineSpacing: 1.6)
        let m = NSMutableAttributedString(attributedString: s)
        m.addAttribute(.font, value: font(fMono, 8.2), range: NSRange(location: 0, length: m.length))
        m.addAttribute(.foregroundColor, value: cText, range: NSRange(location: 0, length: m.length))
        let h = height(m, width: cw - 16) + 12
        need(h + 6)
        if draw, let c = ctx { c.setFillColor(cCodeBg.cgColor); c.fill(CGRect(x: mL, y: H - y - h, width: cw, height: h))
            c.setFillColor(cAmber.cgColor); c.fill(CGRect(x: mL, y: H - y - h, width: 2.5, height: h)) }
        let f = CTFramesetterCreateWithAttributedString(m)
        drawFrame(f, range: CFRange(location: 0, length: 0), x: mL + 10, top: y + 6, width: cw - 16, h: h - 8)
        y += h + 8
    }

    func noteBlock(_ kind: Callout, _ t: String) {
        let (bg, bar, label): (NSColor, NSColor, String) = {
            switch kind {
            case .info: return (rgb(0xE8EEF5), rgb(0x6B8CB0), L.info)
            case .warn: return (rgb(0xFBECEA), rgb(0xC4453A), L.warn)
            case .tip:  return (rgb(0xEAF4EA), rgb(0x4C8C4A), L.tip)
            }
        }()
        let s = attributed("**\(label).** " + t, size: 9.6, lineSpacing: 2)
        let h = height(s, width: cw - 22) + 14
        need(h + 6)
        if draw, let c = ctx { c.setFillColor(bg.cgColor); c.fill(CGRect(x: mL, y: H - y - h, width: cw, height: h))
            c.setFillColor(bar.cgColor); c.fill(CGRect(x: mL, y: H - y - h, width: 3.5, height: h)) }
        let f = CTFramesetterCreateWithAttributedString(s)
        drawFrame(f, range: CFRange(location: 0, length: 0), x: mL + 14, top: y + 7, width: cw - 22, h: h - 10)
        y += h + 8
    }

    func cover() {
        guard draw, let c = ctx else { return }
        c.setFillColor(cAmber.cgColor); c.fill(CGRect(x: mL, y: H - 250, width: 84, height: 4))
        drawLine(attributed("GDC", size: 15, color: cAmber, boldAll: true), x: mL, top: 120, width: cw)
        drawLine(attributed("GDC Resolve\nEncoder", size: 46, color: .white, boldAll: true, lineSpacing: 4), x: mL, top: 160, width: cw)
        drawLine(attributed(L.coverSub, size: 17, color: rgb(0xEDEFF2)), x: mL, top: 275, width: cw)
        drawLine(attributed(L.coverDesc, size: 11.5, color: rgb(0xA9B0BA), lineSpacing: 3), x: mL, top: 310, width: cw)
        drawLine(attributed(String(format: L.coverVer, docVersion), size: 11, color: cAmber, boldAll: true), x: mL, top: H - 120, width: cw)
        drawLine(attributed(L.disclaimer, size: 8.5, color: rgb(0x8A929D)), x: mL, top: H - 96, width: cw - 60)
    }

}

// construiește PDF-ul în două treceri: măsurare (pagini pentru cuprins), apoi desen final
func buildPDF(blocks: [Block], out: URL, version: String, title: String) -> (pages: Int, toc: [(level: Int, title: String, page: Int)]) {
    // 1) măsurare (fără desen) pentru a afla paginile fiecărui titlu și numărul de pagini de cuprins
    var tocPages = 2
    var entries: [(level: Int, title: String, page: Int)] = []
    for _ in 0..<3 {
        let r = Renderer(draw: false, url: nil, tocPages: tocPages, title: title, version: version)
        r.renderMeasure(blocks)
        entries = r.toc
        let perPage = 44
        let need = max(1, Int(ceil(Double(entries.count) / Double(perPage))))
        if need == tocPages { break }
        tocPages = need
    }
    // 2) desen final
    let r = Renderer(draw: true, url: out, tocPages: tocPages, title: title, version: version)
    r.renderFinal(blocks, entries: entries)
    return (r.pageNo, entries)
}

extension Renderer {
    func renderMeasure(_ blocks: [Block]) {
        pageNo = 1                      // coperta
        pageNo += tocPages              // cuprins
        beginPage()
        renderBody(blocks)
    }
    func renderBody(_ blocks: [Block]) {
        for b in blocks {
            switch b {
            case .h1(let t): heading(1, t)
            case .h2(let t): heading(2, t)
            case .h3(let t): heading(3, t)
            case .p(let t): paragraph(attributed(t, size: 10), after: 6)
            case .bullets(let a): bulletsBlock(a, numbered: false)
            case .numbered(let a): bulletsBlock(a, numbered: true)
            case .table(let h, let r, let w): tableBlock(h, r, w)
            case .code(let t): codeBlock(t)
            case .note(let k, let t): noteBlock(k, t)
            case .space(let s): y += s
            case .pageBreak: newPage()
            }
        }
    }
    func renderFinal(_ blocks: [Block], entries: [(level: Int, title: String, page: Int)]) {
        beginPage(dark: true); cover(); endPage()
        // cuprins
        var idx = 0
        for tp in 0..<tocPages {
            beginPage()
            if tp == 0 {
                paragraph(attributed(L.toc, size: 22, color: cText, boldAll: true), after: 6)
                if let c = ctx { c.setFillColor(cAmber.cgColor); c.fill(CGRect(x: mL, y: H - y - 2, width: 64, height: 3)) }
                y += 16
            }
            var n = 0
            while idx < entries.count && n < 44 && y < pageBottom - 14 {
                let e = entries[idx]
                let ind: CGFloat = e.level == 1 ? 0 : (e.level == 2 ? 14 : 28)
                let size: CGFloat = e.level == 1 ? 10.2 : 9
                let a = attributed(e.title, size: size, color: e.level == 1 ? cText : cMuted, boldAll: e.level == 1, lineSpacing: 0)
                drawLine(a, x: mL + ind, top: y, width: cw - ind - 30)
                drawLine(attributed("\(e.page)", size: size, color: cAccent, boldAll: true, lineSpacing: 0, align: .right), x: mL, top: y, width: cw)
                y += e.level == 1 ? 14.5 : 12.4
                idx += 1; n += 1
            }
            endPage()
        }
        beginPage()
        renderBody(blocks)
        endPage()
        ctx?.closePDF()
    }
}

// ───────── verificare cu PDFKit (rezumat, fără a randa paginile) ─────────
func verify(url: URL, requiredPhrases: [String], forbidden: [String], expectedPages: Int) -> Bool {
    guard let doc = PDFDocument(url: url) else { print("EROARE: PDF ilizibil"); return false }
    var ok = true
    print("\(L.pagesLbl): \(doc.pageCount) (\(expectedPages))")
    if doc.pageCount != expectedPages { print("  EROARE: număr de pagini diferit"); ok = false }
    var empty: [Int] = []
    for i in 0..<doc.pageCount { if (doc.page(at: i)?.string ?? "").trimmingCharacters(in: .whitespacesAndNewlines).count < 20 { empty.append(i + 1) } }
    print("\(L.noText): \(empty.isEmpty ? "niciuna" : empty.map(String.init).joined(separator: ","))")
    if !empty.isEmpty { ok = false }
    // margini: cutia de text a fiecărei pagini trebuie să rămână în interiorul zonei utile
    var marginBad: [Int] = []
    for i in 0..<doc.pageCount {
        guard let pg = doc.page(at: i), i > 0 else { continue }          // coperta e pe fundal întunecat, fără regula de margini
        let box = pg.bounds(for: .mediaBox)
        guard let sel = pg.selection(for: box) else { continue }
        var minX = CGFloat.greatestFiniteMagnitude, maxX: CGFloat = 0, minY = CGFloat.greatestFiniteMagnitude, maxY: CGFloat = 0
        for line in sel.selectionsByLine() {
            let r = line.bounds(for: pg)
            if r.width < 1 { continue }
            minX = min(minX, r.minX); maxX = max(maxX, r.maxX); minY = min(minY, r.minY); maxY = max(maxY, r.maxY)
        }
        if minX < 40 || maxX > box.width - 40 || minY < 24 || maxY > box.height - 24 { marginBad.append(i + 1) }
    }
    print("\(L.outMargins): \(marginBad.isEmpty ? "niciuna" : marginBad.map(String.init).joined(separator: ","))")
    if !marginBad.isEmpty { ok = false }
    let full = doc.string ?? ""
    var missing: [String] = []
    for p in requiredPhrases where !full.contains(p) { missing.append(p) }
    print("\(L.sectionsFound): \(requiredPhrases.count - missing.count)/\(requiredPhrases.count)")
    if !missing.isEmpty { print("  LIPSESC: \(missing)"); ok = false }
    var bad: [String] = []
    for f in forbidden {
        if let re = try? NSRegularExpression(pattern: f, options: [.caseInsensitive]),
           re.firstMatch(in: full, range: NSRange(full.startIndex..., in: full)) != nil { bad.append(f) }
    }
    print("\(L.forbiddenLbl): \(bad.isEmpty ? "niciunul" : bad.joined(separator: ", "))")
    if !bad.isEmpty { ok = false }
    let words = full.split { $0.isWhitespace }.count
    print("Cuvinte: ~\(words)")
    return ok
}

// ───────── punct de intrare ─────────
let args = CommandLine.arguments
let lang = args.count > 1 ? args[1] : "ro"
let blocks = setLanguage(lang)
let outPath = args.count > 2 ? args[2] : L.outName
let out = URL(fileURLWithPath: outPath)
let version = "1.7.0"
let title = L.docTitle
let res = buildPDF(blocks: blocks, out: out, version: version, title: title)
let sections = res.toc.filter { $0.level == 1 }.map { $0.title }
print("[\(lang)] chapters: \(sections.count), TOC entries: \(res.toc.count)")
let ok = verify(url: out, requiredPhrases: sections + L.required, forbidden: L.forbidden, expectedPages: res.pages)
print(ok ? "VERIFY OK → \(outPath)" : "VERIFY FAILED")
exit(ok ? 0 : 1)
