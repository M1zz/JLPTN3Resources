import SwiftUI

struct ContentView: View {
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

            KanjiWritingView()
                .tabItem {
                    Label("쓰기", systemImage: "pencil.and.scribble")
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
    }
}

#Preview {
    ContentView()
}
