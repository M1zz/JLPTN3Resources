import SwiftUI

struct ContentView: View {
    // 탭마다 따로 만들면 한 탭에서 푼 결과가 다른 탭에 비치지 않는다.
    // 합격 확률은 학습 진도와 풀이 기록을 함께 보므로 한 벌만 두고 나눠 쓴다.
    @StateObject private var learning = LearningStore()
    @StateObject private var practice = PracticeStore()
    @StateObject private var notes = VocabNoteStore()

    var body: some View {
        TabView {
            LearningHomeView()
                .tabItem {
                    Label("학습", systemImage: "brain.head.profile")
                }

            ResourceListView()
                .tabItem {
                    Label("자료", systemImage: "books.vertical")
                }

            // 쓰기·독해·청해를 한 탭에 모았다 — 탭 막대는 5개까지가 한계다
            PracticeHubView()
                .tabItem {
                    Label("연습", systemImage: "pencil.and.scribble")
                }

            MockExamView()
                .tabItem {
                    Label("모의고사", systemImage: "list.clipboard")
                }

            MilestoneView()
                .tabItem {
                    Label("목표", systemImage: "trophy")
                }
        }
        .tint(Theme.brand)
        .environmentObject(learning)
        .environmentObject(practice)
        .environmentObject(notes)
    }
}

#Preview {
    ContentView()
}
