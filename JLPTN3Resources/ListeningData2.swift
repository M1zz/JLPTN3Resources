import Foundation

// MARK: - 청해 연습 데이터 (추가분)
//
// 실제 시험 1회분이 청해 28문항이다. 기존 40문항은 한 회분 반쯤이라
// 유형 감각을 잡기에 모자란다. 같은 다섯 유형으로 32문항을 더 만든다.
// 대본은 전부 자체 제작이며, 음성은 AVSpeechSynthesizer가 읽는다.

let listeningItems2: [ListeningItem] =
    taskItems2 + pointItems2 + summaryItems2 + speechItems2 + quickItems2

// MARK: 課題理解 — 이 다음에 무엇을 하는가

private let taskItems2: [ListeningItem] = [

    ListeningItem(
        id: "lt11", kind: .task,
        situation: "会社で女の人と男の人が話しています。男の人はこのあとまず何をしますか。",
        dialogue: [
            DialogueLine(speaker: .female, text: "田村君、来週の説明会だけど、席は何人分用意した？"),
            DialogueLine(speaker: .male, text: "50人分です。申し込みが45人だったので、少し多めに。"),
            DialogueLine(speaker: .female, text: "実はさっき10人増えたの。椅子を追加してもらえる？"),
            DialogueLine(speaker: .male, text: "分かりました。倉庫から運んできます。"),
            DialogueLine(speaker: .female, text: "あ、その前に資料ね。人数が変わったから、先に印刷をお願い。椅子はそのあとで。"),
            DialogueLine(speaker: .male, text: "はい、そうします。"),
        ],
        question: "男の人はこのあとまず何をしますか。",
        choices: ["資料を印刷する", "倉庫から椅子を運ぶ", "申し込みの数を数える", "説明会の席を減らす"],
        answerIndex: 0,
        explanation: "남자가 의자를 옮기려 하자 여자가 「その前に資料ね…先に印刷をお願い。椅子はそのあとで」라고 순서를 바꿨습니다. «먼저 무엇을»을 묻는 유형은 이렇게 뒤집는 말이 정답을 정합니다."),

    ListeningItem(
        id: "lt12", kind: .task,
        situation: "大学で先生と学生が話しています。学生はこのあとまず何をしますか。",
        dialogue: [
            DialogueLine(speaker: .male, text: "先生、レポートのことでご相談したいのですが。"),
            DialogueLine(speaker: .female, text: "はい、どうしましたか。"),
            DialogueLine(speaker: .male, text: "テーマを変えたいんです。調べてみたら資料が少なくて。"),
            DialogueLine(speaker: .female, text: "変えるのはかまいませんよ。ただ、新しいテーマを紙に書いて出してください。"),
            DialogueLine(speaker: .male, text: "分かりました。すぐ書いて持ってきます。"),
            DialogueLine(speaker: .female, text: "急がなくていいです。図書館で資料があるかどうか確かめてから書いたほうがいいですよ。同じことになってしまいますから。"),
        ],
        question: "学生はこのあとまず何をしますか。",
        choices: ["先生にもう一度相談する", "図書館で資料があるか調べる", "新しいテーマを紙に書く", "レポートを書き始める"],
        answerIndex: 1,
        explanation: "학생은 바로 쓰겠다고 했지만, 선생님이 「資料があるかどうか確かめてから書いたほうがいい」라고 했습니다. 같은 실수를 반복하지 않기 위해 «자료 확인»이 먼저입니다."),

    ListeningItem(
        id: "lt13", kind: .task,
        situation: "家で母親と息子が話しています。息子はこのあとまず何をしますか。",
        dialogue: [
            DialogueLine(speaker: .female, text: "ゆうた、出かける前に部屋を片づけてね。"),
            DialogueLine(speaker: .male, text: "うん。あ、その前に洗濯物を取り込んでおこうか。雨が降りそうだし。"),
            DialogueLine(speaker: .female, text: "それはお母さんがやるからいいわ。それより、ごみを出す日でしょう。もう8時よ。"),
            DialogueLine(speaker: .male, text: "あ、忘れてた。8時までだったよね。"),
            DialogueLine(speaker: .female, text: "今からでも間に合うから、走って行ってきなさい。"),
        ],
        question: "息子はこのあとまず何をしますか。",
        choices: ["洗濯物を取り込む", "出かける", "ごみを出しに行く", "部屋を片づける"],
        answerIndex: 2,
        explanation: "빨래는 엄마가 하고, 방 정리는 나가기 전이면 됩니다. 시간이 급한 «쓰레기 배출»이 먼저입니다."),

    ListeningItem(
        id: "lt14", kind: .task,
        situation: "店で店長とアルバイトの人が話しています。アルバイトの人はこのあとまず何をしますか。",
        dialogue: [
            DialogueLine(speaker: .male, text: "今日はお客さんが少ないね。"),
            DialogueLine(speaker: .female, text: "はい。じゃあ、今のうちに棚を並べ直しておきましょうか。"),
            DialogueLine(speaker: .male, text: "うん、でもその前に。冷蔵庫の温度、朝から少し高いままなんだ。数字を紙に書いておいてくれる？"),
            DialogueLine(speaker: .female, text: "はい。書いたら店長に見せればいいですか。"),
            DialogueLine(speaker: .male, text: "いや、そのまま机に置いておいて。僕は今から本社に電話するから。"),
        ],
        question: "アルバイトの人はこのあとまず何をしますか。",
        choices: ["棚を並べ直す", "店長に温度を見せる", "本社に電話する", "冷蔵庫の温度を紙に書く"],
        answerIndex: 3,
        explanation: "「その前に」 뒤가 먼저 할 일입니다. 종이는 보여 주는 게 아니라 «机に置いておいて»이고, 전화는 점장이 합니다."),

    ListeningItem(
        id: "lt15", kind: .task,
        situation: "旅行の前に女の人と男の人が話しています。女の人はこのあとまず何をしますか。",
        dialogue: [
            DialogueLine(speaker: .female, text: "切符はもう買ったし、ホテルも予約したし、準備はだいたい終わったかな。"),
            DialogueLine(speaker: .male, text: "パスポートは？期限、大丈夫だった？"),
            DialogueLine(speaker: .female, text: "あ……見てない。確か去年までだったような。"),
            DialogueLine(speaker: .male, text: "それ、先に見たほうがいいよ。切れてたら旅行どころじゃないから。"),
            DialogueLine(speaker: .female, text: "そうだね。荷物を作るのは後にする。"),
        ],
        question: "女の人はこのあとまず何をしますか。",
        choices: ["パスポートの期限を確かめる", "荷物を作る", "切符を買う", "ホテルを予約する"],
        answerIndex: 0,
        explanation: "표와 호텔은 이미 끝났고, 짐 싸기는 «後にする»입니다. 여권 유효기간 확인이 먼저입니다."),

    ListeningItem(
        id: "lt16", kind: .task,
        situation: "会社で女の人が男の人に電話しています。男の人はこのあとまず何をしますか。",
        dialogue: [
            DialogueLine(speaker: .female, text: "もしもし、佐藤さん？今、駅にいるんだけど、電車が止まっていて。"),
            DialogueLine(speaker: .male, text: "え、じゃあ2時の打ち合わせは。"),
            DialogueLine(speaker: .female, text: "30分くらい遅れそう。先方に連絡してもらえる？"),
            DialogueLine(speaker: .male, text: "分かりました。会議室の準備もしておきます。"),
            DialogueLine(speaker: .female, text: "うん、でも連絡が先ね。待たせたら失礼だから。"),
        ],
        question: "男の人はこのあとまず何をしますか。",
        choices: ["打ち合わせを取り消す", "相手の会社に連絡する", "会議室を準備する", "駅まで迎えに行く"],
        answerIndex: 1,
        explanation: "「連絡が先ね」라고 순서를 못 박았습니다. 회의실 준비는 그다음입니다."),
]

