import SwiftUI

// MARK: - 청해 연습 데이터
//
// 실제 기출 음성은 쓸 수 없으므로, 공식 출제 형식 5가지만 따라 대본을 직접 썼다.
// 음성은 AVSpeechSynthesizer(ja-JP)로 읽어 주고, 화자별로 pitch를 달리해 대화를 구분한다.

enum ListeningKind: String, CaseIterable, Identifiable {
    case task     // 課題理解 — 이 다음에 무엇을 해야 하는가
    case point    // ポイント理解 — 이유·시각·장소 등 한 가지 정보
    case summary  // 概要理解 — 전체 내용·주장
    case speech   // 発話表現 — 이 상황에서 뭐라고 말하나
    case quick    // 即時応答 — 짧은 말에 대한 응답

    var id: String { rawValue }

    var name: String {
        switch self {
        case .task:    return "課題理解"
        case .point:   return "ポイント理解"
        case .summary: return "概要理解"
        case .speech:  return "発話表現"
        case .quick:   return "即時応答"
        }
    }

    var korean: String {
        switch self {
        case .task:    return "과제 이해 · 다음에 할 일"
        case .point:   return "포인트 이해 · 이유와 조건"
        case .summary: return "개요 이해 · 전체 내용"
        case .speech:  return "발화 표현 · 뭐라고 말할까"
        case .quick:   return "즉시 응답 · 짧은 대답"
        }
    }

    var icon: String {
        switch self {
        case .task:    return "checklist"
        case .point:   return "target"
        case .summary: return "text.alignleft"
        case .speech:  return "bubble.left"
        case .quick:   return "bolt"
        }
    }

    /// 이 유형에서 «먼저 문제를 읽어도 되는지».
    /// 실제 시험에서 概要理解·即時応答은 질문이 음성 뒤에 나온다.
    var showsQuestionBeforeAudio: Bool {
        switch self {
        case .task, .point, .speech: return true
        case .summary, .quick:       return false
        }
    }
}

struct ListeningItem: Identifiable {
    let id: String
    let kind: ListeningKind
    /// 음성 앞에 읽어 주는 상황 설명 (発話表現은 화면에도 보여준다)
    let situation: String
    let dialogue: [DialogueLine]
    /// 질문 (일본어)
    let question: String
    let choices: [String]
    let answerIndex: Int
    /// 한국어 해설
    let explanation: String
}

// MARK: - 문항 은행

let listeningItems: [ListeningItem] =
    taskItems + pointItems + summaryItems + speechItems + quickItems + listeningItems2

// MARK: 課題理解 — 이 다음에 무엇을 하는가

