import SwiftUI

// MARK: - 독해·청해 진도
//
// 학습 탭의 SRS(LearningStore)와 달리, 독해·청해는 «푼 문항»과 «맞힌 문항»만 남긴다.
// 목표 탭에서 «독해·청해는 앱이 추적하지 않는다»고 적어 두었던 빈칸을 이 값이 채운다.

final class PracticeStore: ObservableObject {

    /// 문항 id → 맞았는지
    @Published private(set) var reading: [String: Bool] = [:]
    @Published private(set) var listening: [String: Bool] = [:]
    /// 모의고사는 언어지식을 재는 유일한 자료다 — 합격 확률 계산에 쓰려면 남겨야 한다
    @Published private(set) var mock: [String: Bool] = [:]

    private let readingKey = "n3_reading_results_v1"
    private let listeningKey = "n3_listening_results_v1"
    private let mockKey = "n3_mock_results_v1"

    init() { load() }

    // MARK: 기록

    func record(readingQuestion id: String, correct: Bool) {
        reading[id] = correct
        save()
    }

    func record(listeningItem id: String, correct: Bool) {
        listening[id] = correct
        save()
    }

    /// 모의고사 한 회분을 통째로 기록한다 (같은 문항을 다시 풀면 최신 결과로 덮는다)
    func record(mockAnswers answers: [String: Int], questions: [MockQuestion]) {
        for q in questions where answers[q.id] != nil {
            mock[q.id] = answers[q.id] == q.answerIndex
        }
        save()
    }

    func result(readingQuestion id: String) -> Bool? { reading[id] }
    func result(listeningItem id: String) -> Bool? { listening[id] }

    func resetReading()   { reading = [:];   save() }
    func resetListening() { listening = [:]; save() }

    // MARK: 집계

    var readingSolved: Int { reading.count }
    var readingCorrect: Int { reading.values.filter { $0 }.count }
    var listeningSolved: Int { listening.count }
    var listeningCorrect: Int { listening.values.filter { $0 }.count }

    var readingTotal: Int { readingPassages.reduce(0) { $0 + $1.questions.count } }
    var listeningTotal: Int { listeningItems.count }

    /// 정답률 (푼 문항 기준). 아직 푼 게 없으면 nil
    var readingAccuracy: Double? {
        guard readingSolved > 0 else { return nil }
        return Double(readingCorrect) / Double(readingSolved)
    }

    var listeningAccuracy: Double? {
        guard listeningSolved > 0 else { return nil }
        return Double(listeningCorrect) / Double(listeningSolved)
    }

    /// 과목별로 「푼 문항 / 맞힌 문항」을 모은다 — 합격 확률 계산의 입력.
    /// 독해·청해는 연습 기록과 모의고사 기록을 합치고, 언어지식은 모의고사만 있다.
    func record(for subject: ExamSubject) -> (solved: Int, correct: Int) {
        var solved = 0, correct = 0
        switch subject {
        case .language:  break
        case .reading:   solved = readingSolved;   correct = readingCorrect
        case .listening: solved = listeningSolved; correct = listeningCorrect
        }
        for q in mockExamQuestions where q.subject == subject {
            guard let ok = mock[q.id] else { continue }
            solved += 1
            if ok { correct += 1 }
        }
        return (solved, correct)
    }

    /// 한 지문을 다 풀었는지
    func isFinished(_ passage: ReadingPassage) -> Bool {
        !passage.questions.isEmpty && passage.questions.allSatisfy { reading[$0.id] != nil }
    }

    func correctCount(_ passage: ReadingPassage) -> Int {
        passage.questions.filter { reading[$0.id] == true }.count
    }

    func solvedCount(_ kind: ListeningKind) -> Int {
        listeningItems.filter { $0.kind == kind && listening[$0.id] != nil }.count
    }

    func correctCount(_ kind: ListeningKind) -> Int {
        listeningItems.filter { $0.kind == kind && listening[$0.id] == true }.count
    }

    // MARK: 저장

    private func save() {
        let d = UserDefaults.standard
        d.set(try? JSONEncoder().encode(reading), forKey: readingKey)
        d.set(try? JSONEncoder().encode(listening), forKey: listeningKey)
        d.set(try? JSONEncoder().encode(mock), forKey: mockKey)
    }

    private func load() {
        let d = UserDefaults.standard
        if let data = d.data(forKey: readingKey),
           let decoded = try? JSONDecoder().decode([String: Bool].self, from: data) {
            reading = decoded
        }
        if let data = d.data(forKey: listeningKey),
           let decoded = try? JSONDecoder().decode([String: Bool].self, from: data) {
            listening = decoded
        }
        if let data = d.data(forKey: mockKey),
           let decoded = try? JSONDecoder().decode([String: Bool].self, from: data) {
            mock = decoded
        }
    }
}