// MARK: ポイント理解 — 한 가지 정보(이유·시각·장소)

private let pointItems2: [ListeningItem] = [

    ListeningItem(
        id: "lp11", kind: .point,
        situation: "男の人と女の人が話しています。男の人はどうして引っ越すことにしましたか。",
        dialogue: [
            DialogueLine(speaker: .female, text: "来月引っ越すんだって？今の部屋、駅から近くていいのに。"),
            DialogueLine(speaker: .male, text: "うん、場所は気に入ってるんだけどね。"),
            DialogueLine(speaker: .female, text: "家賃が上がるの？"),
            DialogueLine(speaker: .male, text: "それは変わらないよ。ただ、去年から在宅で働くことが増えて、部屋が一つだと机を置く場所がなくて。"),
            DialogueLine(speaker: .female, text: "ああ、仕事をする場所か。"),
            DialogueLine(speaker: .male, text: "そう。少し駅から遠くなるけど、部屋が二つあるところにする。"),
        ],
        question: "男の人はどうして引っ越すことにしましたか。",
        choices: ["駅から遠くて不便だから",
                  "近所がうるさいから",
                  "働く場所が部屋の中に必要になったから",
                  "家賃が高くなったから"],
        answerIndex: 2,
        explanation: "집세는 «変わらない», 위치는 «気に入ってる»입니다. 이유는 재택근무가 늘어 책상 둘 곳이 없다는 것입니다."),

    ListeningItem(
        id: "lp12", kind: .point,
        situation: "女の人と男の人が話しています。二人はいつ会いますか。",
        dialogue: [
            DialogueLine(speaker: .male, text: "今週、どこかで食事でもどう？"),
            DialogueLine(speaker: .female, text: "いいね。水曜か木曜なら空いてるよ。"),
            DialogueLine(speaker: .male, text: "水曜は会議が遅くまであるんだ。木曜にしようか。"),
            DialogueLine(speaker: .female, text: "あ、ごめん。木曜、母が来るんだった。金曜は？"),
            DialogueLine(speaker: .male, text: "金曜なら大丈夫。じゃあ、それで。"),
        ],
        question: "二人はいつ会いますか。",
        choices: ["水曜日", "木曜日", "土曜日", "金曜日"],
        answerIndex: 3,
        explanation: "수요일은 남자가 회의, 목요일은 여자 어머니가 오심 → 금요일로 결정됐습니다. 이런 유형은 «후보가 하나씩 지워지는» 흐름을 따라가면 됩니다."),

    ListeningItem(
        id: "lp13", kind: .point,
        situation: "先生が学生に話しています。試験の日はどう変わりましたか。",
        dialogue: [
            DialogueLine(speaker: .female, text: "みなさん、試験のことでお知らせがあります。"),
            DialogueLine(speaker: .female, text: "20日の火曜日に行う予定でしたが、その日は学校の行事が入りました。"),
            DialogueLine(speaker: .female, text: "そこで、一週間後の27日に変えます。曜日は同じ火曜日です。"),
            DialogueLine(speaker: .female, text: "時間は変わりません。1時からです。教室だけ、201から305に変わりますので気をつけてください。"),
        ],
        question: "試験について、変わったのは何ですか。",
        choices: ["日にちと教室", "時間と教室", "日にちと時間", "曜日と時間"],
        answerIndex: 0,
        explanation: "20일 → 27일(날짜 변경), 201 → 305(교실 변경). 요일(화요일)과 시간(1시)은 «変わりません»입니다."),

    ListeningItem(
        id: "lp14", kind: .point,
        situation: "男の人と女の人が話しています。女の人はどうして疲れていますか。",
        dialogue: [
            DialogueLine(speaker: .male, text: "なんだか眠そうだね。仕事が忙しかった？"),
            DialogueLine(speaker: .female, text: "ううん、仕事は普通。昨日、隣の部屋の工事が朝早くから始まって。"),
            DialogueLine(speaker: .male, text: "ああ、それは大変だ。夜も続いたの？"),
            DialogueLine(speaker: .female, text: "夜は静かだったんだけど、目が覚めたのが5時で、そのあと眠れなくて。"),
        ],
        question: "女の人はどうして疲れていますか。",
        choices: ["隣の人と話していたから",
                  "朝早く工事の音で起きて、それから眠れなかったから",
                  "夜遅くまで仕事をしたから",
                  "夜中じゅう工事の音がしていたから"],
        answerIndex: 1,
        explanation: "밤에는 «静かだった»고 했습니다. 아침 5시에 공사 소리로 깬 뒤 다시 못 잔 것이 이유입니다."),

    ListeningItem(
        id: "lp15", kind: .point,
        situation: "店で客と店員が話しています。客はいくら払いますか。",
        dialogue: [
            DialogueLine(speaker: .female, text: "このかばん、おいくらですか。"),
            DialogueLine(speaker: .male, text: "8,000円です。今週は全品10%引きですので、7,200円になります。"),
            DialogueLine(speaker: .female, text: "カードは使えますか。"),
            DialogueLine(speaker: .male, text: "はい。あ、こちらの会員カードをお持ちでしたら、さらに200円お引きします。"),
            DialogueLine(speaker: .female, text: "持っています。じゃあ、それでお願いします。"),
        ],
        question: "客はいくら払いますか。",
        choices: ["8,000円", "7,800円", "7,000円", "7,200円"],
        answerIndex: 2,
        explanation: "8,000엔 → 10% 할인 7,200엔 → 회원 카드로 200엔 추가 할인 = 7,000엔. 숫자가 여러 번 나오는 유형은 마지막까지 들어야 합니다."),

    ListeningItem(
        id: "lp16", kind: .point,
        situation: "女の人と男の人が話しています。男の人はどこで待ちますか。",
        dialogue: [
            DialogueLine(speaker: .female, text: "明日、駅前の本屋の前で待ち合わせでいい？"),
            DialogueLine(speaker: .male, text: "うん。あ、でも明日は雨だよね。"),
            DialogueLine(speaker: .female, text: "そうだった。じゃあ、駅の中の改札の前は？"),
            DialogueLine(speaker: .male, text: "改札は人が多くて分かりにくいから、その隣の花屋の前にしない？"),
            DialogueLine(speaker: .female, text: "いいよ、そうしよう。"),
        ],
        question: "二人はどこで待ち合わせますか。",
        choices: ["駅前の本屋の前", "改札の前", "駅の外", "駅の中の花屋の前"],
        answerIndex: 3,
        explanation: "서점 앞 → 비 때문에 취소, 개찰구 앞 → 사람이 많아 취소, 결국 «その隣の花屋の前»입니다."),
]