private let taskItems: [ListeningItem] = [

    ListeningItem(
        id: "lt01", kind: .task,
        situation: "会社で女の人と男の人が話しています。男の人はこのあとまず何をしますか。",
        dialogue: [
            DialogueLine(speaker: .female, text: "田中さん、午後の会議の準備、進んでいますか。"),
            DialogueLine(speaker: .male, text: "はい、資料のコピーは終わりました。"),
            DialogueLine(speaker: .female, text: "ありがとう。じゃあ、会議室の机を並べておいてくれる？"),
            DialogueLine(speaker: .male, text: "分かりました。あ、その前に部長に資料を見ていただかないと。"),
            DialogueLine(speaker: .female, text: "そうね、部長は今出かけているから、戻ってからでいいわ。先に机をお願い。"),
            DialogueLine(speaker: .male, text: "はい、そうします。")
        ],
        question: "男の人はこのあとまず何をしますか。",
        choices: ["資料をコピーする", "会議室の机を並べる", "部長に資料を見せる", "部長を迎えに行く"],
        answerIndex: 1,
        explanation: "부장은 외출 중이라 «戻ってからでいい»고 했고, 여자가 「先に机をお願い」라고 정리했습니다. 복사는 이미 끝났습니다."),

    ListeningItem(
        id: "lt02", kind: .task,
        situation: "大学で男の学生と女の学生が話しています。女の学生はこのあと何をしますか。",
        dialogue: [
            DialogueLine(speaker: .male, text: "レポート、もう出した？"),
            DialogueLine(speaker: .female, text: "書き終わったんだけど、参考にした本の名前を書くのを忘れてて。"),
            DialogueLine(speaker: .male, text: "それ、書かないと受け取ってもらえないよ。"),
            DialogueLine(speaker: .female, text: "うん。図書館でもう一度本を確認してから出す。"),
            DialogueLine(speaker: .male, text: "先生に相談しなくて大丈夫？"),
            DialogueLine(speaker: .female, text: "直してから持っていくよ。")
        ],
        question: "女の学生はこのあと何をしますか。",
        choices: ["レポートを出す", "先生に相談する", "図書館で本を確認する", "レポートを書き直す"],
        answerIndex: 2,
        explanation: "「図書館でもう一度本を確認してから出す」 — 도서관 확인이 먼저입니다. 선생님께는 «直してから» 갑니다."),

    ListeningItem(
        id: "lt03", kind: .task,
        situation: "家で母親と息子が話しています。息子はこのあとまず何をしますか。",
        dialogue: [
            DialogueLine(speaker: .female, text: "帰りにスーパーで牛乳を買ってきてくれない？"),
            DialogueLine(speaker: .male, text: "いいよ。でも今日は6時から塾があるんだ。"),
            DialogueLine(speaker: .female, text: "あら、じゃあ間に合わないわね。"),
            DialogueLine(speaker: .male, text: "塾のあとでもいい？8時には終わるから。"),
            DialogueLine(speaker: .female, text: "スーパー、8時で閉まっちゃうのよ。じゃあ、塾に行く前に寄って。"),
            DialogueLine(speaker: .male, text: "分かった。そうする。")
        ],
        question: "息子はこのあとまず何をしますか。",
        choices: ["塾に行く", "スーパーで牛乳を買う", "8時まで待つ", "母親と買い物に行く"],
        answerIndex: 1,
        explanation: "슈퍼가 8시에 닫으므로 어머니가 「塾に行く前に寄って」라고 했고 아들이 동의했습니다."),

    ListeningItem(
        id: "lt04", kind: .task,
        situation: "旅行会社で女の人と店の人が話しています。女の人はこのあと何をしますか。",
        dialogue: [
            DialogueLine(speaker: .female, text: "来月の京都のツアーを申し込みたいんですが。"),
            DialogueLine(speaker: .male, text: "ありがとうございます。こちらの用紙にお名前とご住所をお願いします。"),
            DialogueLine(speaker: .female, text: "はい。お金は今日払うんですか。"),
            DialogueLine(speaker: .male, text: "お支払いは一週間以内で結構です。用紙を出していただいたら、確認のメールをお送りします。"),
            DialogueLine(speaker: .female, text: "分かりました。書きます。")
        ],
        question: "女の人はこのあと何をしますか。",
        choices: ["お金を払う", "確認のメールを送る", "用紙に名前と住所を書く", "一週間待つ"],
        answerIndex: 2,
        explanation: "지불은 «一週間以内»로 나중이고, 지금은 용지에 이름과 주소를 씁니다."),

    ListeningItem(
        id: "lt05", kind: .task,
        situation: "病院で医者と男の人が話しています。男の人は今日このあとどうしますか。",
        dialogue: [
            DialogueLine(speaker: .male, text: "先生、熱は下がったんですが、まだせきが出ます。"),
            DialogueLine(speaker: .female, text: "そうですか。では、せきの薬を出しておきますね。"),
            DialogueLine(speaker: .male, text: "会社には行ってもいいですか。"),
            DialogueLine(speaker: .female, text: "熱がなければ大丈夫ですが、今日はゆっくり休んでください。明日から行きましょう。"),
            DialogueLine(speaker: .male, text: "分かりました。")
        ],
        question: "男の人は今日このあとどうしますか。",
        choices: ["会社に行く", "家で休む", "もう一度病院に来る", "薬を飲まないで様子を見る"],
        answerIndex: 1,
        explanation: "의사가 「今日はゆっくり休んでください。明日から行きましょう」라고 했습니다."),

    ListeningItem(
        id: "lt06", kind: .task,
        situation: "店で店員と客が話しています。客はこのあとどうしますか。",
        dialogue: [
            DialogueLine(speaker: .female, text: "すみません、このシャツのMサイズはありますか。"),
            DialogueLine(speaker: .male, text: "申し訳ありません。こちらの色のMは今切れておりまして。"),
            DialogueLine(speaker: .female, text: "そうですか…。"),
            DialogueLine(speaker: .male, text: "同じサイズなら白と青がございます。あと、三日後には同じ色が入ります。"),
            DialogueLine(speaker: .female, text: "じゃあ、入ってから電話をいただけますか。待ちます。"),
            DialogueLine(speaker: .male, text: "かしこまりました。")
        ],
        question: "客はこのあとどうしますか。",
        choices: ["白いシャツを買う", "青いシャツを買う", "店から電話が来るのを待つ", "別の店に行く"],
        answerIndex: 2,
        explanation: "「入ってから電話をいただけますか。待ちます」 — 다른 색을 사지 않고 연락을 기다립니다."),

    ListeningItem(
        id: "lt07", kind: .task,
        situation: "会社で男の人と女の人が話しています。女の人はこのあとまず何をしますか。",
        dialogue: [
            DialogueLine(speaker: .male, text: "山田さん、来週のイベントの案内、もう送った？"),
            DialogueLine(speaker: .female, text: "まだです。参加する人のリストを作っているところで。"),
            DialogueLine(speaker: .male, text: "案内は今日中に出したいな。リストは明日でもいいよ。"),
            DialogueLine(speaker: .female, text: "分かりました。では案内の文を先に作ります。"),
            DialogueLine(speaker: .male, text: "うん、できたら見せて。")
        ],
        question: "女の人はこのあとまず何をしますか。",
        choices: ["参加者のリストを作る", "案内の文を作る", "イベントの場所を予約する", "男の人に確認してもらう"],
        answerIndex: 1,
        explanation: "안내는 «今日中», 리스트는 «明日でもいい» → 안내문 작성이 먼저입니다."),

    ListeningItem(
        id: "lt08", kind: .task,
        situation: "アパートで管理人と住民が話しています。住民はこのあと何をしますか。",
        dialogue: [
            DialogueLine(speaker: .male, text: "すみません、部屋の電気がつかなくなってしまって。"),
            DialogueLine(speaker: .female, text: "そうですか。電球を替えてもだめですか。"),
            DialogueLine(speaker: .male, text: "替えてみましたが、つきません。"),
            DialogueLine(speaker: .female, text: "では、修理の人を呼びますね。今日の午後３時ごろになりますが、部屋にいらっしゃいますか。"),
            DialogueLine(speaker: .male, text: "3時なら大丈夫です。待っています。")
        ],
        question: "住民はこのあと何をしますか。",
        choices: ["電球を買いに行く", "自分で電気を直す", "3時まで部屋で待つ", "管理人に電話する"],
        answerIndex: 2,
        explanation: "수리 기사가 «午後3時ごろ» 오므로 방에서 기다립니다. 전구는 이미 갈아 봤습니다."),
]

