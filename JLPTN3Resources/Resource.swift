import SwiftUI

// MARK: - Category

enum ResourceCategory: String, CaseIterable, Identifiable {
    case vocabulary = "어휘·한자"
    case grammar    = "문법"
    case reading    = "독해"
    case listening  = "청해"
    case mockExam   = "모의고사"

    var id: String { rawValue }

    var japaneseLabel: String {
        switch self {
        case .vocabulary: return "語彙・漢字"
        case .grammar:    return "文法"
        case .reading:    return "読解"
        case .listening:  return "聴解"
        case .mockExam:   return "模擬試験"
        }
    }

    var color: Color {
        switch self {
        case .vocabulary: return Color(accentHex: "BE123C")
        case .grammar:    return Color(accentHex: "1D4ED8")
        case .reading:    return Color(accentHex: "7C3AED")
        case .listening:  return Color(accentHex: "0891B2")
        case .mockExam:   return Color(accentHex: "B45309")
        }
    }

    var icon: String {
        switch self {
        case .vocabulary: return "character.book.closed.ja"
        case .grammar:    return "text.book.closed"
        case .reading:    return "doc.text"
        case .listening:  return "headphones"
        case .mockExam:   return "checkmark.seal"
        }
    }
}

// MARK: - ResourceType

enum ResourceType: String, CaseIterable {
    case free    = "무료"
    case paid    = "유료"
    case mixed   = "무/유료"
}

// MARK: - Platform

enum Platform: String {
    case web       = "웹"
    case mobile    = "모바일"
    case youtube   = "YouTube"
    case podcast   = "팟캐스트"
    case book      = "교재"
    case appWeb    = "앱/웹"
    case webApp    = "웹/앱"
}

// MARK: - Resource

struct Resource: Identifiable {
    let id: Int
    let category: ResourceCategory
    let title: String
    let description: String
    let type: ResourceType
    let platform: String
    let urlString: String
    let tag: String
    let emoji: String

    var url: URL? { URL(string: urlString) }

    var typeColor: Color {
        switch type {
        case .free:  return Color(accentHex: "16A34A")
        case .paid:  return Color(accentHex: "DC2626")
        case .mixed: return Color(accentHex: "D97706")
        }
    }
}

// MARK: - Sample Data

