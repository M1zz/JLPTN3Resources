import SwiftUI

// MARK: - 연습 허브
//
// 시험 과목 그대로 «쓰기(문자·어휘) · 독해 · 청해»를 한 탭에 모은다.
// 탭 막대는 5개까지가 보기 좋으므로, 세 연습을 이 화면 아래에 둔다.

struct PracticeHubView: View {
    @EnvironmentObject private var practice: PracticeStore
    /// 단어장은 이 자리에서 한 번만 만들어 독해 화면과 나눠 쓴다.
    /// 화면마다 새로 만들면 한쪽에서 담은 단어가 다른 쪽에 바로 비치지 않는다.
    @EnvironmentObject private var notes: VocabNoteStore
    @EnvironmentObject private var learning: LearningStore

    /// 카드에 적을 한 줄 요약 — 틀린 것이 있으면 그것부터 알린다
    private var studyLogDetail: String {
        let acquired = learning.cards.filter { $0.mastery == .acquired }.count
        let learningCount = learning.cards.filter { $0.mastery == .learning }.count
        if acquired == 0 && learningCount == 0 { return "아직 시작하지 않았습니다" }
        return "알게 됨 \(acquired)개 · 습득 못함 \(learningCount)개"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        header

                        NavigationLink {
                            KanjiWritingView()
                        } label: {
                            card(icon: "pencil.line",
                                 title: "쓰기 · 읽기 · 듣기 (단어)",
                                 subtitle: "한자를 쓰고, 읽기를 떠올리고, 소리로 받아쓰기",
                                 detail: "어휘 \(LearningCard.vocabularyWordCount)개 · 획순 \(KanjiStrokes.count)자",
                                 progress: nil)
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            ReadingView(store: practice, notes: notes)
                        } label: {
                            card(icon: "doc.text",
                                 title: "독해",
                                 subtitle: "短文 · 中文 · 情報検索",
                                 detail: "지문 \(readingPassages.count)개 · \(practice.readingTotal)문항",
                                 progress: ratio(practice.readingSolved, practice.readingTotal))
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            ListeningView(store: practice)
                        } label: {
                            card(icon: "headphones",
                                 title: "청해",
                                 subtitle: "課題理解 · ポイント理解 · 概要理解 · 発話表現 · 即時応答",
                                 detail: "\(practice.listeningTotal)문항 · 음성 재생",
                                 progress: ratio(practice.listeningSolved, practice.listeningTotal))
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            StudyLogView()
                        } label: {
                            card(icon: "checklist",
                                 title: "학습 현황",
                                 subtitle: "알게 된 것 · 습득 못한 것 · 앞으로 알아야 할 것",
                                 detail: studyLogDetail,
                                 progress: nil)
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            VocabNotebookView(store: notes)
                        } label: {
                            card(icon: "highlighter",
                                 title: "내 단어장",
                                 subtitle: "독해에서 형광펜으로 짚어 담은 단어",
                                 detail: notes.notes.isEmpty
                                     ? "아직 담은 단어가 없습니다"
                                     : "\(notes.notes.count)개 담음",
                                 progress: nil)
                        }
                        .buttonStyle(.plain)

                        note
                    }
                    .padding(16)
                }
            }
            .navigationTitle("연습")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func ratio(_ done: Int, _ total: Int) -> Double? {
        guard total > 0 else { return nil }
        return Double(done) / Double(total)
    }

    private var header: some View {
        HStack(spacing: 12) {
            ForEach(ExamSubject.allCases) { subject in
                VStack(spacing: 4) {
                    Text(subject.name)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color(accentHex: subject.colorHex))
                    Text(status(for: subject))
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(accentHex: subject.colorHex).opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func status(for subject: ExamSubject) -> String {
        switch subject {
        case .language:  return "쓰기·읽기"
        case .reading:   return "\(practice.readingSolved)/\(practice.readingTotal)"
        case .listening: return "\(practice.listeningSolved)/\(practice.listeningTotal)"
        }
    }

    private func card(icon: String, title: String, subtitle: String,
                      detail: String, progress: Double?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.onBrand)
                    .frame(width: 40, height: 40)
                    .background(Theme.brand)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(Theme.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.textQuaternary)
            }

            if let progress {
                ProgressView(value: progress).tint(Theme.brand)
            }

            Text(detail)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.textQuaternary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var note: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("지문·대본·문항은 모두 자체 제작입니다. 실제 기출문제는 저작권 때문에 실을 수 없습니다.")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textQuaternary)
                .frame(maxWidth: .infinity, alignment: .leading)
            // 어휘(JMdict)·획순(KanjiVG) 데이터가 CC BY-SA라 출처를 밝혀야 한다
            NavigationLink {
                LicenseView()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 10))
                    Text("라이선스 · 출처")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(Theme.brand)
            }
        }
        .padding(.top, 4)
    }
}
