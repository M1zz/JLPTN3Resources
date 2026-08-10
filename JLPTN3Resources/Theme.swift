import SwiftUI
import UIKit

// MARK: - Adaptive Color Helpers

extension Color {
    /// 시스템 외관(라이트/다크)에 따라 자동 전환되는 색.
    static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }

    static func adaptive(light: String, dark: String) -> Color {
        adaptive(light: UIColor(Color(hex: light)), dark: UIColor(Color(hex: dark)))
    }

    /// 강조색(브랜드·시맨틱 컬러). 다크모드에서는 원래 hex 그대로,
    /// 라이트모드에서는 밝은 배경 위 대비를 위해 색조는 유지한 채 어둡게 보정한다.
    init(accentHex hex: String) {
        let base = UIColor(Color(hex: hex))
        self = .adaptive(light: base.darkenedForLightBackground(), dark: base)
    }
}

extension UIColor {
    fileprivate func darkenedForLightBackground() -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard getHue(&h, saturation: &s, brightness: &b, alpha: &a) else { return self }
        // 무채색(흰색·회색)은 채도 보정이 의미 없으므로 명도만 낮춘다.
        let saturation = s < 0.08 ? s : min(s * 1.25, 1)
        return UIColor(hue: h, saturation: saturation, brightness: min(b, 0.72), alpha: a)
    }
}

// MARK: - Semantic Palette

enum Theme {

    // 배경
    static let background = Color.adaptive(light: "F7F4EF", dark: "0A1628")
    static let backgroundElevated = Color.adaptive(light: "FFFFFF", dark: "0F1F3D")

    /// 히어로 배너 — 라이트/다크 모두 어둡게 유지되는 강조 영역
    static let heroBanner = Color.adaptive(light: "17305A", dark: "0F1F3D")
    static let onHeroBanner = Color.white

    /// 학습 카드 앞/뒷면 그라데이션
    static let cardFaceTop = Color.adaptive(light: "FFFFFF", dark: "0F2044")
    static let cardFaceBottom = Color.adaptive(light: "F4F0E9", dark: "0A1628")

    /// 한자 쓰기 칸 배경
    static let canvasCell = Color.adaptive(light: "FFFFFF", dark: "111827")

    // 표면 (카드·칩)
    static let surface = Color.adaptive(
        light: .white,
        dark: UIColor(white: 1, alpha: 0.08)
    )
    static let surfaceSoft = Color.adaptive(
        light: UIColor(white: 0, alpha: 0.035),
        dark: UIColor(white: 1, alpha: 0.04)
    )
    /// 프로그레스 바 트랙
    static let track = Color.adaptive(
        light: UIColor(white: 0, alpha: 0.10),
        dark: UIColor(white: 1, alpha: 0.07)
    )
    static let stroke = Color.adaptive(
        light: UIColor(white: 0, alpha: 0.10),
        dark: UIColor(white: 1, alpha: 0.10)
    )
    /// 배경 장식용 초대형 한자
    static let decoration = Color.adaptive(
        light: UIColor(white: 0, alpha: 0.035),
        dark: UIColor(white: 1, alpha: 0.04)
    )
    static let shadow = Color.adaptive(
        light: UIColor(white: 0, alpha: 0.07),
        dark: UIColor(white: 0, alpha: 0.45)
    )

    // 텍스트
    static let textPrimary = Color.adaptive(light: "1A1A1A", dark: "FFFFFF")
    static let textSecondary = Color.adaptive(
        light: UIColor(white: 0, alpha: 0.66),
        dark: UIColor(white: 1, alpha: 0.70)
    )
    static let textTertiary = Color.adaptive(
        light: UIColor(white: 0, alpha: 0.50),
        dark: UIColor(white: 1, alpha: 0.45)
    )
    static let textQuaternary = Color.adaptive(
        light: UIColor(white: 0, alpha: 0.34),
        dark: UIColor(white: 1, alpha: 0.30)
    )

    // 브랜드
    static let brand = Color(accentHex: "D4A373")
    /// 브랜드 색 위에 올라가는 텍스트/아이콘
    static let onBrand = Color.adaptive(light: "FFFFFF", dark: "0A1628")

    /// PencilKit 펜 잉크 — UIColor가 필요해 별도 제공
    static let inkColor = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.95, green: 0.92, blue: 0.86, alpha: 1)
            : UIColor(red: 0.13, green: 0.14, blue: 0.16, alpha: 1)
    }
}
