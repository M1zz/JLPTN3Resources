import SwiftUI

// MARK: - 내 단어장
//
// 독해 지문에서 형광펜으로 짚어 담은 단어들. 지문별로 묶어 보여준다.

struct VocabNotebookView: View {
    @ObservedObject var store: VocabNoteStore
    @State private var editing: VocabNote?

    private var grouped: [(title: String, notes: [VocabNote])] {
        let byID = Dictionary(grouping: store.notes, by: { $0.sourceID })
        return byID
            .map { (key, value) in
                (title: value.first?.sourceTitle ?? key,
                 notes: value.sorted { $0.addedAt < $1.addedAt })
            }
            .sorted { ($0.notes.first?.addedAt ?? .distantPast) > ($1.notes.first?.addedAt ?? .distantPast) }
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if store.notes.isEmpty {
                emptyView
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        summary
                        ForEach(grouped, id: \.title) { group in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(group.title)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Theme.textTertiary)
                                ForEach(group.notes) { note in
                                    row(note)
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .navigationTitle("내 단어장")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !store.notes.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("전체 비우기", role: .destructive) { store.removeAll() }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(item: $editing) { note in
            VocabNoteEditor(note: note, store: store)
                .presentationDetents([.height(280)])
        }
    }

    private var summary: some View {
        HStack(spacing: 10) {
            Text("\(store.notes.count)")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(Theme.brand)
            Text("단어")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
            Spacer()
            let missing = store.notes.filter { !$0.hasMeaning }.count
            if missing > 0 {
                Text("뜻 미등록 \(missing)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color(accentHex: "D97706"))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surfaceSoft)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func row(_ note: VocabNote) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(note.word)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    // 활용형으로 담았으면 사전에 실린 기본형을 나란히 («走っています → 走る»)
                    if note.inflected, let base = note.base {
                        Text("→ \(base)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.brand)
                    }
                    if !note.reading.isEmpty {
                        Text(note.reading)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textQuaternary)
                    }
                }
                Text(note.hasMeaning ? note.meaning : "뜻 미등록 — 눌러서 적어 두기")
                    .font(.system(size: 12))
                    .foregroundStyle(note.hasMeaning ? Theme.textSecondary : Theme.textQuaternary)
            }
            Spacer(minLength: 4)
            Button {
                store.remove(note)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textQuaternary)
                    .padding(8)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Theme.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
        .onTapGesture { editing = note }
    }

    private var emptyView: some View {
        VStack(spacing: 10) {
            Image(systemName: "highlighter")
                .font(.system(size: 34))
                .foregroundStyle(Theme.highlight)
            Text("아직 담은 단어가 없습니다")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("독해 지문에서 모르는 단어를 누르면\n형광펜이 그어지면서 여기에 담깁니다")
                .font(.system(size: 12))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(30)
    }
}

// MARK: - 뜻 직접 적기

struct VocabNoteEditor: View {
    let note: VocabNote
    @ObservedObject var store: VocabNoteStore
    @Environment(\.dismiss) private var dismiss

    @State private var reading = ""
    @State private var meaning = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 14) {
                    Text(note.word)
                        .font(.system(size: 28, weight: .black))
                        .foregroundStyle(Theme.textPrimary)

                    TextField("읽기 (ひらがな)", text: $reading)
                        .textFieldStyle(.roundedBorder)
                    TextField("뜻", text: $meaning)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        store.update(note, reading: reading, meaning: meaning)
                        dismiss()
                    } label: {
                        Text("저장")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Theme.onBrand)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.brand)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    Spacer(minLength: 0)
                }
                .padding(20)
            }
            .navigationTitle("단어 메모")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            reading = note.reading
            meaning = note.meaning
        }
    }
}
