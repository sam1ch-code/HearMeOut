//
//  SwiftUIView.swift
//  HearMeOut
//
//  Created by Sukhrob on 13/09/26.
//

import SwiftUI

struct TranscriberView: View {
    @State private var recorder = SpeechRecognizer()
    @State private var isRecording: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            ScrollView {
                Text(recorder.transcript)
                    .font(.title3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(.red)
            }
            Button {
                Task {
                    if isRecording {
                        await recorder.stopTranscribing()
                        isRecording = false
                    } else {
                        await recorder.startTranscribing()
                        isRecording = true
                    }
                }
            } label: {
                Label(
                    isRecording ? "Stop & Transcribe" : "Start Recording",
                    systemImage: isRecording ? "stop.circle.fill" : "record.circle"
                )
                .font(.title2)
            }
            .tint(isRecording ? .red : .accentColor)
        }
        .padding()
    }
}

//struct TranscriberView: View {
//    @State var speechRecognizer = SpeechRecognizer()
//    @State private var isRecording = false
//
//    var body: some View {
//        VStack {
//            Text(speechRecognizer.transcript)
//                .font(.title)
//                .foregroundStyle(.red)
//            Button {
//                speechRecognizer.startTranscribing()
//            } label: {
//                Text("Start Recording")
//                    .font(.title)
//            }
//            Button {
//                speechRecognizer.stopTranscribing()
//            } label: {
//                Text("Stop Recording")
//                    .font(.title)
//            }
//        }
//        .padding()
//        .navigationBarTitleDisplayMode(.inline)
//    }
//}
