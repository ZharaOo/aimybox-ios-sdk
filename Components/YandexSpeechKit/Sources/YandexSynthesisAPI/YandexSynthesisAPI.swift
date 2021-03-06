//
//  YandexSynthesisAPI.swift
//  YandexSpeechKit
//
//  Created by Vladislav Popovich on 30.01.2020.
//  Copyright © 2020 Just Ai. All rights reserved.
//

import Foundation
import AVFoundation

class YandexSynthesisAPI {
 
    /** IAMToken, used for auth.
     */
    private var token: String
    
    private var folderId: String
    
    private var address: URL
    
    private var operationQueue: OperationQueue
    
    init(
        iAMToken: String,
        folderId: String,
        api address: URL,
        operation queue: OperationQueue
    ) {
        self.token = iAMToken
        self.folderId = folderId
        self.operationQueue = queue
        self.address = address
    }
    
    func request(
        text: String,
        language code: String,
        config: YandexSynthesisConfig,
        onResponse completion: @escaping (URL?)->()
    ) {
        var components = URLComponents(url: address, resolvingAgainstBaseURL: true)!
        
        var queries = [
            URLQueryItem(name: "folderId", value: folderId),
            URLQueryItem(name: "text", value: text),
            URLQueryItem(name: "lang", value: code)
        ]

        queries.append(contentsOf: config.asParams.map { URLQueryItem(name: $0.0, value: $0.1) })
        
        components.queryItems = queries

        guard let url = components.url else {
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        
        perform(request, onResponse: completion)
    }
    
    private func perform(
        _ request: URLRequest,
        onResponse: @escaping (URL?)->()
    ) {
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            guard error == nil else {
                return onResponse(nil)
            }
            
            guard let code = (response as? HTTPURLResponse)?.statusCode, 200..<300 ~= code else {
                return onResponse(nil)
            }
            
            guard let _local_data = data else {
                return onResponse(nil)
            }
            
            guard let _local_url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
                .first?
                .appendingPathComponent("\(UUID().uuidString).wav") else {
                return onResponse(nil)
            }
            
            try? WAVFileGenerator().createWAVFile(using: _local_data).write(to: _local_url)
            
            onResponse(_local_url)
            
            try? FileManager.default.removeItem(at: _local_url)
        })
         
        DispatchQueue.global(qos: .userInitiated).async {
            task.resume()
        }
    }
}

public struct YandexSynthesisConfig {
    
    var voice: String
    var emotion: String
    var speed: Float
    var format: String
    var sampleRateHertz: Int
}

public extension YandexSynthesisConfig {
    /**
     */
    static let defaultConfig: YandexSynthesisConfig = {
        YandexSynthesisConfig(
            voice: "alena",
            emotion: "neutral",
            speed: 1.0,
            format: "lpcm",
            sampleRateHertz: 48000)
    }()
    
    /** Used to build query items.
     */
    internal var asParams: [String : String] {
        var params = [String : String]()
        
        params["voice"] = voice
        params["emotion"] = emotion
        params["speed"] = String(speed)
        params["format"] = format
        params["sampleRateHertz"] = String(sampleRateHertz)
        
        return params
    }
}
