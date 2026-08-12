import AppKit

// 학습 카드(플래시카드) 모티프.
// 예전 아이콘은 감색 바탕 + 금색 N3 + 日本語라 «공식 자격 배지»처럼 읽혔다.
// 비공식 학습 도구임이 한눈에 보이도록 카드 두 장이 겹친 모양으로 바꾼다.

let S = 1024

struct Palette {
    let bgTop, bgBottom, cardBack, cardFront, ink, accent, sub: NSColor
}

func hex(_ h: String) -> NSColor {
    var v: UInt64 = 0; Scanner(string: h).scanHexInt64(&v)
    return NSColor(srgbRed: CGFloat((v >> 16) & 0xFF)/255,
                   green: CGFloat((v >> 8) & 0xFF)/255,
                   blue: CGFloat(v & 0xFF)/255, alpha: 1)
}

func render(_ p: Palette, flat: Bool, to path: String) {
    // 1024×1024 픽셀을 정확히 만든다 (NSImage lockFocus는 화면 배율을 따라가 2048이 된다)
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: S, pixelsHigh: S,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                               isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    let gctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = gctx
    let ctx = gctx.cgContext
    let side = CGFloat(S)

    // 배경 (꽉 차게 — 아이콘은 시스템이 모서리를 깎는다)
    if flat {
        p.bgTop.setFill(); CGRect(x: 0, y: 0, width: side, height: side).fill()
    } else {
        NSGradient(colors: [p.bgTop, p.bgBottom])!
            .draw(in: CGRect(x: 0, y: 0, width: side, height: side), angle: -90)
    }

    let cw: CGFloat = 700, ch: CGFloat = 780
    let cx = side/2, cy = side/2

    // 뒤 카드 — 살짝 기울여 «여러 장»을 암시
    ctx.saveGState()
    ctx.translateBy(x: cx, y: cy); ctx.rotate(by: -0.11)
    p.cardBack.setFill()
    NSBezierPath(roundedRect: CGRect(x: -cw/2, y: -ch/2, width: cw, height: ch),
                 xRadius: 72, yRadius: 72).fill()
    ctx.restoreGState()

    // 앞 카드
    ctx.saveGState()
    if !flat {
        ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 36,
                      color: NSColor.black.withAlphaComponent(0.25).cgColor)
    }
    p.cardFront.setFill()
    NSBezierPath(roundedRect: CGRect(x: cx - cw/2, y: cy - ch/2, width: cw, height: ch),
                 xRadius: 72, yRadius: 72).fill()
    ctx.restoreGState()

    // «N3» — 카드 위쪽 절반에
    let n3 = "N3" as NSString
    let n3Attr: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 310, weight: .black),
        .foregroundColor: p.ink,
    ]
    let n3Size = n3.size(withAttributes: n3Attr)
    let n3Y = cy + 40                      // 글자 아래쪽 기준선
    n3.draw(at: NSPoint(x: cx - n3Size.width/2, y: n3Y), withAttributes: n3Attr)

    // 형광펜 밑줄 — 글자 아래에 놓는다 (겹치면 «취소선»처럼 보인다)
    p.accent.setFill()
    NSBezierPath(roundedRect: CGRect(x: cx - 170, y: n3Y - 34, width: 340, height: 24),
                 xRadius: 12, yRadius: 12).fill()

    // 카드 아래 작은 가나 — 공식 표기(日本語) 대신 «단어장»을 뜻하는 가나
    let kana = "たんご" as NSString
    let kanaAttr: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 96, weight: .semibold),
        .foregroundColor: p.sub,
    ]
    let kanaSize = kana.size(withAttributes: kanaAttr)
    kana.draw(at: NSPoint(x: cx - kanaSize.width/2, y: cy - ch/2 + 74),
              withAttributes: kanaAttr)

    NSGraphicsContext.restoreGraphicsState()
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path))
    print("\(path) — \(rep.pixelsWide)x\(rep.pixelsHigh)")
}

let out = CommandLine.arguments[1]
render(Palette(bgTop: hex("EFE6D8"), bgBottom: hex("DDCBAF"), cardBack: hex("C9A87C"),
               cardFront: hex("FFFDF9"), ink: hex("2A2622"), accent: hex("D4A373"),
               sub: hex("9A8B78")), flat: false, to: "\(out)/Icon-1024.png")
render(Palette(bgTop: hex("16233D"), bgBottom: hex("0A1628"), cardBack: hex("2C3E63"),
               cardFront: hex("F4EFE6"), ink: hex("1A1814"), accent: hex("D4A373"),
               sub: hex("8A8172")), flat: false, to: "\(out)/Icon-1024-Dark.png")
render(Palette(bgTop: hex("000000"), bgBottom: hex("000000"), cardBack: hex("4A4A4A"),
               cardFront: hex("E8E8E8"), ink: hex("1C1C1C"), accent: hex("9E9E9E"),
               sub: hex("6E6E6E")), flat: true, to: "\(out)/Icon-1024-Tinted.png")
