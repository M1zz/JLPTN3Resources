import WidgetKit
import SwiftUI
import AppIntents

// MARK: - 타임라인
//
// 위젯은 앱이 써 둔 스냅샷만 읽는다. 카드 2,798장을 위젯에서 훑으면
// 메모리 한도(약 30MB)에 걸리기 쉽고, 그릴 때마다 느려진다.

struct StudyEntry: TimelineEntry {
    let date: Date
    let snapshot: SharedStore.Snapshot
}

struct StudyProvider: TimelineProvider {
    func placeholder(in context: Context) -> StudyEntry {
        StudyEntry(date: Date(), snapshot: .init(dueCount: 12, newCount: 10,
                                                 todayReviewed: 0, streak: 3,
                                                 cardID: "sample", front: "約束",
                                                 reading: "やくそく", meaning: "약속"))
    }

    func getSnapshot(in context: Context, completion: @escaping (StudyEntry) -> Void) {
        completion(StudyEntry(date: Date(), snapshot: SharedStore.readSnapshot()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StudyEntry>) -> Void) {
        let entry = StudyEntry(date: Date(), snapshot: SharedStore.readSnapshot())
        // 복습 시각은 앱이 바뀔 때 reloadAllTimelines로 알려 주므로,
        // 여기서는 한 시간에 한 번만 스스로 깨어나 «밀린 복습»을 다시 센다.
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - 홈 화면 위젯

struct StudyWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: StudyEntry

    var body: some View {
        switch family {
        case .accessoryCircular:    circular
        case .accessoryRectangular: rectangular
        case .accessoryInline:      inline
        case .systemMedium:         medium
        default:                    small
        }
    }

    private var snapshot: SharedStore.Snapshot { entry.snapshot }
    private var remaining: Int { snapshot.dueCount + snapshot.newCount }

    // MARK: 홈 화면 — 작게

    /// 남은 장수와 다음 낱말. 누르면 학습 화면으로 바로 들어간다.
    private var small: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Text("\(remaining)")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                Text("장 남음")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            if let front = snapshot.front {
                Text(front)
                    .font(.system(size: 22, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text(snapshot.revealed ? (snapshot.meaning ?? "") : (snapshot.reading ?? ""))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            } else {
                Text("오늘 몫을 다 했습니다")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Text(snapshot.todayReviewed > 0 ? "오늘 \(snapshot.todayReviewed)장" : "학습하러 가기")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .widgetURL(URL(string: "jlptn3://study"))
    }

    // MARK: 홈 화면 — 중간 (여기서 바로 채점까지)

    private var medium: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(remaining)")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                Text("장 남음")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                if snapshot.streak > 0 {
                    Text("연속 \(snapshot.streak)일")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Link(destination: URL(string: "jlptn3://study")!) {
                    Text("앱에서 학습")
                        .font(.system(size: 10, weight: .bold))
                }
            }
            .frame(width: 74, alignment: .leading)

            Divider()

            if let front = snapshot.front {
                VStack(alignment: .leading, spacing: 6) {
                    Text(front)
                        .font(.system(size: 26, weight: .black))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)

                    if snapshot.revealed {
                        Text(snapshot.reading ?? "")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Text(snapshot.meaning ?? "")
                            .font(.system(size: 13, weight: .semibold))
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                        Spacer(minLength: 0)
                        HStack(spacing: 6) {
                            // 위젯 안에서 그대로 채점한다 (앱이 열리지 않는다)
                            Button(intent: RateCardIntent(ratingValue: SRSRating.again.rawValue)) {
                                Text("몰랐다").font(.system(size: 12, weight: .bold))
                                    .frame(maxWidth: .infinity)
                            }
                            .tint(.red)
                            Button(intent: RateCardIntent(ratingValue: SRSRating.good.rawValue)) {
                                Text("알았다").font(.system(size: 12, weight: .bold))
                                    .frame(maxWidth: .infinity)
                            }
                            .tint(.green)
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Spacer(minLength: 0)
                        Button(intent: RevealMeaningIntent()) {
                            Text("뜻 보기")
                                .font(.system(size: 13, weight: .bold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 4) {
                    Text("오늘 몫을 다 했습니다")
                        .font(.system(size: 14, weight: .bold))
                    Text("내일 복습할 카드가 준비됩니다")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: 잠금화면 — 동그라미 (남은 장수)

    private var circular: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Text("\(remaining)")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .minimumScaleFactor(0.5)
                Text("장")
                    .font(.system(size: 9))
            }
        }
        .widgetURL(URL(string: "jlptn3://study"))
    }

    // MARK: 잠금화면 — 네모 (낱말 + 채점 버튼)

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let front = snapshot.front {
                Text(front)
                    .font(.system(size: 15, weight: .bold))
                    .lineLimit(1)
                if snapshot.revealed {
                    Text(snapshot.meaning ?? "")
                        .font(.system(size: 12))
                        .lineLimit(1)
                    HStack(spacing: 8) {
                        Button(intent: RateCardIntent(ratingValue: SRSRating.again.rawValue)) {
                            Text("몰랐다").font(.system(size: 11, weight: .bold))
                        }
                        Button(intent: RateCardIntent(ratingValue: SRSRating.good.rawValue)) {
                            Text("알았다").font(.system(size: 11, weight: .bold))
                        }
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(snapshot.reading ?? "")
                        .font(.system(size: 11))
                        .lineLimit(1)
                    Button(intent: RevealMeaningIntent()) {
                        Text("뜻 보기").font(.system(size: 11, weight: .bold))
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Text("오늘 몫 완료")
                    .font(.system(size: 14, weight: .bold))
                Text("남은 카드 없음")
                    .font(.system(size: 11))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: 잠금화면 — 한 줄

    private var inline: some View {
        // 시계 위 한 줄. 버튼을 넣을 수 없으므로 눌러서 앱으로 간다.
        Text(remaining > 0 ? "N3 \(remaining)장 · \(snapshot.front ?? "")"
                           : "N3 오늘 몫 완료")
            .widgetURL(URL(string: "jlptn3://study"))
    }
}

// MARK: - 위젯 정의

struct StudyWidget: Widget {
    let kind = "JLPTN3StudyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StudyProvider()) { entry in
            StudyWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("N3 학습")
        .description("남은 카드를 보고, 잠금화면에서 바로 외웁니다.")
        .supportedFamilies([.systemSmall, .systemMedium,
                            .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

@main
struct JLPTN3WidgetBundle: WidgetBundle {
    var body: some Widget {
        StudyWidget()
    }
}
