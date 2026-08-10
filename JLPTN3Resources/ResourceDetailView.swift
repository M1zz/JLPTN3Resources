import SwiftUI

struct ResourceDetailView: View {
    let resource: Resource
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Hero section
                heroSection

                VStack(alignment: .leading, spacing: 24) {
                    // Description card
                    descriptionCard

                    // Meta info
                    metaGrid

                    // Open button
                    openButton
                }
                .padding(20)
            }
        }
        .background(Theme.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    if let url = resource.url {
                        openURL(url)
                    }
                } label: {
                    Image(systemName: "safari")
                        .foregroundStyle(Theme.brand)
                }
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            resource.category.color
                .opacity(0.12)

            // Background emoji
            Text(resource.emoji)
                .font(.system(size: 100))
                .opacity(0.12)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 20)

            VStack(alignment: .leading, spacing: 8) {
                Text(resource.emoji)
                    .font(.system(size: 48))

                // Category
                HStack(spacing: 4) {
                    Image(systemName: resource.category.icon)
                        .font(.system(size: 11, weight: .bold))
                    Text(resource.category.rawValue)
                        .font(.system(size: 12, weight: .bold))
                        .tracking(0.5)
                    Text("·")
                    Text(resource.category.japaneseLabel)
                        .font(.system(size: 11))
                }
                .foregroundStyle(resource.category.color)

                Text(resource.title)
                    .font(.system(size: 26, weight: .black))
                    .foregroundStyle(Theme.textPrimary)

                // Badges
                HStack(spacing: 8) {
                    badgeView(text: resource.type.rawValue, color: resource.typeColor)
                    badgeView(text: resource.tag, color: Theme.textSecondary)
                    badgeView(text: resource.platform, color: Theme.textSecondary)
                }
            }
            .padding(20)
        }
    }

    // MARK: - Description Card

    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("소개", systemImage: "text.alignleft")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.secondary)

            Text(resource.description)
                .font(.system(size: 15))
                .foregroundStyle(Theme.textPrimary)
                .lineSpacing(5)
        }
        .padding(16)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Theme.shadow, radius: 6, x: 0, y: 2)
    }

    // MARK: - Meta Grid

    private var metaGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            metaCell(icon: "tag", label: "분류", value: resource.category.rawValue, color: resource.category.color)
            metaCell(icon: "yensign.circle", label: "비용", value: resource.type.rawValue, color: resource.typeColor)
            metaCell(icon: "globe", label: "플랫폼", value: resource.platform, color: Color(accentHex: "0891B2"))
            metaCell(icon: "bookmark", label: "태그", value: resource.tag, color: Color(accentHex: "7C3AED"))
        }
    }

    private func metaCell(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: Theme.shadow, radius: 4, x: 0, y: 1)
    }

    // MARK: - Open Button

    private var openButton: some View {
        Button {
            if let url = resource.url {
                openURL(url)
            }
        } label: {
            HStack {
                Spacer()
                Image(systemName: "arrow.up.right.square.fill")
                    .font(.system(size: 16))
                Text("사이트 바로가기")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
            }
            .padding(.vertical, 16)
            .background(resource.category.color)
            .foregroundStyle(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: resource.category.color.opacity(0.4), radius: 12, x: 0, y: 6)
        }
    }

    private func badgeView(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

#Preview {
    NavigationStack {
        ResourceDetailView(resource: Resource.all[0])
    }
}