// MARK: 概要理解 — 전체 내용·주장

private let summaryItems2: [ListeningItem] = [

    ListeningItem(
        id: "ls11", kind: .summary,
        situation: "ラジオで女の人が話しています。",
        dialogue: [
            DialogueLine(speaker: .female, text: "毎年この時期になると、「今年こそ運動を始めよう」という声をよく聞きます。"),
            DialogueLine(speaker: .female, text: "けれども、三か月後まで続いている人は10人に1人ほどだそうです。"),
            DialogueLine(speaker: .female, text: "続かない理由を調べると、時間がないからではなく、「最初に決めた目標が高すぎた」という答えが一番多いのです。"),
            DialogueLine(speaker: .female, text: "毎日1時間走ると決めた人より、週に二回、20分だけ歩くと決めた人のほうが、一年後も続けています。"),
            DialogueLine(speaker: .female, text: "始めるときに大切なのは、強い気持ちよりも、低い目標なのかもしれません。"),
        ],
        question: "女の人は何について話していますか。",
        choices: ["運動を続けるには目標を低くするほうがいいということ",
                  "運動をする時間を作る方法",
                  "毎日走ることの体への効果",
                  "運動を始める人が減っていること"],
        answerIndex: 0,
        explanation: "«続かない理由 = 목표가 너무 높아서» → «낮은 목표가 오래 간다»는 흐름입니다. 概要理解는 세부 숫자가 아니라 이 결론을 잡아야 합니다."),

    ListeningItem(
        id: "ls12", kind: .summary,
        situation: "会社で男の人が話しています。",
        dialogue: [
            DialogueLine(speaker: .male, text: "新しい制度について説明します。来月から、週に一日は家で働けるようになります。"),
            DialogueLine(speaker: .male, text: "ただ、これは「休みが増える」ということではありません。"),
            DialogueLine(speaker: .male, text: "会社にいないぶん、何をしているかが見えにくくなりますから、朝と夕方に短い報告をお願いします。"),
            DialogueLine(speaker: .male, text: "長い文章は要りません。三行で十分です。"),
            DialogueLine(speaker: .male, text: "自由に働ける代わりに、伝えることは今までより丁寧に。これだけ守っていただければ大丈夫です。"),
        ],
        question: "男の人が一番言いたいことは何ですか。",
        choices: ["家で働くことは認められない",
                  "家で働くときは、報告をこれまでより丁寧にしてほしい",
                  "来月から休みが増える",
                  "長い報告書を毎日書いてほしい"],
        answerIndex: 1,
        explanation: "「自由に働ける代わりに、伝えることは今までより丁寧に」가 결론입니다. 보고는 «三行で十分»이라고 했으니 긴 보고서는 아닙니다."),

    ListeningItem(
        id: "ls13", kind: .summary,
        situation: "テレビで男の人が話しています。",
        dialogue: [
            DialogueLine(speaker: .male, text: "この町の図書館は、去年から本を借りる人が急に増えました。"),
            DialogueLine(speaker: .male, text: "本を増やしたわけでも、建物を新しくしたわけでもありません。"),
            DialogueLine(speaker: .male, text: "変えたのは、開いている時間だけです。夜9時まで開けるようにしたのです。"),
            DialogueLine(speaker: .male, text: "仕事が終わってから寄れるようになり、これまで昼間に来られなかった人が来るようになりました。"),
            DialogueLine(speaker: .male, text: "何を置くかより、いつ開けるか。それだけで人の流れは変わるのですね。"),
        ],
        question: "男の人は何について話していますか。",
        choices: ["本の数を増やす必要があること",
                  "夜に働く人が増えていること",
                  "開く時間を変えたことで図書館の利用者が増えたこと",
                  "図書館の建物が新しくなったこと"],
        answerIndex: 2,
        explanation: "「変えたのは、開いている時間だけ」이 핵심이고, 마지막 줄이 그것을 다시 정리합니다."),

    ListeningItem(
        id: "ls14", kind: .summary,
        situation: "先生が学生に話しています。",
        dialogue: [
            DialogueLine(speaker: .female, text: "発表の練習をするとき、多くの人は原稿を覚えようとします。"),
            DialogueLine(speaker: .female, text: "でも、覚えた言葉は一か所忘れると全部止まってしまいます。"),
            DialogueLine(speaker: .female, text: "覚えるのは言葉ではなく、話の順番にしてください。"),
            DialogueLine(speaker: .female, text: "「初めに問題、次に理由、最後に提案」というように、大きな流れだけ頭に入れる。"),
            DialogueLine(speaker: .female, text: "そうすれば、言葉が少し変わっても、話は最後まで進みます。"),
        ],
        question: "先生は発表の練習について、どうするように言っていますか。",
        choices: ["原稿を全部覚えるようにする",
                  "原稿を見ながら話す",
                  "短い言葉だけを覚える",
                  "話の順番を覚えるようにする"],
        answerIndex: 3,
        explanation: "「覚えるのは言葉ではなく、話の順番に」가 지시의 핵심입니다."),
]