// MARK: ポイント理解 — 이유·조건 한 가지

private let pointItems: [ListeningItem] = [

    ListeningItem(
        id: "lp01", kind: .point,
        situation: "男の人と女の人が話しています。女の人はどうして引っ越すことにしましたか。",
        dialogue: [
            DialogueLine(speaker: .male, text: "来月引っ越すって聞いたけど、今の部屋、広くていいのに。"),
            DialogueLine(speaker: .female, text: "うん、部屋は気に入ってるんだけどね。"),
            DialogueLine(speaker: .male, text: "家賃が高いとか？"),
            DialogueLine(speaker: .female, text: "それは大丈夫。ただ、４月から職場が変わって、片道1時間半になっちゃって。"),
            DialogueLine(speaker: .male, text: "ああ、それは遠いね。")
        ],
        question: "女の人はどうして引っ越すことにしましたか。",
        choices: ["部屋がせまいから", "家賃が高いから", "通勤に時間がかかるから", "職場の人と合わないから"],
        answerIndex: 2,
        explanation: "「職場が変わって、片道1時間半になっちゃって」 — 통근 시간이 이유입니다. 방과 집세는 문제없다고 부정했습니다."),

    ListeningItem(
        id: "lp02", kind: .point,
        situation: "女の学生と男の学生が話しています。二人はいつ会いますか。",
        dialogue: [
            DialogueLine(speaker: .female, text: "発表の準備、いつやる？"),
            DialogueLine(speaker: .male, text: "水曜の午後はどう？"),
            DialogueLine(speaker: .female, text: "水曜はバイトなんだ。木曜なら空いてる。"),
            DialogueLine(speaker: .male, text: "木曜は午前中しか無理だな。"),
            DialogueLine(speaker: .female, text: "じゃあ木曜の10時に図書館で。"),
            DialogueLine(speaker: .male, text: "うん、それでいこう。")
        ],
        question: "二人はいつ会いますか。",
        choices: ["水曜日の午後", "木曜日の午前", "木曜日の午後", "金曜日の午前"],
        answerIndex: 1,
        explanation: "여학생은 수요일 알바, 남학생은 목요일 오전만 가능 → 「木曜の10時」로 정해집니다."),

    ListeningItem(
        id: "lp03", kind: .point,
        situation: "店で男の人が店員と話しています。男の人はいくら払いますか。",
        dialogue: [
            DialogueLine(speaker: .male, text: "このかばん、いくらですか。"),
            DialogueLine(speaker: .female, text: "5,000円ですが、今週はセールで2割引きになります。"),
            DialogueLine(speaker: .male, text: "じゃあ、それをください。あと、この財布も。"),
            DialogueLine(speaker: .female, text: "財布は1,000円です。こちらはセールの対象ではありません。"),
            DialogueLine(speaker: .male, text: "分かりました。")
        ],
        question: "男の人はいくら払いますか。",
        choices: ["4,000円", "4,800円", "5,000円", "6,000円"],
        answerIndex: 2,
        explanation: "가방 5,000엔의 20% 할인 = 4,000엔, 지갑 1,000엔은 할인 대상 아님 → 합계 5,000엔."),

    ListeningItem(
        id: "lp04", kind: .point,
        situation: "会社で女の人と男の人が話しています。男の人はどうして遅れましたか。",
        dialogue: [
            DialogueLine(speaker: .female, text: "遅かったですね。電車が止まったんですか。"),
            DialogueLine(speaker: .male, text: "いえ、電車は動いていました。"),
            DialogueLine(speaker: .female, text: "じゃあ、寝坊ですか。"),
            DialogueLine(speaker: .male, text: "違いますよ。家を出るとき、鍵が見つからなくて、探していたんです。"),
            DialogueLine(speaker: .female, text: "それは大変でしたね。")
        ],
        question: "男の人はどうして遅れましたか。",
        choices: ["電車が止まったから", "朝寝坊したから", "鍵を探していたから", "道が込んでいたから"],
        answerIndex: 2,
        explanation: "전철·늦잠은 모두 부정하고 「鍵が見つからなくて、探していた」라고 했습니다."),

    ListeningItem(
        id: "lp05", kind: .point,
        situation: "女の人と男の人が旅行について話しています。二人は何で行きますか。",
        dialogue: [
            DialogueLine(speaker: .female, text: "海まで、電車で行く？"),
            DialogueLine(speaker: .male, text: "電車だと駅から遠いんだよね。バスに乗りかえないと。"),
            DialogueLine(speaker: .female, text: "車を借りるのはどう？"),
            DialogueLine(speaker: .male, text: "夏は道が込むから、時間が読めないよ。"),
            DialogueLine(speaker: .female, text: "じゃあ、多少歩いても電車にしよう。乗りかえは１回だけだし。"),
            DialogueLine(speaker: .male, text: "そうだね。")
        ],
        question: "二人は何で行きますか。",
        choices: ["車", "電車とバス", "自転車", "飛行機"],
        answerIndex: 1,
        explanation: "차는 «道が込む»로 제외, 결국 전철로 가고 «乗りかえは1回»(버스 환승)이 남습니다."),

    ListeningItem(
        id: "lp06", kind: .point,
        situation: "先生と学生が話しています。学生は何を持ってこなければなりませんか。",
        dialogue: [
            DialogueLine(speaker: .male, text: "先生、あしたの試験に辞書は使えますか。"),
            DialogueLine(speaker: .female, text: "辞書は使えません。鉛筆と消しゴムだけでいいですよ。"),
            DialogueLine(speaker: .male, text: "時計はどうですか。"),
            DialogueLine(speaker: .female, text: "教室に時計がありますから、なくても大丈夫です。"),
            DialogueLine(speaker: .male, text: "分かりました。")
        ],
        question: "学生は何を持ってこなければなりませんか。",
        choices: ["辞書と鉛筆", "鉛筆と消しゴム", "時計と辞書", "何も持ってこなくていい"],
        answerIndex: 1,
        explanation: "「鉛筆と消しゴムだけでいい」 — 사전은 사용 불가, 시계는 없어도 됩니다."),

    ListeningItem(
        id: "lp07", kind: .point,
        situation: "男の人と女の人が話しています。パーティーは何時から始まりますか。",
        dialogue: [
            DialogueLine(speaker: .male, text: "土曜のパーティー、6時からだよね。"),
            DialogueLine(speaker: .female, text: "実は30分遅くなったの。店の準備が間に合わないって。"),
            DialogueLine(speaker: .male, text: "じゃあ、集まるのはその15分前でいい？"),
            DialogueLine(speaker: .female, text: "うん、それでお願い。")
        ],
        question: "パーティーは何時から始まりますか。",
        choices: ["5時45分", "6時", "6時15分", "6時30分"],
        answerIndex: 3,
        explanation: "6시에서 30분 늦어져 6시 30분 시작입니다. 6시 15분은 «모이는» 시각입니다."),

    ListeningItem(
        id: "lp08", kind: .point,
        situation: "女の人と男の人が話しています。男の人はどうしてこの店を選びましたか。",
        dialogue: [
            DialogueLine(speaker: .female, text: "ここ、ちょっと高いけど、よく来るの？"),
            DialogueLine(speaker: .male, text: "うん。味は正直、ほかの店のほうがいいかもしれない。"),
            DialogueLine(speaker: .female, text: "え、じゃあどうして？"),
            DialogueLine(speaker: .male, text: "夜遅くまで開いていて、静かだから。仕事のあとに落ち着いて話せるんだ。"),
            DialogueLine(speaker: .female, text: "なるほどね。")
        ],
        question: "男の人はどうしてこの店を選びましたか。",
        choices: ["料理が安いから", "味がいちばんいいから", "遅くまで開いていて静かだから", "家から近いから"],
        answerIndex: 2,
        explanation: "가격은 «ちょっと高い», 맛도 «ほかの店のほうがいいかも»라고 하고, 이유로 「遅くまで開いていて、静かだから」를 들었습니다."),
]

