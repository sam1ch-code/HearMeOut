import SwiftUI

struct ContentView: View {
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "#6F72FB"),
                    Color(hex: "#A95CFC"),
                    Color(hex: "#D056F5")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                HStack(spacing: 24) {
                    ForEach(modes) { model in
                        HStack(spacing: 24) {
                            ModeTile(mode: model)
                        }
                    }
                }
                .padding()
            }
        }
    }

    let modes = [
        Mode(
            title: "Interview Mode",
            subtitle: "Practice answers.\nBuild confidence.",
            icon: "mic",
            bgColor: .blue
        ),
        Mode(
            title: "Story Tell Mode",
            subtitle: "Share stories.\nInspire others.",
            icon: "bubble.left",
            bgColor: .red
        )
    ]
}

struct ModeTile: View {
    let mode: Mode

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: mode.icon)
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(.white)

            Text(mode.title)
                .font(.title3.bold())
                .foregroundStyle(.white)

            Text(mode.subtitle)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)

            Image(systemName: Icons.chevron)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 180)
        .padding(20)
        .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 45))
    }
}

private extension ContentView {
    private var gradient: some View {
        LinearGradient(
            colors: [
                Color(hex: "#6F72FB"),
                Color(hex: "#A95CFC"),
                Color(hex: "#D056F5")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

enum Icons: Equatable {
    static let chevron: String = "chevron.right"
    static let microphone: String = "chevron.right"
    static let musicNote: String = "chevron.right"
    static let MessageBubble: String = "chevron.right"
}



struct Mode: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let bgColor: Color
}
