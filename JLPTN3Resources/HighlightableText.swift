import SwiftUI

// MARK: - 짚을 수 있는 일본어 본문
//
// 낱말 하나하나가 버튼이다. 누르면 형광펜이 그어지고 단어장에 담긴다.
// 줄바꿈을 지키기 위해 «줄 → 낱말» 두 단계로 나눠 그린다.

struct HighlightableText: View {
    let text: String
    let fontSize: CGFloat
    /// 지금 형광펜이 그어진 단어들
    let highlighted: Set<String>
    let onTap: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            ForEach(Array(text.components(separatedBy: "\n").enumerated()), id: \.offset) { _, line in
                if line.trimmingCharacters(in: .whitespaces).isEmpty {
                    // 빈 줄은 문단 사이 간격으로 남긴다
                    Color.clear.frame(height: fontSize * 0.5)
                } else {
                    FlowLayout(spacing: 0, lineSpacing: 6) {
                        ForEach(JapaneseText.units(of: line)) { unit in
                            tokenView(unit)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func tokenView(_ unit: JapaneseText.Unit) -> some View {
        if let word = unit.word {
            let on = highlighted.contains(word)
            Button {
                onTap(word)
            } label: {
                Text(unit.display)
                    .font(.system(size: fontSize))
                    .foregroundStyle(Theme.textPrimary)
                    // 형광펜 — 글자를 덮지 않도록 옅게 깔고 아래에 선을 하나 더 둔다.
                    // 좌우 여백을 두면 낱말 사이가 벌어져 띄어쓰기처럼 보이므로 넣지 않는다.
                    .background(
                        ZStack(alignment: .bottom) {
                            if on {
                                Theme.highlight.opacity(0.5)
                                Rectangle()
                                    .fill(Theme.highlight)
                                    .frame(height: 2)
                            }
                        }
                    )
            }
            .buttonStyle(.plain)
        } else {
            Text(unit.display)
                .font(.system(size: fontSize))
                .foregroundStyle(Theme.textPrimary)
        }
    }
}

// MARK: - 흘려 담기 레이아웃
//
// 낱말을 가로로 늘어놓다가 폭이 모자라면 다음 줄로 넘긴다.

struct FlowLayout: Layout {
    var spacing: CGFloat = 0
    var lineSpacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += lineHeight + lineSpacing
                lineHeight = 0
            }
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize,
                       subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += lineHeight + lineSpacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading,
                          proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