// MARK: 概要理解 — 전체 내용 (질문은 음성 뒤)

private let summaryItems: [ListeningItem] = [

    ListeningItem(
        id: "ls01", kind: .summary,
        situation: "テレビでアナウンサーが話しています。",
        dialogue: [
            DialogueLine(speaker: .female, text: "今年の夏は、去年より雨の日が多くなりそうです。"),
            DialogueLine(speaker: .female, text: "気温はそれほど高くなりませんが、湿気が多いため、暑く感じる日が続くでしょう。"),
            DialogueLine(speaker: .female, text: "外に出るときは、水をこまめに飲むようにしてください。")
        ],
        question: "アナウンサーは何について話していますか。",
        choices: ["今年の夏の天気と注意", "去年の夏の思い出", "水の飲み方の研究", "夏の旅行の計画"],
        answerIndex: 0,
        explanation: "여름 날씨(비·습도)와 «水をこまめに»라는 주의를 전하고 있습니다."),

    ListeningItem(
        id: "ls02", kind: .summary,
        situation: "会社で男の人が話しています。",
        dialogue: [
            DialogueLine(speaker: .male, text: "来月から、会議の資料を紙で配るのをやめます。"),
            DialogueLine(speaker: .male, text: "みなさんのパソコンに前の日までに送りますので、各自で見てください。"),
            DialogueLine(speaker: .male, text: "紙が必要な方は、自分で印刷していただいて構いません。")
        ],
        question: "男の人が伝えたいことは何ですか。",
        choices: ["会議の回数を減らすこと", "資料を紙で配るのをやめること", "パソコンを新しくすること", "印刷の機械が使えないこと"],
        answerIndex: 1,
        explanation: "핵심은 «紙で配るのをやめる»이고, 나머지는 그에 따른 안내입니다."),

    ListeningItem(
        id: "ls03", kind: .summary,
        situation: "女の人が友達に話しています。",
        dialogue: [
            DialogueLine(speaker: .female, text: "新しい仕事を始めて三か月たったんだけど、まだ慣れなくて。"),
            DialogueLine(speaker: .female, text: "覚えることが多くて、家に帰ると何もできないの。"),
            DialogueLine(speaker: .female, text: "でも、先輩がていねいに教えてくれるから、やめようとは思っていないよ。")
        ],
        question: "女の人は今の仕事についてどう思っていますか。",
        choices: ["すぐにやめたいと思っている", "大変だが続けるつもりだ", "もう完全に慣れた", "先輩が厳しくてつらい"],
        answerIndex: 1,
        explanation: "힘들다고 하면서도 「やめようとは思っていない」 — 계속할 생각입니다."),

    ListeningItem(
        id: "ls04", kind: .summary,
        situation: "先生が学生に話しています。",
        dialogue: [
            DialogueLine(speaker: .male, text: "レポートは長ければいいというものではありません。"),
            DialogueLine(speaker: .male, text: "自分の意見が一つはっきり書いてあれば、短くても構いません。"),
            DialogueLine(speaker: .male, text: "本の内容をそのまま写しただけのものは、いくら長くても評価しません。")
        ],
        question: "先生がいちばん言いたいことは何ですか。",
        choices: ["レポートは長く書くべきだ", "本を写して書けばよい", "自分の意見が書いてあることが大事だ", "レポートは出さなくてよい"],
        answerIndex: 2,
        explanation: "길이가 아니라 «自分の意見が一つはっきり»가 중요하다는 이야기입니다."),

    ListeningItem(
        id: "ls05", kind: .summary,
        situation: "店で店員が客に話しています。",
        dialogue: [
            DialogueLine(speaker: .female, text: "こちらのカメラは、去年の型ですので今3割引きです。"),
            DialogueLine(speaker: .female, text: "新しい型との違いは、写真の色が少し変わったくらいで、使い方はほとんど同じです。"),
            DialogueLine(speaker: .female, text: "初めて使う方には、こちらで十分だと思いますよ。")
        ],
        question: "店員は何と言っていますか。",
        choices: ["新しい型のほうが初心者に向いている",
                  "古い型でも初めての人には十分だ",
                  "古い型は使い方がむずかしい",
                  "今は買わないほうがよい"],
        answerIndex: 1,
        explanation: "「初めて使う方には、こちらで十分」 — 작년 모델을 권하고 있습니다."),

    ListeningItem(
        id: "ls06", kind: .summary,
        situation: "男の人が町の集まりで話しています。",
        dialogue: [
            DialogueLine(speaker: .male, text: "この公園は、20年前に住民が自分たちで作った場所です。"),
            DialogueLine(speaker: .male, text: "今は草が伸びて、遊ぶ子どもも減りました。"),
            DialogueLine(speaker: .male, text: "月に一度でいいので、みなさんで掃除をする日を作りませんか。")
        ],
        question: "男の人は何をしたいと言っていますか。",
        choices: ["公園を新しく作ること", "みんなで公園の掃除をすること", "子どもを公園に呼ぶ会を開くこと", "公園をなくすこと"],
        answerIndex: 1,
        explanation: "마지막 제안 「月に一度…掃除をする日を作りませんか」가 요지입니다."),
]

