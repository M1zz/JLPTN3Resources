import SwiftUI

// MARK: - 학습 현황
//
// 「무엇을 알게 됐고, 무엇이 아직 안 되고, 앞으로 무엇이 남았는가」를 한 화면에서 본다.
// 진도 막대(몇 %)만으로는 어떤 낱말이 약한지 알 수 없어, 낱말 하나하나를 늘어놓는다.
//
// 기준은 자기 평가가 아니라 «실제로 꺼낼 수 있었는가»와 «얼마나 오래 견뎠는가»다.
// 한 번 맞힌 것은 다음 날 잊을 수 있으므로, 일주일 간격을 넘긴 카드만 «알게 된 것»으로 센다.

struct StudyLogView: View {
    @EnvironmentObject private var store: LearningStore

    enum Group: String, CaseIterable, Identifiable {
        case acquired = "알게 된 것"
        case learning = "아직 습득 못함"
        case upcoming = "앞으로 알아야 할 것"
        var id: String { rawValue }

        var short: String {
            switch self {
            case .acquired: return "알게 됨"
            case .learning: return "습득 못함"
            case .upcoming: return "앞으로"
            }
        }

        var color: Color {
            switch self {
            case .acquired: return Color(accentHex: "16A34A")
            case .learning: return Color(accentHex: "D97706")
            case .upcoming: return Color(accentHex: "64748B")
            }
        }

        var icon: String {
            switch self {
            case .acquired: return "checkmark.seal.fill"
            case .learning: return "arrow.triangle.2.circlepath"
            case .upcoming: return "hourglass"
            }
        }

        var mastery: LearningCard.Mastery {
            switch self {
            case .acquired: return .acquired
            case .learning: return .learning
            case .upcoming: return .upcoming
            }
        }

        var hint: String {
            switch self {
            case .acquired: return "일주일 넘는 간격을 견딘 낱말입니다"
            case .learning: return "봤지만 아직 굳지 않았습니다. 틀린 것이 위에 옵니다"
            case .upcoming: return "아직 한 번도 보지 않았습니다. 자주 쓰이는 것부터 나옵니다"
            }
        }
    }

    /// 기본은 «아직 습득 못함» — 이 화면에 오는 이유는 대개 약한 것을 찾기 위해서다
    @State private var group: Group = .learning
    @State private var type: CardType? = nil
    @State private var expanded: String? = nil

    private var counts: [Group: Int] {
        var out: [Group: Int] = [:]
        for g in Group.allCases {
            out[g] = store.cards.filter { $0.mastery == g.mastery }.count
        }
        return out
    }

