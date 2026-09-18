import SwiftUI

struct TutorialView: View {
    let type: TutorialType

    @Environment(Router.self) private var router
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            background

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    HStack {
                        Button(action: dismiss.callAsFunction) {
                            Image(systemName: "chevron.left")
                                .font(.headline.weight(.semibold))
                                .frame(width: 44, height: 44)
                                .glassEffect(.clear, in: .circle)
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Text("QUICK GUIDE")
                            .font(.caption.weight(.bold))
                            .tracking(1.3)
                            .foregroundStyle(.white.opacity(0.72))
                    }

                    Spacer(minLength: 12)

                    Image(systemName: content.iconName)
                        .font(.system(size: 48, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.white)
                        .frame(width: 112, height: 112)
                        .glassEffect(.clear.tint(content.tint.opacity(0.48)), in: .circle)
                        .frame(maxWidth: .infinity)

                    VStack(alignment: .leading, spacing: 10) {
                        Text(content.title)
                            .font(.largeTitle.bold())
                        Text(content.description)
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.74))
                    }
                    .foregroundStyle(.white)

                    VStack(spacing: 12) {
                        ForEach(Array(content.steps.enumerated()), id: \.offset) { index, step in
                            stepView(number: index + 1, text: step)
                        }
                    }

                    Button(action: begin) {
                        HStack(spacing: 10) {
                            Text(content.buttonTitle)
                                .font(.headline.weight(.semibold))
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.headline.weight(.bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity, minHeight: 58)
                        .glassEffect(
                            .clear.tint(content.tint.opacity(0.42)).interactive(),
                            in: .capsule
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                }
                .padding(24)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationBarBackButtonHidden()
    }

    private func stepView(number: Int, text: String) -> some View {
        HStack(spacing: 16) {
            Text("\(number)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .glassEffect(.clear, in: .circle)

            Text(text)
                .font(.body.weight(.medium))
                .foregroundStyle(.white.opacity(0.9))

            Spacer(minLength: 0)
        }
        .padding(16)
        .glassEffect(.clear, in: .rect(cornerRadius: 20))
    }

    private func begin() {
        router.completeTutorial(type)
    }

    private var content: Content {
        switch type {
        case .interviewTutorial:
            Content(
                title: "Interview practice",
                description: "Practice answering prompts with calm, clear eye contact.",
                iconName: "person.2.fill",
                tint: .green,
                steps: [
                    "Look toward the camera as you answer naturally.",
                    "Review your feedback and try again whenever you like."
                ],
                buttonTitle: "Start interview practice"
            )
        case .readingTutorial:
            Content(
                title: "Reading practice",
                description: "Read aloud at a comfortable pace while staying engaged.",
                iconName: "book.closed.fill",
                tint: .yellow,
                steps: [
                    "Read aloud in your natural voice."
                ],
                buttonTitle: "Start reading practice"
            )
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [Color(hex: "#101B3A"), Color(hex: "#322B69"), Color(hex: "#135B75")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(content.tint.opacity(0.2))
                .frame(width: 260)
                .blur(radius: 70)
                .offset(x: 90, y: -100)
        }
        .ignoresSafeArea()
    }
}

private extension TutorialView {
    struct Content {
        let title: String
        let description: String
        let iconName: String
        let tint: Color
        let steps: [String]
        let buttonTitle: String
    }
}

#Preview("Interview") {
    TutorialView(type: .interviewTutorial)
        .withRouter()
}

#Preview("Reading") {
    TutorialView(type: .readingTutorial)
        .withRouter()
}