// MARK: 発話表現 — 이 상황에서 뭐라고 말하나 (선택지 3개)

private let speechItems: [ListeningItem] = [

    ListeningItem(
        id: "le01", kind: .speech,
        situation: "友達の荷物が重そうです。手伝いたいとき、何と言いますか。",
        dialogue: [
            DialogueLine(speaker: .narrator, text: "友達の荷物が重そうです。手伝いたいとき、何と言いますか。")
        ],
        question: "何と言いますか。",
        choices: ["持とうか。", "持ってくれる？", "持ってもいい？"],
        answerIndex: 0,
        explanation: "내가 들어 주겠다는 제안은 「持とうか」입니다. 2번은 상대에게 부탁, 3번은 허락을 구하는 말입니다."),

    ListeningItem(
        id: "le02", kind: .speech,
        situation: "会議の時間に遅れてしまいました。部屋に入るとき、何と言いますか。",
        dialogue: [
            DialogueLine(speaker: .narrator, text: "会議の時間に遅れてしまいました。部屋に入るとき、何と言いますか。")
        ],
        question: "何と言いますか。",
        choices: ["お待たせしました。", "遅れて申し訳ありません。", "お先に失礼します。"],
        answerIndex: 1,
        explanation: "지각했을 때의 사과는 「遅れて申し訳ありません」입니다. 3번은 먼저 자리를 뜰 때 쓰는 말입니다."),

    ListeningItem(
        id: "le03", kind: .speech,
        situation: "先生に本を貸してほしいです。何と言いますか。",
        dialogue: [
            DialogueLine(speaker: .narrator, text: "先生に本を貸してほしいです。何と言いますか。")
        ],
        question: "何と言いますか。",
        choices: ["この本、お貸ししましょうか。", "この本、貸していただけませんか。", "この本、借りてもいいですね。"],
        answerIndex: 1,
        explanation: "빌려 달라는 정중한 부탁은 「貸していただけませんか」입니다. 1번은 내가 빌려주겠다는 뜻입니다."),

    ListeningItem(
        id: "le04", kind: .speech,
        situation: "店で服を着てみたいです。店員に何と言いますか。",
        dialogue: [
            DialogueLine(speaker: .narrator, text: "店で服を着てみたいです。店員に何と言いますか。")
        ],
        question: "何と言いますか。",
        choices: ["着てみてもいいですか。", "着てみましょうか。", "着てくださいませんか。"],
        answerIndex: 0,
        explanation: "허락을 구하는 「〜てもいいですか」가 맞습니다."),

    ListeningItem(
        id: "le05", kind: .speech,
        situation: "道が分からなくなりました。近くの人に聞きたいとき、何と言いますか。",
        dialogue: [
            DialogueLine(speaker: .narrator, text: "道が分からなくなりました。近くの人に聞きたいとき、何と言いますか。")
        ],
        question: "何と言いますか。",
        choices: ["駅はどこか教えてあげましょうか。", "すみません、駅はどちらでしょうか。", "駅に行ってもかまいませんか。"],
        answerIndex: 1,
        explanation: "길을 묻는 정중한 표현은 「〜はどちらでしょうか」입니다."),

    ListeningItem(
        id: "le06", kind: .speech,
        situation: "友達が試験に合格しました。何と言いますか。",
        dialogue: [
            DialogueLine(speaker: .narrator, text: "友達が試験に合格しました。何と言いますか。")
        ],
        question: "何と言いますか。",
        choices: ["おめでとう。よかったね。", "お大事に。", "おかげさまで。"],
        answerIndex: 0,
        explanation: "축하는 「おめでとう」. 「お大事に」는 아픈 사람에게, 「おかげさまで」는 감사의 답례 표현입니다."),

    ListeningItem(
        id: "le07", kind: .speech,
        situation: "会議室が暑いです。窓を開けたいとき、周りの人に何と言いますか。",
        dialogue: [
            DialogueLine(speaker: .narrator, text: "会議室が暑いです。窓を開けたいとき、周りの人に何と言いますか。")
        ],
        question: "何と言いますか。",
        choices: ["窓を開けていただけませんか。", "窓を開けてもよろしいですか。", "窓が開いていますよ。"],
        answerIndex: 1,
        explanation: "«내가» 열고 싶으므로 허락을 구하는 「開けてもよろしいですか」입니다. 1번은 남에게 열어 달라는 부탁입니다."),

    ListeningItem(
        id: "le08", kind: .speech,
        situation: "友達の家に着きました。中に入るとき、何と言いますか。",
        dialogue: [
            DialogueLine(speaker: .narrator, text: "友達の家に着きました。中に入るとき、何と言いますか。")
        ],
        question: "何と言いますか。",
        choices: ["おじゃまします。", "いらっしゃいませ。", "行ってきます。"],
        answerIndex: 0,
        explanation: "남의 집에 들어갈 때는 「おじゃまします」입니다."),
]