    private var shown: [LearningCard] {
        let base = store.cards
            .filter { $0.mastery == group.mastery }
            .filter { type == nil || $0.type == type }
        switch group {
        case .learning:
            // 틀린 것을 위로, 그다음 간격이 짧은(= 덜 굳은) 것부터
            return base.sorted {
                let aWrong = $0.lastCorrect == false, bWrong = $1.lastCorrect == false
                if aWrong != bWrong { return aWrong }
                return $0.interval < $1.interval
            }
        case .upcoming:
            // 앞으로 배울 순서 그대로 — 자주 쓰이는 것(level 1)부터
            return base.sorted { $0.level == $1.level ? $0.front < $1.front : $0.level < $1.level }
        case .acquired:
            // 가장 단단한 것부터
            return base.sorted { $0.interval > $1.interval }
        }
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                summary
                typeBar
                Divider().overlay(Theme.stroke)
                list
            }
        }
        .navigationTitle("학습 현황")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: 한 눈에

    private var summary: some View {
        let c = counts
        let total = max(store.cards.count, 1)
        return VStack(spacing: 10) {
            // 세 덩어리의 비율을 한 줄 막대로
            GeometryReader { geo in
                HStack(spacing: 1.5) {
                    ForEach(Group.allCases) { g in
                        let w = geo.size.width * Double(c[g] ?? 0) / Double(total)
                        Rectangle()
                            .fill(g.color)
                            .frame(width: max(0, w))
                    }
                }
                .clipShape(Capsule())
            }
            .frame(height: 10)

            HStack(spacing: 8) {
                ForEach(Group.allCases) { g in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) { group = g }
                    } label: {
                        VStack(spacing: 3) {
                            HStack(spacing: 4) {
                                Image(systemName: g.icon)
                                    .font(.system(size: 9, weight: .bold))
                                Text("\(c[g] ?? 0)")
                                    .font(.system(size: 17, weight: .black, design: .rounded))
                                    .minimumScaleFactor(0.6)
                                    .lineLimit(1)
                            }
                            .foregroundStyle(g.color)
                            Text(g.short)
                                .font(.system(size: 10, weight: group == g ? .bold : .regular))
                                .foregroundStyle(group == g ? g.color : Theme.textTertiary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(g.color.opacity(group == g ? 0.18 : 0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(group == g ? g.color.opacity(0.5) : .clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Text(group.hint)
                .font(.system(size: 11))
                .foregroundStyle(Theme.textQuaternary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    private var typeBar: some View {
        HStack(spacing: 6) {
            chip("전체", active: type == nil, color: Theme.brand) { type = nil }
            chip("어휘", active: type == .vocabulary, color: CardType.vocabulary.color) {
                type = .vocabulary
            }
            chip("문법", active: type == .grammar, color: CardType.grammar.color) {
                type = .grammar
            }
            Spacer()
            Text("\(shown.count)개")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Theme.textQuaternary)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }

    private func chip(_ title: String, active: Bool, color: Color,
                      action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(active ? Theme.onBrand : color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(active ? color : color.opacity(0.12))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: 목록

    @ViewBuilder
    private var list: some View {
        let cards = shown
        if cards.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "tray")
                    .font(.system(size: 30))
                    .foregroundStyle(Theme.textQuaternary)
                Text(emptyMessage)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(30)
        } else {
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(cards) { card in
                        row(card)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
        }
    }

    private var emptyMessage: String {
        switch group {
        case .acquired: return "아직 «알게 된 것»이 없습니다\n일주일 간격을 넘기면 여기로 옵니다"
        case .learning: return "지금 붙들고 있는 낱말이 없습니다"
        case .upcoming: return "모든 낱말을 한 번씩 봤습니다"
        }
    }

    /// 누르면 읽기·뜻·예문을 펼친다. 접혀 있을 때는 표기만 — 여기서도 인출이 먼저다.
    private func row(_ card: LearningCard) -> some View {
        let open = expanded == card.id
        let wrong = card.lastCorrect == false
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { expanded = open ? nil : card.id }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(wrong ? Color(accentHex: "DC2626") : group.color)
                        .frame(width: 7, height: 7)
                    Text(card.front)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    if wrong {
                        Text("틀림")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(Color(accentHex: "DC2626"))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color(accentHex: "DC2626").opacity(0.12))
                            .clipShape(Capsule())
                    }
                    Spacer(minLength: 4)
                    Text(detail(card))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Theme.textQuaternary)
                    Image(systemName: open ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Theme.textQuaternary)
                }
                if open {
                    if !card.reading.isEmpty {
                        Text(card.reading)
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    Text(card.meaning)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if let ex = N3Examples.sentence(for: card) {
                        FuriganaText(text: ex.japanese, size: 13)
                        Text(ex.korean)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textQuaternary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    /// 오른쪽 작은 글씨 — 덩어리마다 알고 싶은 것이 다르다
    private func detail(_ card: LearningCard) -> String {
        switch group {
        case .acquired: return "\(card.interval)일 간격"
        case .learning: return card.repetitions > 0 ? "\(card.repetitions)번 봄" : "학습 중"
        case .upcoming: return card.level == 1 ? "빈출" : (card.level == 2 ? "표준" : "심화")
        }
    }
}
