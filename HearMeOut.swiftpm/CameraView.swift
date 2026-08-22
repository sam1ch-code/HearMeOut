//
//  SwiftUIView.swift
//  HearMeOut
//
//  Created by Sukhrob on 22/08/26.
//

import SwiftUI

struct CameraView: View {
    @StateObject private var model = FrameHandler()

    var body: some View {
        FrameView(image: model.frame)
            .ignoresSafeArea()
    }
}
