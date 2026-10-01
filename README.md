# SpeechToTextFromWhisper

A SwiftUI iOS app that records speech from the microphone and transcribes it to Nepali text on-device, using OpenAI's Whisper models through [WhisperKit](https://github.com/argmaxinc/WhisperKit).

## How it works

1. Tap **Start Recording**. On first use the Whisper model is downloaded and loaded before recording begins, so nothing you say is lost to the download.
2. Speak in Nepali.
3. Tap **Stop & Transcribe**. The transcription appears on screen and can be selected and copied.

Transcription runs entirely on the device with Core ML. A network connection is only needed for the one-time model download.

## Requirements

- Xcode 15.2 or later (Swift 5.9)
- iOS 17.2 or later, iPhone or iPad
- A real device or an Apple silicon Mac. Core ML crashes when it runs the Whisper models in the x86_64 simulator, so the record button is disabled in the simulator on an Intel Mac.
- Roughly 480 MB of free storage for the default `small` model

## Setup

The app depends on a local Swift package, `voicetotextbywishper`, which is **not included in this repository**. The Xcode project references it at `../../framework/voicetotextbywishper`, relative to the project folder:

```
My_Project/
├── framework/
│   └── voicetotextbywishper/        <- the local package
└── new project/
    └── SpeechToTextFromWhisper/     <- this repository
```

Place the package at that path (or re-add it in Xcode under **Package Dependencies**), then:

1. Open `SpeechToTextFromWhisper.xcodeproj` in Xcode.
2. Wait for Swift Package Manager to resolve WhisperKit and its dependencies.
3. Select your development team under **Signing & Capabilities**.
4. Build and run on a device, and allow microphone access when prompted.

## Choosing a model

The app uses the package's default model, `small`. Nepali is a low-resource language for Whisper, so accuracy improves a lot with model size. To use a different one, pass a configuration in `ContentView.swift`:

```swift
@State private var speech = NepaliSpeechToText(
    configuration: .init(model: .largeV3Turbo)
)
```

| Model | Size | Notes |
| --- | --- | --- |
| `tiny` | ~75 MB | Fastest, poor Nepali accuracy |
| `base` | ~145 MB | Fast, weak Nepali accuracy |
| `small` | ~480 MB | Default. Reasonable balance on recent iPhones |
| `medium` | ~1.5 GB | Better accuracy, needs plenty of memory |
| `largeV3Turbo` | ~630 MB | Close to large-v3 accuracy and much faster |
| `largeV3Compressed` | ~950 MB | Best accuracy that still fits on most recent iPhones |
| `largeV3` | ~3 GB | Best accuracy |

Models are downloaded from the [`argmaxinc/whisperkit-coreml`](https://huggingface.co/argmaxinc/whisperkit-coreml) repository on Hugging Face.

## Project structure

```
SpeechToTextFromWhisper/
├── SpeechToTextFromWhisperApp.swift   App entry point
├── ContentView.swift                  Recording UI and transcription flow
└── Assets.xcassets                    App icon and accent colour
```

## Dependencies

- `voicetotextbywishper` (local package) provides `NepaliSpeechToText`
- [WhisperKit](https://github.com/argmaxinc/WhisperKit) 0.14.1, the newest release line that resolves with Swift 5.9 / Xcode 15.2
