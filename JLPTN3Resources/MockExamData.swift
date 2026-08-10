import SwiftUI

// MARK: - 채점 과목

enum ExamSubject: String, CaseIterable, Identifiable {
    case language
    case reading
    case listening

    var id: String { rawValue }

    var name: String {
        switch self {
        case .language:  return "언어지식"
        case .reading:   return "독해"
        case .listening: return "청해"
        }
    }

    var japanese: String {
        switch self {
        case .language:  return "言語知識"
        case .reading:   return "読解"
        case .listening: return "聴解"
        }
    }

    var icon: String {
        switch self {
        case .language:  return "character.book.closed.ja"
        case .reading:   return "doc.text"
        case .listening: return "headphones"
        }
    }

    var colorHex: String {
        switch self {
        case .language:  return "BE123C"
        case .reading:   return "7C3AED"
        case .listening: return "0891B2"
        }
    }

    /// 실제 시험의 과목별 만점
    var maxScore: Int { 60 }
    /// 과목별 기준점 — 하나라도 못 넘으면 총점과 무관하게 불합격
    var passLine: Int { 19 }
}

// MARK: - 청해 대사

enum DialogueSpeaker {
    case male, female, narrator

    var pitch: Float {
        switch self {
        case .male:     return 0.82
        case .female:   return 1.18
        case .narrator: return 1.0
        }
    }

    var label: String {
        switch self {
        case .male:     return "男"
        case .female:   return "女"
        case .narrator: return "N"
        }
    }
}

struct DialogueLine {
    let speaker: DialogueSpeaker
    let text: String
}

// MARK: - 문항

struct MockQuestion: Identifiable {
    let id: String
    let subject: ExamSubject
    /// 実際の出題形式 이름 (問題 유형)
    let format: String
    /// 독해 지문 — 같은 지문을 쓰는 문항끼리 passageID가 같다
    let passage: String?
    let passageID: String?
    /// 청해 음성 대본
    let dialogue: [DialogueLine]?
    let prompt: String
    let choices: [String]
    let answerIndex: Int
    let explanation: String

    init(id: String, subject: ExamSubject, format: String,
         passage: String? = nil, passageID: String? = nil,
         dialogue: [DialogueLine]? = nil,
         prompt: String, choices: [String], answerIndex: Int, explanation: String) {
        self.id = id
        self.subject = subject
        self.format = format
        self.passage = passage
        self.passageID = passageID
        self.dialogue = dialogue
        self.prompt = prompt
        self.choices = choices
        self.answerIndex = answerIndex
        self.explanation = explanation
    }
}

// MARK: - 미니 모의고사 문항 은행
//
// 실제 JLPT 기출문제는 저작권이 있어 사용할 수 없다.
// 아래 문항은 공식 출제 «형식»만 따라 N3 범위에서 직접 만든 것이다.

private let readingPassageA = """
図書館からのお知らせ

来月の1日から10日まで、館内の工事のため、2階の閲覧室が使えなくなります。
本の貸し出しと返却は、1階のカウンターでいつもどおりできます。
なお、工事の期間中は、閉館時間が午後8時から午後6時に変わります。
ご不便をおかけしますが、ご協力をお願いします。
"""

private let readingPassageB = """
私は毎朝、駅まで歩いて通勤している。以前はバスを使っていたが、朝の道路は込んでいて、
着く時間が読めないことが多かった。歩けば25分かかる。それでも、何時に着くかが
はっきりしているし、体を動かすこともできる。雨の日は少し大変だけれど、
一日の始まりに自分だけの時間が持てるのは、思ったよりも気持ちがいい。
"""

