import Foundation
import WidgetKit

// MARK: - 앱과 위젯이 함께 쓰는 저장소
//
// 위젯은 앱과 다른 프로세스라 UserDefaults.standard를 나눠 쓸 수 없다.
// App Group을 하나 두고 양쪽이 같은 저장소를 보게 한다.
//
// 이전 판은 standard에 저장했으므로, 처음 한 번 옮겨 온다.

enum SharedStore {

    static let appGroup = "group.com.gaebaljari.JLPTN3Resources"

    /// 앱·위젯 공용 저장소. App Group을 쓸 수 없는 상황(설정 누락 등)에서는
    /// standard로 물러난다 — 위젯 데이터는 비지만 앱은 그대로 동작한다.
    static let defaults: UserDefaults = {
        guard let shared = UserDefaults(suiteName: appGroup) else { return .standard }
        migrateIfNeeded(to: shared)
        return shared
    }()

    /// 옮겨야 할 키들 — 학습 진도·연습 기록·단어장
    private static let keys = [
        "n3_cards_v2", "n3_stats_v2",
        "n3_reading_results_v1", "n3_listening_results_v1", "n3_mock_results_v1",
        "n3_vocab_notes_v1",
    ]

    private static let migratedKey = "n3_migrated_to_group_v1"

    private static func migrateIfNeeded(to shared: UserDefaults) {
        guard !shared.bool(forKey: migratedKey) else { return }
        let standard = UserDefaults.standard
        for key in keys {
            // 이미 공용 저장소에 값이 있으면 덮어쓰지 않는다
            guard shared.object(forKey: key) == nil,
                  let value = standard.object(forKey: key) else { continue }
            shared.set(value, forKey: key)
        }
        shared.set(true, forKey: migratedKey)
    }

    // MARK: 위젯이 읽는 요약

    /// 위젯 화면에 필요한 최소한의 정보.
    /// 위젯이 카드 전체를 훑지 않도록 앱이 바뀔 때마다 여기에 적어 둔다.
    struct Snapshot: Codable {
        var dueCount: Int
        var newCount: Int
        var todayReviewed: Int
        var streak: Int
        /// 지금 낼 카드
        var cardID: String?
        var front: String?
        var reading: String?
        var meaning: String?
        /// 이 카드의 뜻을 위젯에서 펼쳐 두었는지
        var revealed: Bool = false

        static let empty = Snapshot(dueCount: 0, newCount: 0, todayReviewed: 0,
                                    streak: 0, cardID: nil, front: nil,
                                    reading: nil, meaning: nil)
    }

    private static let snapshotKey = "n3_widget_snapshot_v1"

    static func writeSnapshot(_ snapshot: Snapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: snapshotKey)
    }

    /// 위젯을 새로 그리게 한다 (앱에서 진도가 바뀌었을 때)
    static func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func readSnapshot() -> Snapshot {
        guard let data = defaults.data(forKey: snapshotKey),
              let decoded = try? JSONDecoder().decode(Snapshot.self, from: data)
        else { return .empty }
        return decoded
    }
}
