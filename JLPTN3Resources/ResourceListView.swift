import SwiftUI

struct ResourceListView: View {
    @State private var selectedCategory: ResourceCategory? = nil
    @State private var searchText = ""
    @State private var freeOnly = false

    var filteredResources: [Resource] {
        Resource.all.filter { resource in
            let matchCat = selectedCategory == nil || resource.category == selectedCategory
            let matchSearch = searchText.isEmpty ||
                resource.title.localizedCaseInsensitiveContains(searchText) ||
                resource.description.contains(searchText)
            let matchFree = !freeOnly || resource.type == .free
            return matchCat && matchSearch && matchFree
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header banner
                    headerBanner

                    // Category pills
                    categoryScroll

                    // Free toggle + count
                    filterBar

                    // Cards
                    LazyVStack(spacing: 12) {
                        ForEach(filteredResources) { resource in
                            NavigationLink(destination: ResourceDetailView(resource: resource)) {
                                ResourceCardView(resource: resource)
                            }
                            .buttonStyle(.plain)
                        }

                        if filteredResources.isEmpty {
                            emptyState
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            .background(Theme.background)
            .navigationBarHidden(true)
            .searchable(text: $searchText, prompt: "자료 검색...")
        }
    }

    // MARK: - Header

    private var headerBanner: some View {
        ZStack(alignment: .bottomLeading) {
            Theme.heroBanner

            // Background N3 text
            Text("N3")
                .font(.system(size: 140, weight: .black))
                .foregroundStyle(Color.white.opacity(0.06))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 20)
                .padding(.bottom, -10)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("JLPT")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(4)
                        .foregroundStyle(Color(hex: "E0B98C"))
                    Rectangle()
                        .frame(width: 30, height: 1)
                        .foregroundStyle(Color(hex: "E0B98C"))
                    Text("2026 下半期")
                        .font(.system(size: 12, weight: .medium))
                        .tracking(2)
                        .foregroundStyle(Color(hex: "E0B98C"))
                }

                Text("N3 합격\n학습자료 가이드")
                    .font(.system(size: 30, weight: .black))
                    .foregroundStyle(Theme.onHeroBanner)
                    .lineSpacing(2)

                Text("無料・有料 자료 \(Resource.all.count)개 큐레이션")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.6))
            }
            .padding(20)
        }
        .frame(height: 160)
    }

    // MARK: - Category Scroll

    private var categoryScroll: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All button
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedCategory = nil
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("전체")
                            .font(.system(size: 13, weight: .bold))
                        Text("All")
                            .font(.system(size: 10))
                            .opacity(0.7)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(selectedCategory == nil ? Theme.textPrimary : Color.clear)
                    .foregroundStyle(selectedCategory == nil ? Theme.background : Theme.textPrimary)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Theme.textPrimary, lineWidth: 1.5))
                }

                ForEach(ResourceCategory.allCases) { cat in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = selectedCategory == cat ? nil : cat
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(cat.rawValue)
                                .font(.system(size: 13, weight: .bold))
                            Text(cat.japaneseLabel)
                                .font(.system(size: 9))
                                .opacity(0.7)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(selectedCategory == cat ? cat.color : Color.clear)
                        .foregroundStyle(selectedCategory == cat ? Color.white : cat.color)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(cat.color, lineWidth: 1.5))
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 12)
        .background(Theme.background)
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        HStack {
            Text("\(filteredResources.count)개 자료")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)

            Spacer()

            Toggle(isOn: $freeOnly) {
                Text("무료만")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(freeOnly ? Color(accentHex: "16A34A") : Color.secondary)
            }
            .toggleStyle(.switch)
            .tint(Color(accentHex: "16A34A"))
            .labelsHidden()

            Text("무료만")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(freeOnly ? Color(accentHex: "16A34A") : Color.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("見つからない")
                .font(.system(size: 36))
            Text("검색 결과가 없습니다")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

#Preview {
    ResourceListView()
}
