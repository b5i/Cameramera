//
//  ScannerModel.swift
//  Cameramera
//
//  Created by Antoine Bollengier on 23.11.2024.
//  Copyright © 2024 Antoine Bollengier (github.com/b5i). All rights reserved.
//

import Foundation
import Combine
import MMLanScan

class ScannerModel: NSObject, ObservableObject, MMLANScannerDelegate {
    static let shared = ScannerModel()
    
    var lanScanner : MMLANScanner!
    
    @Published private(set) var isScanning = false
    
    @Published private(set) var connectedDevices = Set<MMDevice>()
    
    @Published private(set) var failedToScan: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()

        self.lanScanner = MMLANScanner(delegate: self)
        
        self.lanScanner.publisher(for: \.isScanning)
            .sink { [weak self] newValue in
                DispatchQueue.main.async {
                    self?.isScanning = newValue
                }
            }
            .store(in: &cancellables)
    }
    
    func startNetWorkScan() {
        DispatchQueue.main.async {
            self.connectedDevices = []
            self.failedToScan = false
        }
        self.lanScanner.start()
    }
    
    func stopNetWorkScan() {
        self.lanScanner.stop()
    }
        
    
    func lanScanDidFindNewDevice(_ device: MMDevice!) {
        DispatchQueue.main.async {
            self.connectedDevices.insert(device)
        }
    }
    
    func lanScanDidFinishScanning(with status: MMLanScannerStatus) {}
    
    func lanScanDidFailedToScan() {
        DispatchQueue.main.async {
            self.failedToScan = true
        }
    }
}
