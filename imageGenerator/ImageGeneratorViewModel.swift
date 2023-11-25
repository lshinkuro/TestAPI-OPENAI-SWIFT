//
//  ImageGeneratorViewModel.swift
//  imageGenerator
//
//  Created by Phincon on 25/11/23.
//

import Foundation
import SwiftUI
import OpenAIKit
import netfox
import AVFoundation

final class ViewModel: ObservableObject {
    
    
    private var audioPlayer: AVAudioPlayer?
    private var openAI: OpenAI?
    
    let apiKey2 = ""

    
    func setup() {
        openAI = OpenAI(
            Configuration(
                organizationId: "org-r08c1rKaqGTurWtwZaDfQQEv",
                apiKey: apiKey2
            )
        )
    }
    
    func generateImage(from prompt: String) async -> UIImage? {
        guard let openAI = openAI else {
            return nil
        }
        
        let imageParameters = ImageParameters(
            prompt: prompt,
            resolution: .medium,
            responseFormat: .base64Json
        )
    
        do {
            let result = try await openAI.createImage(parameters: imageParameters)
            let imageData = result.data[0].image
            let image = try openAI.decodeBase64Image(imageData)
            return image
            
        } catch {
            print(error.localizedDescription)
            return nil
        }

    }
    
    func generateImage() async -> UIImage? {
        guard let openAI = openAI else {
            return nil
        }
        do {
            let imageParam = ImageParameters(
                prompt: "An armchair in the shape of an avocado",
                resolution: .large,
                responseFormat: .base64Json
            )
            let result = try await openAI.createImage(
                parameters: imageParam
            )
            let b64Image = result.data[0].image
            let image = try openAI.decodeBase64Image(b64Image)
            return image
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    func generateChat(from prompt: String) async -> String? {
        guard let openAI = openAI else {
            return nil
        }
        do {
            let chat: [ChatMessage] = [
                ChatMessage(role: .system, content: "You are a helpful assistant."),
                ChatMessage(role: .user, content: prompt)
             
            ]

            let chatParameters = ChatParameters(
                model: "gpt-3.5-turbo",  // ID of the model to use.
                messages: chat,  // A list of messages comprising the conversation so far.
                temperature: 1.0
            )

            let chatCompletion = try await openAI.generateChatCompletion(
                parameters: chatParameters
               
            )

            let content = chatCompletion.choices[0].message.content
            return content
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    

    func play(audioData: Data? , isPlay: Bool) {
       guard let data = audioData else {
           print("No audio data set")
           return
       }
       
       do {
           audioPlayer = try AVAudioPlayer(data: data)
           if isPlay {
               audioPlayer?.prepareToPlay()
               audioPlayer?.play()
           } else {
               audioPlayer?.stop()
           }
       } catch {
           print("Error initializing audio player: \(error.localizedDescription)")
       }
   }
    
    
    func translateAudioFile<T: Codable>( audioData: Data? , expecting type: T.Type, completion: @escaping (Result<T, Error>) -> Void) {
        let apiUrl = "https://api.openai.com/v1/audio/translations"
        let filePath = "/path/to/file/audio.mp3"  // Replace with the actual file path

        guard let url = URL(string: apiUrl) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // Set the Authorization header
        request.setValue("Bearer \(apiKey2)", forHTTPHeaderField: "Authorization")

        // Create the multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Add the file data to the body
        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"file\"; filename=\"\(URL(fileURLWithPath: filePath).lastPathComponent)\"\r\n".utf8))
        body.append(Data("Content-Type: audio/mp3\r\n\r\n".utf8))

//        if let fileData = try? Data(contentsOf: URL(fileURLWithPath: filePath)) {
//            body.append(fileData)
//        }
//
        if let fileData = audioData {
            body.append(fileData)
        }
        

        body.append(Data("\r\n--\(boundary)\r\n".utf8))

        // Add the model parameter to the body
        body.append(Data("Content-Disposition: form-data; name=\"model\"\r\n\r\n".utf8))
        body.append(Data("whisper-1\r\n".utf8))
        body.append(Data("--\(boundary)--\r\n".utf8))

        request.httpBody = body

        
        URLSession.shared.dataTask(with: request) { data, _, error in
              guard let data = data, error == nil else {
                  completion(.failure(error!))
                  return
              }
              
              do {
                  let result = try JSONDecoder().decode(type.self, from: data)
                  completion(.success(result))
              } catch {
                  completion(.failure(error))
              }
          }.resume()
    }

    func generateSpeech(from prompt: String, voiceType: String,  completion: @escaping (Result<Data, Error>) -> Void) {
        let apiUrl = "https://api.openai.com/v1/audio/speech"
        
        guard let url = URL(string: apiUrl) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Set the Authorization header
        request.setValue("Bearer \(apiKey2)", forHTTPHeaderField: "Authorization")
        
        // Set the Content-Type header
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create the request body as JSON
        let requestBody: [String: Any] = [
            "model": "tts-1",
            "input": prompt,
            "voice": voiceType
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else {
                completion(.failure(error!))
                return
            }
            completion(.success(data))
        }.resume()
    }
}




