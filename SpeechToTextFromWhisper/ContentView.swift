//
//  ContentView.swift
//  SpeechToTextFromWhisper
//
//  Created by Hira Shrestha on 01/10/2026.
//

import SwiftUI
import voicetotextbywishper

struct ContentView: View {
    private enum Phase {
        case idle
        case loadingModel
        case recording
        case transcribing
    }

    // Core ML crashes (SIGFPE in the mel spectrogram's padding layer) when it runs the Whisper
    // models in the x86_64 simulator, so transcription only works on a device or an Apple silicon Mac.
    #if targetEnvironment(simulator) && arch(x86_64)
    private static let isTranscriptionSupported = false
    #else
    private static let isTranscriptionSupported = true
    #endif

    @State private var speech = NepaliSpeechToText()
    @State private var phase = Phase.idle
    @State private var downloadProgress = 0.0
    @State private var transcript = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            ScrollView {
                Text(transcript.isEmpty ? "Transcription will appear here" : transcript)
                    .font(.title3)
                    .foregroundStyle(transcript.isEmpty ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            status

            Button {
                Task { await buttonTapped() }
            } label: {
                Label(
                    phase == .recording ? "Stop & Transcribe" : "Start Recording",
                    systemImage: phase == .recording ? "stop.circle.fill" : "mic.circle.fill"
                )
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(phase == .recording ? .red : .accentColor)
            .disabled(!Self.isTranscriptionSupported || phase == .loadingModel || phase == .transcribing)
        }
        .padding()
    }

    @ViewBuilder
    private var status: some View {
        switch phase {
            case .idle:
                if Self.isTranscriptionSupported {
                    Text("Tap the button and speak in Nepali")
                        .foregroundStyle(.secondary)
                } else {
                    Text("Whisper is not supported in the simulator on an Intel Mac. Run the app on a real iPhone.")
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                }
            case .loadingModel:
                // The download reports progress; compiling and loading the model afterwards does not.
                if downloadProgress > 0, downloadProgress < 1 {
                    ProgressView(value: downloadProgress) {
                        Text("Downloading model \(Int(downloadProgress * 100))%")
                    }
                } else {
                    ProgressView("Loading model…")
                }
            case .recording:
                Label("Recording…", systemImage: "waveform")
                    .foregroundStyle(.red)
            case .transcribing:
                ProgressView("Transcribing…")
        }
    }

    @MainActor
    private func buttonTapped() async {
        errorMessage = nil
        do {
            switch phase {
                case .idle:
                    try await startRecording()
                case .recording:
                    try await stopAndTranscribe()
                case .loadingModel, .transcribing:
                    break
            }
        } catch {
            await speech.cancelRecording()
            errorMessage = error.localizedDescription
            phase = .idle
        }
    }

    @MainActor
    private func startRecording() async throws {
        // Load the model before recording so nothing the user says is lost to the first-time download.
        if await !speech.isReady {
            phase = .loadingModel
            downloadProgress = 0
            try await speech.prepare { fraction in
                Task { @MainActor in
                    downloadProgress = fraction
                }
            }
        }
        try await speech.startRecording()
        phase = .recording
    }

    @MainActor
    private func stopAndTranscribe() async throws {
        phase = .transcribing
        let result = try await speech.stopRecordingAndTranscribe()
        if result.isEmpty {
            errorMessage = "No speech was recognised."
        } else {
            transcript = result.text
        }
        phase = .idle
    }
}

#Preview {
    ContentView()
}
