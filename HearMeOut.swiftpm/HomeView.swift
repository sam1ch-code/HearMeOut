//
//  SwiftUIView.swift
//  HearMeOut
//
//  Created by Sukhrob on 10/09/26.
//

import SwiftUI

struct HomeView<ViewModel: HomeViewModelProtocol>: View {
    @StateObject var viewModel: ViewModel
    @Environment(Router.self) var router

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                header

                Spacer(minLength: 48)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Choose your practice")
                        .font(.title.bold())
                    Text("Build confidence, one conversation at a time.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.72))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(.white)

                Spacer(minLength: 32)

                VStack(spacing: 16) {
                    ForEach(viewModel.state.buttons) { button in
                        buttonView(model: button)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
    }
}

private extension HomeView {
    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("HEAR ME OUT")
                    .font(.caption.weight(.bold))
                    .tracking(1.4)
                Text("Practice studio")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.68))
            }
            .foregroundStyle(.white)

            Spacer()

            ZStack {
                Circle()
                    .fill(.clear)
                    .glassEffect(.clear, in: .circle)

                Image("MainIcon")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
            }
            .frame(width: 54, height: 54)
        }
    }

    private func buttonView(model: ButtonModel) -> some View {
        ButtonView(model: model) {
            
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
                .fill(.cyan.opacity(0.28))
                .frame(width: 280)
                .blur(radius: 70)
                .offset(x: 90, y: -120)
        }
        .overlay(alignment: .bottomLeading) {
            Circle()
                .fill(.purple.opacity(0.35))
                .frame(width: 300)
                .blur(radius: 80)
                .offset(x: -110, y: 120)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    HomeView<HomeViewModel>(viewModel: HomeViewModel(state: HomeState()))
}
