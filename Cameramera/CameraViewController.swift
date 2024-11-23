//
//  CameraViewController.swift
//  Cameramera
//
//  Created by Antoine Bollengier on 23.11.2024.
//  Copyright © 2024 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import UIKit
import MetalKit

class CameraViewController: UIViewController {
    var imageView: UIImageView!
    lazy var device: MTLDevice! = MTLCreateSystemDefaultDevice()
    var commandQueue: MTLCommandQueue!
    var funcName: String = "shader1"

   var outTexture: MTLTexture!
   
   var pipelineState: MTLComputePipelineState!
   let threadGroupCount = MTLSizeMake(16, 16, 1)
    
    private var metalAvailable: Bool = false

    // metal code from  https://medium.com/birdman-inc/how-to-add-effects-to-images-with-msl-metal-shading-language-a785b989f534
    private func setupMetal() {
        let defaultLibrary = device.makeDefaultLibrary()!
        if let target = defaultLibrary.makeFunction(name: funcName) {
            commandQueue = device.makeCommandQueue()
            do {
                pipelineState = try device.makeComputePipelineState(function: target)
                self.metalAvailable = true
            } catch {
                print("Impossible to setup MTL")
                self.metalAvailable = false
            }
        }
    }
    
    /*=========================
         UIImage -> MTLTexture
     =========================*/
    private func mtlTexture(from image: UIImage) -> MTLTexture? {
        UIGraphicsBeginImageContext(image.size);
        image.draw(in: CGRect(x:0, y:0, width:image.size.width, height:image.size.height))
        let renderedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        guard let cgImage = renderedImage?.cgImage else {
            print("Can't open image \(image)")
            return nil
        }
        let textureLoader = MTKTextureLoader(device: self.device)
        do {
            let tex = try textureLoader.newTexture(cgImage: cgImage, options: nil)
            let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: tex.pixelFormat, width: tex.width, height: tex.height, mipmapped: false)
            textureDescriptor.usage = [.shaderRead, .shaderWrite]
            return tex
        }
        catch {
            print("Can't load texture")
            return nil
        }
    }
    
    public func applyShaderTo(image: UIImage) -> UIImage {
        guard metalAvailable else { return image }
        let buffer = commandQueue.makeCommandBuffer()
        let encoder = buffer?.makeComputeCommandEncoder()
        encoder?.setComputePipelineState(pipelineState)
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.rgba8Unorm, width:640, height: 480, mipmapped: false)
        textureDescriptor.usage = [.shaderRead, .shaderWrite]
        outTexture = self.device.makeTexture(descriptor: textureDescriptor)
        encoder?.setTexture(outTexture, index: 0)
        encoder?.setTexture(mtlTexture(from: image), index: 1)
        var volume: UInt8 = MicrophoneManager.shared.audioLevel
        encoder?.setBytes(&volume, length: MemoryLayout<UInt8>.stride, index: 0)
        encoder?.dispatchThreadgroups( MTLSizeMake(
            Int(ceil(image.size.width / CGFloat(self.threadGroupCount.width))),
            Int(ceil(image.size.height / CGFloat(self.threadGroupCount.height))),
            1), threadsPerThreadgroup: threadGroupCount)
        encoder?.endEncoding()
        buffer?.commit()
        buffer?.waitUntilCompleted()
        return self.image(from: self.outTexture)
    }
    
    /*=========================
        MTLTexture -> UIImage
     =========================*/
    private func image(from mtlTexture: MTLTexture) -> UIImage {
        let w = mtlTexture.width
        let h = mtlTexture.height
        let bytesPerPixel: Int = 4
        let imageByteCount = w * h * bytesPerPixel
        let bytesPerRow = w * bytesPerPixel
        var src = [UInt8](repeating: 0, count: Int(imageByteCount))
        let region = MTLRegionMake2D(0, 0, w, h)
        mtlTexture.getBytes(&src, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
        let bitmapInfo = CGBitmapInfo(rawValue: (CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue))
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitsPerComponent = 8
        let context = CGContext(data: &src,
                                width: w,
                                height: h,
                                bitsPerComponent: bitsPerComponent,
                                bytesPerRow: bytesPerRow,
                                space: colorSpace,
                                bitmapInfo: bitmapInfo.rawValue)
        let cgImage = context?.makeImage()
        let image = UIImage(cgImage: cgImage!)
        return image
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMetal()
        
        // Create and configure the image view
        imageView = UIImageView(frame: UIScreen.main.bounds.applying(.init(scaleX: UIScreen.main.scale, y: UIScreen.main.scale)))
        imageView.contentMode = .scaleAspectFill
        self.view.addSubview(imageView)
        
        CameraModel.shared.start(withConfiguration: .init(ipAddress: "192.168.0.x", authToken: "Basic xxxxx" /* username:password encoded in base64 */, videoEndpoint: "video.cgi?resolution=VGA"), completionHandler: { newImage in
            let processedImage = self.applyShaderTo(image: newImage)
            DispatchQueue.main.async {
                self.imageView.image = processedImage
            }
        })
    }
}
