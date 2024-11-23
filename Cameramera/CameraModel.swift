//
//  CameraModel.swift
//  Cameramera
//
//  Created by Antoine Bollengier on 23.11.2024.
//  Copyright © 2024 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import Foundation
import UIKit

class CameraModel: NSObject, URLSessionDataDelegate {
    static let shared = CameraModel()
    
    @MainActor @Published private(set) var isRunning: Bool = false
    
    var shouldRestartIfConnectionLost: Bool = true
    
    private var currentConfiguration: Configuration?
    
    private var currentTask: URLSessionDataTask?
    
    private var session: URLSession!
    
    private var dataBuffer: Data = Data()
    
    private var completionHandler: ((UIImage) -> Void)?
    
    override init() {
        super.init()
        self.session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }
    
    func start(withConfiguration configuration: Configuration, completionHandler: @escaping (UIImage) -> Void) {
        self.stop()
        
        self.currentConfiguration = configuration
        self.completionHandler = completionHandler
        
        self.startSession()
    }
    
    func stop() {
        self.dataBuffer.removeAll()
        
        if currentTask != nil {
            self.currentTask?.cancel()
            self.currentTask = nil
        }
        
        self.completionHandler = nil
        
        DispatchQueue.main.async {
            self.isRunning = false
        }
    }
    
    private func startSession() {
        guard let configuration = currentConfiguration else { return }
        let url = URL(string: "http://\(configuration.ipAddress)/\(configuration.videoEndpoint)")!
        
        var request = URLRequest(url: url)
        
        request.setValue(configuration.authToken, forHTTPHeaderField: "Authorization")
        
        // Start a data task with the request
        self.currentTask = self.session.dataTask(with: request)
        self.currentTask?.resume()
        
        DispatchQueue.main.async {
            self.isRunning = true
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        if self.shouldRestartIfConnectionLost {
            self.startSession()
        } else {
            self.stop()
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        // Append the incoming data to the buffer
        dataBuffer.append(data)

        // Process the buffer to extract frames
        processBuffer()
    }
    
    private func processBuffer() {
        // magic number of jpeg image
        let imageMagicNumberData = Data(base64Encoded: "/9j/4AAQSkZJRg==".data(using: .ascii)!)!
        
        while let beginning = dataBuffer.range(of: imageMagicNumberData), let end = dataBuffer.range(of: imageMagicNumberData, in: beginning.upperBound..<dataBuffer.endIndex) {
            let imageData = dataBuffer.subdata(in: beginning.lowerBound..<end.lowerBound)
            
            dataBuffer.removeSubrange(dataBuffer.startIndex..<end.lowerBound)
            
            if let image = UIImage(data: imageData) {
                self.completionHandler?(image)
            }
        }
    }


    struct Configuration {
        let ipAddress: String
        
        let authToken: String? // base64 username:password
        
        let videoEndpoint: String
    }
}