// MARK: 発話表現 — 이 상황에서 뭐라고 말하나

private let speechItems2: [ListeningItem] = [

    ListeningItem(
        id: "lh11", kind: .speech,
        situation: "電車で、前の人が切符を落としました。何と言いますか。",
        dialogue: [DialogueLine(speaker: .narrator, text: "電車で、前の人が切符を落としました。何と言いますか。")],
        question: "何と言いますか。",
        choices: ["切符を落としてくださいませんか。", "すみません、切符が落ちましたよ。", "切符を落としてもいいですか。"],
        answerIndex: 1,
        explanation: "떨어진 것을 알려 줄 때는 「〜が落ちましたよ」입니다. 나머지는 «떨어뜨려도 되나요 / 떨어뜨려 주세요»가 되어 뜻이 이상합니다."),

    ListeningItem(
        id: "lh12", kind: .speech,
        situation: "友だちの家で、そろそろ帰りたいです。何と言いますか。",
        dialogue: [DialogueLine(speaker: .narrator, text: "友だちの家で、そろそろ帰りたいです。何と言いますか。")],
        question: "何と言いますか。",
        choices: ["そろそろ帰ってください。", "そろそろお帰りになりますか。", "そろそろ失礼します。"],
        answerIndex: 2,
        explanation: "내가 자리를 뜰 때는 「失礼します」입니다. 「帰ってください」「お帰りになりますか」는 상대에게 가라고 하는 말이 됩니다."),

    ListeningItem(
        id: "lh13", kind: .speech,
        situation: "先生に、書いた作文を見てもらいたいです。何と言いますか。",
        dialogue: [DialogueLine(speaker: .narrator, text: "先生に、書いた作文を見てもらいたいです。何と言いますか。")],
        question: "何と言いますか。",
        choices: ["先生、この作文を見ていただけませんか。", "先生、この作文を見てさしあげましょうか。", "先生、この作文を拝見しませんか。"],
        answerIndex: 0,
        explanation: "부탁은 「〜ていただけませんか」입니다. «見てさしあげる»는 내가 선생님께 보여 준다는 실례되는 말이고, «拝見»은 내가 보는 겸양어입니다."),

    ListeningItem(
        id: "lh14", kind: .speech,
        situation: "会議室が寒いので、エアコンを弱くしてほしいです。何と言いますか。",
        dialogue: [DialogueLine(speaker: .narrator, text: "会議室が寒いので、エアコンを弱くしてほしいです。何と言いますか。")],
        question: "何と言いますか。",
        choices: ["少し寒いので、弱くしてあげますよ。", "少し寒いので、弱くしてもらえますか。", "少し寒いので、強くしましょうか。"],
        answerIndex: 1,
        explanation: "남에게 부탁하는 「〜てもらえますか」가 맞습니다. 「強くしましょうか」는 반대로 세게, 「弱くしてあげますよ」는 내가 해 준다는 말입니다."),

    ListeningItem(
        id: "lh15", kind: .speech,
        situation: "重そうな荷物を持っている人を手伝いたいです。何と言いますか。",
        dialogue: [DialogueLine(speaker: .narrator, text: "重そうな荷物を持っている人を手伝いたいです。何と言いますか。")],
        question: "何と言いますか。",
        choices: ["持ってくださいませんか。", "持っていただけますか。", "お持ちしましょうか。"],
        answerIndex: 2,
        explanation: "내가 도와주겠다는 제안은 겸양의 「お持ちしましょうか」입니다. 「持ってくださいませんか」「持っていただけますか」는 상대에게 들어 달라는 부탁입니다."),

    ListeningItem(
        id: "lh16", kind: .speech,
        situation: "約束の時間に遅れてしまいました。相手に会って何と言いますか。",
        dialogue: [DialogueLine(speaker: .narrator, text: "約束の時間に遅れてしまいました。相手に会って何と言いますか。")],
        question: "何と言いますか。",
        choices: ["お待たせしてすみません。", "お待ちしてすみません。", "待たせていただきました。"],
        answerIndex: 0,
        explanation: "«기다리게 해서»는 사역 「待たせる」의 겸양형 「お待たせして」입니다. «お待ちして»는 내가 기다린 것이 됩니다."),
]

