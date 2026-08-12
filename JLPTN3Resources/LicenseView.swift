import SwiftUI

// MARK: - 라이선스 · 출처
//
// 어휘 데이터(JMdict)와 획순 데이터(KanjiVG)는 둘 다 CC BY-SA 3.0이라
// 화면에 출처를 밝혀야 한다.
//
// EDRDG 라이선스는 낱말을 화면에 표시할 때 출처 표시를 요구하지만,
// 「여러 출처가 섞인 경우 포괄적인 표시로 충분하다」고 정하고 있다.
// 이 앱의 카드는 JMdict 자료와 자체 제작 자료가 섞여 있으므로 이 화면으로 갈음한다.

struct LicenseView: View {
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    intro

                    source(title: "어휘 데이터",
                           name: "JMdict / EDRDG",
                           license: "CC BY-SA 3.0",
                           url: "https://www.edrdg.org/edrdg/licence.html",
                           body: "어휘 카드 2,224항목의 표기·읽기는 JMdict에서 왔습니다. "
                               + "Jim Breen이 시작하고 Electronic Dictionary Research and Development Group이 "
                               + "관리하는 사전 파일이며, jisho.org를 통해 받았습니다.\n"
                               + "한국어 뜻은 이 앱에서 새로 작성했지만 원자료의 2차적 저작물이므로 "
                               + "같은 조건(CC BY-SA 3.0)으로 배포됩니다. "
                               + "이 앱은 해당 자료에 대해 저작권을 주장하지 않습니다.")

                    source(title: "획순 데이터",
                           name: "KanjiVG",
                           license: "CC BY-SA 3.0",
                           url: "https://kanjivg.tagaini.net",
                           body: "한자 1,330자의 획 순서와 모양은 KanjiVG에서 왔습니다. "
                               + "앱에 싣기 위해 필요한 글자만 추려 JSON으로 바꾼 파생물이며, "
                               + "원본과 같은 조건으로 배포됩니다.")

                    ownWork
                    trademark
                }
                .padding(16)
            }
        }
        .navigationTitle("라이선스 · 출처")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var intro: some View {
        Text("이 앱은 여러 출처의 자료를 씁니다. 아래에 출처와 조건을 밝힙니다.")
            .font(.system(size: 13))
            .foregroundStyle(Theme.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func source(title: String, name: String, license: String,
                        url: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Theme.textTertiary)

            HStack(spacing: 8) {
                Text(name)
                    .font(.system(size: 17, weight: .black))
                    .foregroundStyle(Theme.textPrimary)
                Text(license)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Theme.brand)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Theme.brand.opacity(0.12))
                    .clipShape(Capsule())
            }

            Text(body)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            if let link = URL(string: url) {
                Link(destination: link) {
                    HStack(spacing: 4) {
                        Text(url)
                            .font(.system(size: 11))
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(Theme.brand)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var ownWork: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("자체 제작")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Theme.textTertiary)
            Text("독해 지문 28개·문항 50개, 청해 문항 72개, 모의고사 문항 18개, "
                 + "예문, 기초 낱말 사전은 이 앱에서 직접 만들었습니다.\n"
                 + "실제 JLPT 기출문제는 저작권 때문에 싣지 않았고, 출제 «형식»만 참고했습니다.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.surfaceSoft)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var trademark: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("상표")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Theme.textTertiary)
            Text("「JLPT」와 「日本語能力試験」은 국제교류기금 및 일본국제교육지원협회(JEES)의 상표입니다. "
                 + "이 앱은 비공식 학습 도구이며 위 기관과 아무런 관련이 없습니다.")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textTertiary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.surfaceSoft)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
