//
//  AimyboxDialogAPI.swift
//  Aimybox
//
//  Created by Vladyslav Popovych on 08.12.2019.
//

import Foundation
import AimyboxCore

fileprivate struct AimyboxConstants {
    /// Sensitive dat
//    public static let api_base_route = URL(string: "https://api.aimybox.com")!
    public static let api_request_route = URL(string: "https://bot.aimylogic.com/chatapi/webhook/zenbox/cVcGlsvz:800911b5cd537cba8c734e772f8c4a1ebd68fb1a")!
    
    
//    public static let api_request_route = api_base_route.appendingPathComponent("/request")
    
    public static let api_default_reply_types: [String:Reply.Type] = [
        "text" : AimyboxTextReply.self,
        "audio" : AimyboxAudioReply.self,
        "image" : AimyboxImageReply.self,
        "buttons" : AimyboxButtonsReply.self
    ]
}



public class AimyboxDialogAPI: AimyboxComponent, DialogAPI {
    
    public var timeoutPollAttempts: Int = 10

    public var customSkills: [AimyboxCustomSkill] = []
    
    public var notify: (DialogAPICallback)?
    
    internal var api_key: String
    
    internal var unit_key: String
    
    public init(api_key: String, unit_key: String) {
        self.api_key = api_key
        self.unit_key = unit_key
    }


    public func createRequest(query: String) -> AimyboxRequest {
        return AimyboxRequest(query: query, apiKey: api_key, unitKey: unit_key, data: [:])
    }

    public func send(request: AimyboxRequest) throws -> AimyboxResponse {
        
        let data = try JSONEncoder().encode(request)
        
        var request = URLRequest(url: AimyboxConstants.api_request_route)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        
        let group = DispatchGroup()
        
        var result: AimyboxResult<AimyboxResponse, Error>?
        
        group.enter()
        URLSession.shared.dataTask(with: request) { (data, response, _error) in
            guard _error == nil else {
                result = .failure(_error!)
                return
            }
            
            guard let code = (response as? HTTPURLResponse)?.statusCode, 200..<300 ~= code else {
                result = .failure(NSError(domain: "HTTPURLResponse", code: 404, userInfo: [:]))
                return
            }
            
            guard let _data = data else {
                result = .failure(NSError(domain: "Missing response data", code: 204, userInfo: ["statusCode":code]))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(AimyboxResponse.self, from: _data)
                result = .success(response)

            } catch let __error {
                result = .failure(__error)
            }
            
            group.leave()
        }.resume()
        
        group.wait()
        
        guard let _result = result else {
            throw NSError(domain: "No response from dapi request.", code: 204, userInfo: [:])
        }
        
        switch _result {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }
}
