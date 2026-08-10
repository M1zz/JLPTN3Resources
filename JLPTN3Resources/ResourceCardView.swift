import SwiftUI

struct ResourceCardView: View {
    let resource: Resource

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top accent line
            Rectangle()
                .fill(resource.category.color)
                .frame(height: 3)

            VStack(alignment: .leading, spacing: 10) {
                // Top row: emoji + badges
                HStack(alignment: .top) {
                    Text(resource.emoji)
                        .font(.system(size: 28))

                    Spacer()

                    HStack(spacing: 6) {
                        // Type badge
                        Text(resource.type.rawValue)
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(resource.typeColor.opacity(0.12))
                            .foregroundStyle(resource.typeColor)
                            .clipShape(Capsule())

                        // Tag badge
                        Text(resource.tag)
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Theme.surfaceSoft)
                            .foregroundStyle(Theme.textSecondary)
                            .clipShape(Capsule())
                    }
                }

                // Category label
                HStack(spacing: 4) {
                    Image(systemName: resource.category.icon)
                        .font(.system(size: 10, weight: .bold))
                    Text(resource.category.rawValue)
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.5)
                    Text("·")
                    Text(resource.category.japaneseLabel)
                        .font(.system(size: 10))
                }
                .foregroundStyle(resource.category.color)

                // Title
                Text(resource.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // Description
                Text(resource.description)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)

                // Bottom row
                HStack {
                    Label(resource.platform, systemImage: "globe")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textTertiary)

                    Spacer()

                    HStack(spacing: 3) {
                        Text("바로가기")
                            .font(.system(size: 12, weight: .bold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(resource.category.color)
                }
            }
            .padding(16)
        }
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Theme.shadow, radius: 8, x: 0, y: 2)
    }
}

#Preview {
    ResourceCardView(resource: Resource.all[0])
        .padding()
        .background(Theme.background)
}
