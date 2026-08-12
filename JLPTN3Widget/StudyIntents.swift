import AppIntents
import WidgetKit

// MARK: - 위젯 안에서 실제로 학습하기
//
// iOS 17부터 위젯의 버튼이 AppIntent를 직접 실행할 수 있다(앱을 열지 않는다).
// 그래서 «뜻 보기 → 몰랐다 / 알았다»까지 잠금화면에서 끝낼 수 있다.
//
// 채점은 앱과 같은 LearningStore를 써서 SM-2를 그대로 태운다.
// 위젯이 따로 계산하면 앱과 진도가 어긋난다.

struct RevealMeaningIntent: AppIntent {
    static var title: LocalizedStringResource = "뜻 보기"
    /// 앱을 열지 않고 위젯 안에서 끝낸다
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        var snapshot = SharedStore.readSnapshot()
        snapshot.revealed = true
        SharedStore.writeSnapshot(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

struct RateCardIntent: AppIntent {
    static var title: LocalizedStringResource = "채점하기"
    static var openAppWhenRun: Bool = false

    /// 1 = 몰랐다(again), 3 = 알았다(good)
    @Parameter(title: "평가")
    var ratingValue: Int

    init() { ratingValue = 3 }
    init(ratingValue: Int) { self.ratingValue = ratingValue }

    func perform() async throws -> some IntentResult {
        let snapshot = SharedStore.readSnapshot()
        guard let cardID = snapshot.cardID,
              let rating = SRSRating(rawValue: ratingValue) else { return .result() }

        // 앱과 같은 엔진으로 채점하고, 다음 카드를 스냅샷에 실어 준다
        let store = LearningStore()
        store.rate(cardId: cardID, rating: rating)
        store.publishWidgetSnapshot(revealed: false)

        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