extension Resource {
    static let all: [Resource] = [
        // 어휘·한자
        Resource(id: 1, category: .vocabulary,
                 title: "Anki JLPT N3 Deck",
                 description: "커뮤니티가 만든 N3 공식 단어 플래시카드 덱. 3,750개 어휘 + 예문 포함. SRS 방식으로 망각 곡선을 극복하는 최고의 도구.",
                 type: .free, platform: "앱/웹",
                 urlString: "https://ankiweb.net/shared/decks/jlpt%20n3",
                 tag: "앱", emoji: "🃏"),

        Resource(id: 2, category: .vocabulary,
                 title: "Takoboto 사전 앱",
                 description: "JLPT 레벨별 단어장 기능. N3 어휘 목록 + 필터 검색 지원. iOS/Android 모두 무료로 사용 가능.",
                 type: .free, platform: "모바일",
                 urlString: "https://takoboto.jp",
                 tag: "앱", emoji: "📱"),

        Resource(id: 3, category: .vocabulary,
                 title: "Jisho.org",
                 description: "일본어 최고 온라인 사전. JLPT 레벨 태그로 N3 어휘 검색 가능. 한자 필획 애니메이션 제공.",
                 type: .free, platform: "웹",
                 urlString: "https://jisho.org",
                 tag: "웹", emoji: "🔍"),

        Resource(id: 4, category: .vocabulary,
                 title: "WaniKani",
                 description: "한자·어휘 특화 SRS 시스템. N3 수준 한자 650자 체계적 학습. 레벨 3까지 무료 체험 가능.",
                 type: .paid, platform: "웹/앱",
                 urlString: "https://www.wanikani.com",
                 tag: "웹", emoji: "🦀"),

        // 문법
        Resource(id: 5, category: .grammar,
                 title: "JLPT Sensei - N3 문법",
                 description: "N3 문법 168패턴 전체 무료 해설. 예문·유사표현 비교까지 제공. 한국어 학습자에게 최적화.",
                 type: .free, platform: "웹",
                 urlString: "https://jlptsensei.com/jlpt-n3-grammar-list/",
                 tag: "웹", emoji: "📖"),

        Resource(id: 6, category: .grammar,
                 title: "Bunpro",
                 description: "SRS 방식 문법 학습. N3 문법 패턴 반복 훈련 + 문장 생성 연습. 문법 포인트 3,000개 이상 수록.",
                 type: .paid, platform: "웹",
                 urlString: "https://bunpro.jp",
                 tag: "웹", emoji: "🌿"),

        Resource(id: 7, category: .grammar,
                 title: "日本語の先生 유튜브",
                 description: "한국어 자막 지원 N3 문법 설명 채널. 문법별 영상 200개 이상 제공. 구독자 100만명 이상.",
                 type: .free, platform: "YouTube",
                 urlString: "https://youtube.com/@JapanesePod101",
                 tag: "영상", emoji: "▶️"),

        Resource(id: 8, category: .grammar,
                 title: "Nihongo-pro 문법 퀴즈",
                 description: "N3 레벨 문법 퀴즈 매일 제공. 오답 통계로 취약 패턴 파악 가능. 즉각적인 피드백 시스템.",
                 type: .free, platform: "웹",
                 urlString: "https://www.nihongo-pro.com/en/j/JLPT_N3_grammar_quizzes",
                 tag: "웹", emoji: "✏️"),

        // 독해
        Resource(id: 9, category: .reading,
                 title: "NHK Web Easy",
                 description: "실제 NHK 뉴스를 N4~N3 수준으로 쉽게 재작성. 매일 새 기사 제공. 단어 팝업 사전 내장.",
                 type: .free, platform: "웹",
                 urlString: "https://www3.nhk.or.jp/news/easy/",
                 tag: "웹", emoji: "📰"),

        Resource(id: 10, category: .reading,
                 title: "Tadoku 무료 독해 자료",
                 description: "레벨별 일본어 읽기 자료 무료 PDF. N3 수준 스토리·에세이 다수. 총 200권 이상 무료 제공.",
                 type: .free, platform: "웹",
                 urlString: "https://tadoku.org/japanese/free-books/",
                 tag: "PDF", emoji: "📚"),

        Resource(id: 11, category: .reading,
                 title: "JLPT N3 독해 기출문제",
                 description: "JLPT 공식 사이트 제공 과거 샘플 문제. 독해 파트 실전 감각 훈련. 정답·해설 포함.",
                 type: .free, platform: "웹",
                 urlString: "https://www.jlpt.jp/e/samples/forlearners.html",
                 tag: "공식", emoji: "🎯"),

        // 청해
        Resource(id: 12, category: .listening,
                 title: "日本語の森 유튜브",
                 description: "N3 청해 전문 채널. 속도·억양이 실제 시험과 유사. 무료 풀코스 + 스크립트 제공.",
                 type: .free, platform: "YouTube",
                 urlString: "https://youtube.com/@nihongonomori",
                 tag: "영상", emoji: "🎧"),

        Resource(id: 13, category: .listening,
                 title: "Erin's Challenge",
                 description: "일본국제교류기금 제작. N3 수준 드라마형 청해 교재. 스크립트 + 문화 해설 포함.",
                 type: .free, platform: "웹",
                 urlString: "https://www.erin.ne.jp/en/",
                 tag: "웹", emoji: "🎬"),

        Resource(id: 14, category: .listening,
                 title: "JapanesePod101",
                 description: "레벨별 팟캐스트 형식 청해 훈련. N3 코스 오디오 + 스크립트 제공. 기초부터 고급까지 커버.",
                 type: .mixed, platform: "웹/앱",
                 urlString: "https://www.japanesepod101.com",
                 tag: "팟캐스트", emoji: "🎙️"),

        Resource(id: 15, category: .listening,
                 title: "Shadowing 일본어 앱",
                 description: "원어민 발음 따라 말하기. 청해와 발음 동시 향상. iOS/Android 지원. 150개 이상 대화 내장.",
                 type: .paid, platform: "모바일",
                 urlString: "https://apps.apple.com/app/shadowing-japanese/id1626518095",
                 tag: "앱", emoji: "🗣️"),

        // 모의고사
        Resource(id: 16, category: .mockExam,
                 title: "JLPT 공식 샘플 문제",
                 description: "JLPT 공식 사이트 N3 전 섹션 샘플 문제. 실제 시험 형식 100% 동일. 가장 신뢰할 수 있는 자료.",
                 type: .free, platform: "웹",
                 urlString: "https://www.jlpt.jp/e/samples/forlearners.html",
                 tag: "공식", emoji: "📋"),

        Resource(id: 17, category: .mockExam,
                 title: "Try! JLPT N3 교재",
                 description: "실전형 모의고사 교재. 문법·독해·청해 풀 세트. 해설 상세. 시중 최고 평점 N3 교재.",
                 type: .paid, platform: "교재",
                 urlString: "https://bookclub.japantimes.co.jp/en/book/b313503.html",
                 tag: "교재", emoji: "📕"),

        Resource(id: 18, category: .mockExam,
                 title: "Nihongo-pro 모의시험",
                 description: "온라인 N3 모의고사. 시간 측정 + 섹션별 점수 분석 자동 제공. 무료로 반복 응시 가능.",
                 type: .free, platform: "웹",
                 urlString: "https://www.nihongo-pro.com/en/j/JLPT_N3_practice_tests",
                 tag: "웹", emoji: "⏱️"),
    ]
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