// MARK: 即時応答 — 짧은 말에 대한 응답 (선택지 3개, 질문은 음성 뒤)

private let quickItems: [ListeningItem] = [

    ListeningItem(
        id: "lq01", kind: .quick,
        situation: "",
        dialogue: [DialogueLine(speaker: .female, text: "この資料、コピーしておきましょうか。")],
        question: "何と答えますか。",
        choices: ["ええ、お願いします。", "はい、コピーしました。", "いいえ、コピーです。"],
        answerIndex: 0,
        explanation: "«~しましょうか»(내가 해 줄까요?)에 대한 자연스러운 수락은 「お願いします」입니다."),

    ListeningItem(
        id: "lq02", kind: .quick,
        situation: "",
        dialogue: [DialogueLine(speaker: .male, text: "その仕事、私がやりましょうか。")],
        question: "何と答えますか。",
        choices: ["いいえ、大丈夫です。自分でできます。", "はい、やりました。", "いいえ、やりましょう。"],
        answerIndex: 0,
        explanation: "제안을 거절할 때는 「大丈夫です」로 사양합니다."),

    ListeningItem(
        id: "lq03", kind: .quick,
        situation: "",
        dialogue: [DialogueLine(speaker: .female, text: "昨日の映画、どうだった？")],
        question: "何と答えますか。",
        choices: ["思ったより面白かったよ。", "明日見に行くよ。", "映画館の前だよ。"],
        answerIndex: 0,
        explanation: "감상을 묻는 질문이므로 «어땠는지»로 답합니다."),

    ListeningItem(
        id: "lq04", kind: .quick,
        situation: "",
        dialogue: [DialogueLine(speaker: .male, text: "会議、何時からでしたっけ。")],
        question: "何と答えますか。",
        choices: ["3階の会議室です。", "2時からですよ。", "私も行きました。"],
        answerIndex: 1,
        explanation: "«何時から»를 물었으므로 시각으로 답해야 합니다."),

    ListeningItem(
        id: "lq05", kind: .quick,
        situation: "",
        dialogue: [DialogueLine(speaker: .female, text: "すみません、ペンをお借りしてもいいですか。")],
        question: "何と答えますか。",
        choices: ["はい、どうぞ。", "はい、借ります。", "いいえ、貸しました。"],
        answerIndex: 0,
        explanation: "빌려 달라는 요청에 대한 승낙은 「どうぞ」입니다."),

    ListeningItem(
        id: "lq06", kind: .quick,
        situation: "",
        dialogue: [DialogueLine(speaker: .male, text: "今日はもう帰ってもいいですよ。")],
        question: "何と答えますか。",
        choices: ["では、お先に失礼します。", "いってらっしゃい。", "おかえりなさい。"],
        answerIndex: 0,
        explanation: "먼저 퇴근할 때 쓰는 인사는 「お先に失礼します」입니다."),

    ListeningItem(
        id: "lq07", kind: .quick,
        situation: "",
        dialogue: [DialogueLine(speaker: .female, text: "この店、思ったより込んでいますね。")],
        question: "何と答えますか。",
        choices: ["ええ、少し待ちましょうか。", "はい、閉まっていますね。", "いいえ、込んでください。"],
        answerIndex: 0,
        explanation: "붐빈다는 말에 이어질 자연스러운 제안은 «조금 기다리자»입니다."),

    ListeningItem(
        id: "lq08", kind: .quick,
        situation: "",
        dialogue: [DialogueLine(speaker: .male, text: "レポート、間に合いそう？")],
        question: "何と答えますか。",
        choices: ["何とか出せそうです。", "レポートを書きました。", "間に合ってください。"],
        answerIndex: 0,
        explanation: "«제때 낼 수 있겠느냐»는 질문에 대한 답은 가능 여부입니다."),

    ListeningItem(
        id: "lq09", kind: .quick,
        situation: "",
        dialogue: [DialogueLine(speaker: .female, text: "先週の旅行、天気はどうでしたか。")],
        question: "何と答えますか。",
        choices: ["ずっと雨で残念でした。", "来週行く予定です。", "飛行機で行きます。"],
        answerIndex: 0,
        explanation: "지난 여행의 «날씨»를 물었으므로 과거의 날씨로 답합니다."),

    ListeningItem(
        id: "lq10", kind: .quick,
        situation: "",
        dialogue: [DialogueLine(speaker: .male, text: "この漢字の読み方、分かりますか。")],
        question: "何と答えますか。",
        choices: ["すみません、ちょっと分からないです。", "はい、書きました。", "いいえ、読みません。"],
        answerIndex: 0,
        explanation: "모를 때는 「分からないです」로 답합니다. 2·3번은 질문과 맞지 않습니다."),
]