let mockExamQuestions: [MockQuestion] = [

    // ── 언어지식 (문자·어휘·문법) ──────────────────────────────

    MockQuestion(
        id: "L1", subject: .language, format: "漢字読み",
        prompt: "先生に＿＿してから決めようと思います。\n（＿＿ = 相談）",
        choices: ["そうだん", "そうたん", "しょうだん", "しょうたん"],
        answerIndex: 0,
        explanation: "相談（そうだん）. 「相」은 «そう», 「談」은 «だん»으로 탁음이 붙습니다."
    ),
    MockQuestion(
        id: "L2", subject: .language, format: "漢字読み",
        prompt: "この町の人口は年々＿＿ている。\n（＿＿ = 増え）",
        choices: ["ふえ", "へえ", "くわえ", "そえ"],
        answerIndex: 0,
        explanation: "増える（ふえる）. 반대말은 減る（へる）로, 한자가 달라 헷갈리기 쉽습니다."
    ),
    MockQuestion(
        id: "L3", subject: .language, format: "表記",
        prompt: "彼は仕事で多くの＿＿を積んできた。\n（＿＿ = けいけん）",
        choices: ["経験", "経検", "軽験", "軽検"],
        answerIndex: 0,
        explanation: "経験. 「経(경)」과 「軽(경)」, 「験(험)」과 「検(검)」을 바꿔치기한 전형적인 함정입니다."
    ),
    MockQuestion(
        id: "L4", subject: .language, format: "表記",
        prompt: "会場までの＿＿をお願いします。\n（＿＿ = あんない）",
        choices: ["案内", "安内", "案円", "安円"],
        answerIndex: 0,
        explanation: "案内. 「案(안)」과 「安(안)」은 한국어 음이 같아 한국인이 자주 틀립니다."
    ),
    MockQuestion(
        id: "L5", subject: .language, format: "文脈規定",
        prompt: "日本語が上手になるには、毎日の（　　）が大切だ。",
        choices: ["練習", "研究", "講義", "試合"],
        answerIndex: 0,
        explanation: "매일 반복하는 «연습»이므로 練習. 研究(연구)·講義(강의)·試合(시합)은 문맥에 맞지 않습니다."
    ),
    MockQuestion(
        id: "L6", subject: .language, format: "文脈規定",
        prompt: "彼は約束を必ず（　　）人だ。",
        choices: ["守る", "持つ", "取る", "作る"],
        answerIndex: 0,
        explanation: "約束を守る(약속을 지키다)가 고정 표현입니다. 約束をする/破る도 함께 외워 두세요."
    ),
    MockQuestion(
        id: "L7", subject: .language, format: "言い換え類義",
        prompt: "「この仕事はかんたんではない。」\nこの文に意味が最も近いものはどれか。",
        choices: ["この仕事はやさしくない。", "この仕事はおもしろくない。",
                  "この仕事はたかくない。", "この仕事はながくない。"],
        answerIndex: 0,
        explanation: "簡単 ≒ やさしい(쉽다). 「やさしい」에는 «상냥하다»의 뜻도 있지만 여기서는 «쉽다»입니다."
    ),
    MockQuestion(
        id: "L8", subject: .language, format: "文法形式の判断",
        prompt: "雨が降りそうだから、傘を持って（　　）ほうがいいですよ。",
        choices: ["いった", "いって", "いく", "いき"],
        answerIndex: 0,
        explanation: "「〜たほうがいい」는 た형에 접속합니다. 持っていく → 持っていったほうがいい."
    ),
    MockQuestion(
        id: "L9", subject: .language, format: "文法形式の判断",
        prompt: "彼は忙しい（　　）、いつも手伝ってくれる。",
        choices: ["のに", "ので", "から", "ため"],
        answerIndex: 0,
        explanation: "«바쁜데도 도와준다»는 역접이므로 のに. ので·から·ため는 모두 순접(이유)입니다."
    ),
    MockQuestion(
        id: "L10", subject: .language, format: "文法形式の判断",
        prompt: "日本語で電話をかけるのは、私に（　　）まだ難しい。",
        choices: ["とって", "ついて", "対して", "よって"],
        answerIndex: 0,
        explanation: "「〜にとって」= ~에게 있어서(입장·기준). 「〜について」는 ~에 대해서(주제)입니다."
    ),

    // ── 독해 ─────────────────────────────────────────────

    MockQuestion(
        id: "R1", subject: .reading, format: "短文 (お知らせ)",
        passage: readingPassageA, passageID: "A",
        prompt: "工事の期間中にできないことは何か。",
        choices: ["2階の閲覧室を使うこと", "本を借りること",
                  "本を返すこと", "図書館に入ること"],
        answerIndex: 0,
        explanation: "«2階の閲覧室が使えなくなります»라고 명시돼 있습니다. 대출·반납은 1층에서 «いつもどおり» 가능합니다."
    ),
    MockQuestion(
        id: "R2", subject: .reading, format: "短文 (お知らせ)",
        passage: readingPassageA, passageID: "A",
        prompt: "工事の期間中、図書館は何時に閉まるか。",
        choices: ["午後6時", "午後8時", "午前6時", "午前8時"],
        answerIndex: 0,
        explanation: "«閉館時間が午後8時から午後6時に変わります» — «A から B に変わる»는 B가 새 값입니다. 이 «から»를 시작 시각으로 읽으면 틀립니다."
    ),
    MockQuestion(
        id: "R3", subject: .reading, format: "短文 (エッセイ)",
        passage: readingPassageB, passageID: "B",
        prompt: "「私」がバスをやめた一番の理由は何か。",
        choices: ["着く時間がはっきりしないから", "料金が高いから",
                  "バス停が遠いから", "運動が好きだから"],
        answerIndex: 0,
        explanation: "«着く時間が読めないことが多かった»가 이유입니다. 운동은 나중에 덧붙인 장점이지 그만둔 이유가 아닙니다."
    ),
    MockQuestion(
        id: "R4", subject: .reading, format: "短文 (エッセイ)",
        passage: readingPassageB, passageID: "B",
        prompt: "「私」は今の通勤についてどう感じているか。",
        choices: ["大変な日もあるが、満足している", "毎日つらいと思っている",
                  "前のほうがよかったと思っている", "特に何も感じていない"],
        answerIndex: 0,
        explanation: "«雨の日は少し大変だけれど» + «思ったよりも気持ちがいい» — 역접 뒤에 오는 쪽이 필자의 결론입니다."
    ),

    // ── 청해 ─────────────────────────────────────────────

    MockQuestion(
        id: "C1", subject: .listening, format: "課題理解",
        dialogue: [
            DialogueLine(speaker: .male,   text: "すみません、この本を借りたいんですが。"),
            DialogueLine(speaker: .female, text: "はい、利用カードはお持ちですか。"),
            DialogueLine(speaker: .male,   text: "いいえ、まだ作っていません。"),
            DialogueLine(speaker: .female, text: "それでは、先にあちらの窓口で申し込んでください。")
        ],
        prompt: "男の人はこのあと、まず何をしますか。",
        choices: ["窓口でカードを申し込む", "本を借りる", "本を返す", "2階へ行く"],
        answerIndex: 0,
        explanation: "«先に〜てください»가 다음 행동을 지시합니다. 課題理解는 «먼저 무엇을 하는가»를 묻습니다."
    ),
    MockQuestion(
        id: "C2", subject: .listening, format: "ポイント理解",
        dialogue: [
            DialogueLine(speaker: .female, text: "明日の集合は9時でしたよね。"),
            DialogueLine(speaker: .male,   text: "いえ、8時半に変わりました。バスが早く出るそうです。"),
            DialogueLine(speaker: .female, text: "分かりました。じゃあ、8時20分には着くようにします。")
        ],
        prompt: "女の人は明日、何時に着くつもりですか。",
        choices: ["8時20分", "8時半", "9時", "9時20分"],
        answerIndex: 0,
        explanation: "숫자가 세 개(9時·8時半·8時20分) 나옵니다. 질문은 «집합 시각»이 아니라 «여자가 도착할 시각»입니다."
    ),
    MockQuestion(
        id: "C3", subject: .listening, format: "課題理解",
        dialogue: [
            DialogueLine(speaker: .male,   text: "会議の資料、コピーはもう終わった？"),
            DialogueLine(speaker: .female, text: "はい、20部作りました。"),
            DialogueLine(speaker: .male,   text: "ありがとう。じゃあ、それを会議室の机に置いておいてくれる？"),
            DialogueLine(speaker: .female, text: "はい、分かりました。")
        ],
        prompt: "女の人はこのあと何をしますか。",
        choices: ["資料を会議室に置く", "資料をコピーする",
                  "会議室を予約する", "男の人に資料を渡す"],
        answerIndex: 0,
        explanation: "복사는 «もう終わった»로 이미 끝난 일입니다. 이미 한 일과 앞으로 할 일을 구분하는 것이 이 유형의 핵심입니다."
    ),
    MockQuestion(
        id: "C4", subject: .listening, format: "即時応答",
        dialogue: [
            DialogueLine(speaker: .female, text: "先週は本当にお世話になりました。")
        ],
        prompt: "この言葉への返事として、最もよいものはどれか。",
        choices: ["いいえ、こちらこそ。", "では、いただきます。",
                  "いってらっしゃい。", "ごちそうさまでした。"],
        answerIndex: 0,
        explanation: "«お世話になりました»(신세 졌습니다)에는 «こちらこそ»(저야말로)로 받습니다. 즉시응답은 장면에 맞는 관용 표현을 고르는 유형입니다."
    )
]

// MARK: - 채점

struct SubjectResult: Identifiable {
    let subject: ExamSubject
    let correct: Int
    let total: Int

    var id: String { subject.rawValue }

    /// 문항 수가 적으므로 정답률을 60점 만점으로 환산한 «예상» 점수
    var scaledScore: Int {
        guard total > 0 else { return 0 }
        return Int((Double(correct) / Double(total) * Double(subject.maxScore)).rounded())
    }
    var passedSubject: Bool { scaledScore >= subject.passLine }
}

struct MockExamResult {
    let subjectResults: [SubjectResult]

    var totalScore: Int { subjectResults.reduce(0) { $0 + $1.scaledScore } }
    var totalCorrect: Int { subjectResults.reduce(0) { $0 + $1.correct } }
    var totalQuestions: Int { subjectResults.reduce(0) { $0 + $1.total } }

    var allSubjectsPassed: Bool { subjectResults.allSatisfy { $0.passedSubject } }
    var totalPassed: Bool { totalScore >= 95 }
    /// 총점 95점 이상 «그리고» 전 과목 19점 이상
    var passed: Bool { totalPassed && allSubjectsPassed }
}
