//
//  SwiftUIView.swift
//  HearMeOut
//
//  Created by Sukhrob on 10/09/26.
//

import SwiftUI

struct ButtonView: View {
    let model: ButtonModel
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 18) {
                Image(systemName: model.iconSystemName)
                    .font(.system(size: 30, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white)
                    .frame(width: 68, height: 68)
                    .glassEffect(
                        .clear.tint(model.backgroundColor.opacity(0.6)),
                        in: .circle
                    )

                VStack(alignment: .leading, spacing: 5) {
                    Text(model.title)
                        .font(.title3.weight(.bold))
                    Text(model.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.72))
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white.opacity(0.82))
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(.white)
            .contentShape(.rect(cornerRadius: 28))
            .glassEffect(
                .clear.tint(model.backgroundColor.opacity(0.28)).interactive(),
                in: .rect(cornerRadius: 28)
            )
//            .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 28))
        }
        .buttonStyle(.plain)
    }
}

