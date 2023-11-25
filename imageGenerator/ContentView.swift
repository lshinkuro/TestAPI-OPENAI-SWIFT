//
//  ContentView.swift
//  imageGenerator
//
//  Created by Phincon on 25/11/23.
//

import SwiftUI
import AVFoundation
import OpenAIKit

enum TranscriptionType: String, CaseIterable, Identifiable  {
    case english
    case dutch
    
    var id: Self { self }
    
}

enum VoiceType: String, CaseIterable, Identifiable  {
    case alloy, echo, fable, onyx, nova, shimmer
    
    var id: Self { self }
    
}

// MARK: - Welcome
struct SpeechToTextModel: Codable {
    let text: String
}

struct ContentView: View {
    
    
    @State private var isCompleting: Bool = false
    @State private var transcription: String = ""
    @State private var selectedLanguage: TranscriptionType = .english
    @State private var voiceType: VoiceType = .alloy

    
    @State private var isPlay: Bool = false

    
    var audioData: Data? {
        switch selectedLanguage {
        case .english:
            return self.retrieveAudio(type: .english)
        case .dutch:
            return self.retrieveAudio(type: .dutch)
        }
    }
    
    
    // English Audio Source: https://librivox.org/12-creepy-tales-by-edgar-allan-poe/
    // 12 - THE PIT AND THE PENDULUM -- Narrator: Eden Rea-Hedrick
    // ---------------------------------------------------------------------------------------
    // Dutch Audio Source: https://librivox.org/the-raven-multilingual-by-edgar-allan-poe/
    // 04 - Dutch: De Raaf (John F. Malta) -- Narrator: Julie VW
    private func retrieveAudio(type: TranscriptionType) -> Data? {
        guard
            let filePath = Bundle.main.path(
                forResource: type == .english ? "audio" : "audio_translation",
                ofType: "mp3"
            ),
            let audio = try? Data(contentsOf: URL(fileURLWithPath: filePath))
        else {
            return nil
        }
        
        return audio
    }
    
    @StateObject private var viewModel = ViewModel()
    @State var prompt: String = ""
    @State var generatedImage: UIImage?
    @State var isLoading: Bool = false
    
    @State var generatedText: String?
    
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color("backgroundColor"))
            } else {
                VStack {
                    Text("DALL-E IMAGE GENERATOR")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.title2)
                        .bold()
                        .offset(y: 10)
                    
                    Picker("Transcription Type", selection: $selectedLanguage) {
                        Text("Regular Transcription").tag(TranscriptionType.english)
                        Text("Translation Transcription").tag(TranscriptionType.dutch)
                    }
                    .padding(.bottom, 20)
                    
                    
                    Picker("Voice Type", selection: $voiceType) {
                        Text("Alloy").tag(VoiceType.alloy)
                        Text("echo").tag(VoiceType.echo)
                        Text("fable").tag(VoiceType.fable)
                        Text("onyx").tag(VoiceType.onyx)
                        Text("nova").tag(VoiceType.nova)
                        Text("shimer").tag(VoiceType.shimmer)
                    }
                    .padding(.bottom, 20)
                    
                    Button {
                        isPlay.toggle()
                        self.viewModel.play(audioData: self.audioData, isPlay: isPlay)
                    } label: {
                        Text("Play Audio")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 270, height: 50)
                            .background(.blue)
                            .clipShape(Capsule())
                            .padding(.top, 8)
                    }.padding()
                    
                    Button {
                        isPlay.toggle()
                        self.viewModel.generateSpeech(from: prompt, voiceType: voiceType.rawValue ) { result in
                            switch result {
                            case .success(let data):
                                // Handle the response data as needed
                                
                                print("Response: \(data)")
                                self.viewModel.play(audioData: data, isPlay: true)
                            case .failure(let error):
                                // Handle the error
                                print("Error: \(error)")
                            }
                            
                        }
                    } label: {
                        Text("TTS")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 270, height: 50)
                            .background(.blue)
                            .clipShape(Capsule())
                            .padding(.top, 8)
                    }
                    Spacer()
                    
                    VStack {
                        Text(transcription)
                    }
                    .padding()
                    
                    VStack {
                        Button {
                            isCompleting = true
                            
                            Task {
                                isLoading = true
                               viewModel.translateAudioFile(audioData: self.audioData, expecting: SpeechToTextModel.self) { result in
                                   switch result {
                                   case .success(let data):
                                       // Handle the response data as needed
                                       
                                       print("Response: \(data)")
                                       transcription = data.text
                                   case .failure(let error):
                                       // Handle the error
                                       print("Error: \(error)")
                                   }
                               }
                                isLoading = false
                            }
                        } label: {
                            Text("Generate Transcription")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(width: 270, height: 50)
                                .background(.blue)
                                .clipShape(Capsule())
                                .padding(.top, 8)
                        }
                    }
                    
                    TextField("", text: $prompt)
                        .padding()
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                        .background(Color("textFieldColor"))
                        .cornerRadius(5)
                        .padding(.horizontal)
                
                
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color("backgroundColor"))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

func createViewForChat() {
    
    VStack {
//        if let generatedText = generatedText {
//            VStack {
//                Text(generatedText)
//                    .foregroundColor(.white.opacity(0.5))
//                    .font(.callout)
//                    .bold()
//                    .padding(10)
//                    .offset(y: 10)
//            }.edgesIgnoringSafeArea(.all)
//        } else {
//            Image("placeholderImage")
//                .resizable()
//                .frame(width: 250, height: 250)
//                .opacity(0.5)
//        }
//        if let generatedImage = generatedImage {
//
//            GeometryReader { geometry in
//                VStack(alignment: .center) {
//                    Text("RESULT")
//                        .foregroundColor(.white.opacity(0.5))
//                        .font(.callout)
//                        .bold()
//                        .offset(y: 10)
//                    Image(uiImage: generatedImage)
//                        .resizable()
//                        .aspectRatio(contentMode: .fit)
//
//                        .frame(width: geometry.size.width , height: geometry.size.height * 0.8 )
//
//                }.edgesIgnoringSafeArea(.all).alignmentGuide(HorizontalAlignment.center) { dimension in
//                    dimension[.trailing] / 2
//                }
//                .alignmentGuide(VerticalAlignment.center) { dimension in
//                    dimension[.bottom] / 2
//                }
//            }
//
//        } else {
//            Image("placeholderImage")
//                .resizable()
//                .frame(width: 250, height: 250)
//                .opacity(0.5)
//        }
//        Spacer()
//        Text("ENTER YOUR PROMPT BELOW")
//            .foregroundColor(.white.opacity(0.6))
//            .font(.caption2.bold())
//        TextField("", text: $prompt)
//            .padding()
//            .font(.caption)
//            .foregroundColor(.white.opacity(0.5))
//            .background(Color("textFieldColor"))
//            .cornerRadius(5)
//            .padding(.horizontal)
//
//        Button("Generate") {
//            Task {
//                isLoading = true
//                //                            generatedImage = await viewModel.generateImage(from: prompt)
//                generatedText = await viewModel.generateChat(from: prompt)
//                isLoading = false
//            }
//        }
//        .foregroundColor(.white)
//        .buttonStyle(.borderedProminent)
//        .tint(.primary)
//        .onAppear {
//            viewModel.setup()
//        }
//        .padding()
    }
   
}