// MARK: 即時応答 — 짧은 말에 대한 응답

private let quickItems2: [ListeningItem] = [

    ListeningItem(
        id: "lq11", kind: .quick,
        situation: "",
        dialogue: [DialogueLine(speaker: .male, text: "明日の会議、何時からでしたっけ。")],
        question: "何と答えますか。",
        choices: ["ええ、行きましたよ。", "10時からですよ。", "はい、会議室です。"],
        answerIndex: 1,
        explanation: "「何時から」를 물었으므로 시각으로 답합니다. 「〜でしたっけ」는 잊은 것을 확인하는 말입니다."),

    ListeningItem(
        id: "lq12", kind: .quick,
        situation: "",
        dialogue: [DialogueLine(speaker: .female, text: "この書類、コピーは何部いりますか。")],
        question: "何と答えますか。",
        choices: ["コピー機は3階です。", "はい、コピーしました。", "5部お願いします。"],
        answerIndex: 2,
        explanation: "«몇 부»를 물었으니 수량으로 답합니다."),

    ListeningItem(
        id: "lq13", kind: .quick,
        situation: "",
        dialogue: [DialogueLine(speaker: .male, text: "ここ、座ってもいいですか。")],
        question: "何と答えますか。",
        choices: ["どうぞ、空いていますよ。", "はい、座りました。", "いいえ、座りましょう。"],
        answerIndex: 0,
        explanation: "허가를 구하는 말에는 「どうぞ」로 허락합니다."),

    ListeningItem(
        id: "lq14", kind: .quick,
        situation: "",
        dialogue: [DialogueLine(speaker: .female, text: "傘、持ってくればよかった。")],
        question: "何と答えますか。",
        choices: ["傘を買いましょうか、私が。", "よかったら、入りますか。", "はい、持ってきました。"],
        answerIndex: 1,
        explanation: "「〜ばよかった」는 «가져올걸» 하는 후회입니다. 우산을 같이 쓰자고 권하는 「よかったら、入りますか」가 자연스럽습니다."),

    ListeningItem(
        id: "lq15", kind: .quick,
        situation: "",
        dialogue: [DialogueLine(speaker: .male, text: "山田さん、もう帰られましたか。")],
        question: "何と答えますか。",
        choices: ["はい、帰りましょう。", "いいえ、帰られます。", "ええ、さっき出ました。"],
        answerIndex: 2,
        explanation: "「帰られましたか」는 존경 표현으로 «가셨습니까»입니다. 이미 나갔다고 답하는 「さっき出ました」가 맞습니다."),

    ListeningItem(
        id: "lq16", kind: .quick,
        situation: "",
        dialogue: [DialogueLine(speaker: .female, text: "この漢字、読み方が分からないんですが。")],
        question: "何と答えますか。",
        choices: ["ああ、それは「けしき」と読みます。", "はい、書き方は簡単です。", "いいえ、分かりませんでした。"],
        answerIndex: 0,
        explanation: "읽는 법을 모른다는 말에는 읽는 법을 알려 주는 것이 자연스럽습니다."),

    ListeningItem(
        id: "lq17", kind: .quick,
        situation: "",
        dialogue: [DialogueLine(speaker: .male, text: "熱があるなら、無理しないほうがいいよ。")],
        question: "何と答えますか。",
        choices: ["いいえ、熱がありました。", "ありがとう。今日は早く帰ります。", "はい、無理しました。"],
        answerIndex: 1,
        explanation: "걱정해 주는 말에는 감사와 함께 앞으로 어떻게 하겠다고 답합니다."),

    ListeningItem(
        id: "lq18", kind: .quick,
        situation: "",
        dialogue: [DialogueLine(speaker: .female, text: "お先に失礼します。")],
        question: "何と答えますか。",
        choices: ["いってきます。", "おかえりなさい。", "お疲れさまでした。"],
        answerIndex: 2,
        explanation: "먼저 퇴근하는 사람에게는 「お疲れさまでした」로 답합니다. 회사에서 굳어진 인사입니다."),

    ListeningItem(
        id: "lq19", kind: .quick,
        situation: "",
        dialogue: [DialogueLine(speaker: .male, text: "この店、思ったより高くなかったね。")],
        question: "何と答えますか。",
        choices: ["うん、また来てもいいね。", "うん、高くて入れないね。", "うん、もう行かないほうがいいね。"],
        answerIndex: 0,
        explanation: "«생각보다 비싸지 않았다»는 긍정적인 감상이므로, 또 오자는 「また来てもいいね」가 어울립니다."),

    ListeningItem(
        id: "lq20", kind: .quick,
        situation: "",
        dialogue: [DialogueLine(speaker: .female, text: "レポート、間に合いそう？")],
        question: "何と答えますか。",
        choices: ["いいえ、出しました。", "何とか出せそうです。", "はい、間に合いました。"],
        answerIndex: 1,
        explanation: "«제때 낼 수 있을 것 같냐»는 앞일에 대한 질문이므로 「〜そうです」로 답합니다."),
]
