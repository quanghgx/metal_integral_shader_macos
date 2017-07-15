//
//  test_class.swift
//  study_integral_macos
//
//  Created by Hoàng Xuân Quang on 7/9/17.
//  Copyright © 2017 Hoang Xuan Quang. All rights reserved.
//

import Foundation
import MetalKit

class TestClass {

    var device: MTLDevice! = nil
    var library : MTLLibrary! = nil
    var commandQueue : MTLCommandQueue! = nil

    init() {
        device = MTLCreateSystemDefaultDevice()!;
        library = device.makeDefaultLibrary()!;
        commandQueue = device.makeCommandQueue()

        print("[test-class] init \(device.description)")
    }

    func test_square(){
        let width: Int = 4
        let height: Int = 3

        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: MTLPixelFormat.r32Float,
            width: width,
            height: height,
            mipmapped: false)
        let grayscaleTex = device.makeTexture(descriptor: descriptor)
        let image:[Float] = [
            1, 2, 3, 4,
            5, 6, 7, 8,
            9, 10, 11, 12
        ]
        grayscaleTex.replace(region: MTLRegionMake2D(0,0,width,height), mipmapLevel: 0, withBytes: image, bytesPerRow: width*4)

        let square_descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: MTLPixelFormat.r32Float,
            width: width,
            height: height,
            mipmapped: false)
        square_descriptor.usage = [.shaderWrite]
        let squareTex = device.makeTexture(descriptor: square_descriptor)
        let commandBuffer = commandQueue.makeCommandBuffer()
        simple_square.process(device: device, library: library, commandBuffer: commandBuffer, sourceTexture: grayscaleTex, destinationTexture: squareTex)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        //5. logging
        let gray_array = texture_to_array(texture: grayscaleTex)
        print("gray_array: ")
        display(img: gray_array, width: width, height: height)

        let square_array = texture_to_array(texture: squareTex)
        print("square_array: ")
        display(img: square_array, width: width, height: height)
    }

    func test_square_integral(){
        let width: Int = 4
        let height: Int = 3

        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: MTLPixelFormat.r32Float,
            width: width,
            height: height,
            mipmapped: false)
        descriptor.usage = [.shaderRead]
        let grayscaleTex = device.makeTexture(descriptor: descriptor)
        let image:[Float] = [
            1, 2, 3, 4,
            5, 6, 7, 8,
            9, 10, 11, 12
        ]
        grayscaleTex.replace(region: MTLRegionMake2D(0,0,width,height), mipmapLevel: 0, withBytes: image, bytesPerRow: width*4)

        let output_descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: MTLPixelFormat.r32Float,
            width: width,
            height: height,
            mipmapped: false)
        output_descriptor.usage = [.shaderWrite]
        let outputTex = device.makeTexture(descriptor: output_descriptor)
        let commandBuffer = commandQueue.makeCommandBuffer()
        let ii = IntegralImage(device: device, library: library, width: width, height: height, inclusive: true)
        ii.encode_square(commandBuffer, sourceTexture: grayscaleTex, destinationTexture: outputTex)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        //5. logging
        let gray_array = texture_to_array(texture: grayscaleTex)
        print("gray_array: ")
        display(img: gray_array, width: width, height: height)

        let ii_integral_square = texture_to_array(texture: outputTex)
        print("ii_integral_square: ")
        display(img: ii_integral_square, width: width, height: height)
    }

    func testSmallTextureSum() -> Bool {
        print("[test-class] testSmallTextureSum")

        let n = 32
        let width = n
        let height = n
        let (ii, input, output) = createTestSetup(width, height)
        let sum = TestClass.getBufferForFloat(device: device)

        let commandBuffer = commandQueue.makeCommandBuffer()
        ii.encode(commandBuffer, sourceTexture: input, destinationTexture: output)
        ii.getBoxIntegral(commandBuffer, integralImage: output, row: 0, col: 0, rows: n, cols: n, output: sum)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        print("[test-class] evaluation")

        let vals = TestClass.textureToArray(texture: output)
        return (vals[n*n-1]==Float(n*n)) && (TestClass.floatBufferToFloat(sum) == Float(n*n))
    }

    func compareImplAgainstMPSWithBounds() -> Bool {

        let width = 1280
        let height = 720

        let input = TestClass.createRandomTexture(device: device, width: width, height: height)
        let (ii, _, output) = createTestSetup(width, height)

        let commandBuffer = commandQueue.makeCommandBuffer()
        ii.encode(commandBuffer, sourceTexture: input, destinationTexture: output)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        return true;

    }

    func compareImplAgainstMPS() -> Bool {

        let width = 1280
        let height = 720

        let input = TestClass.createTestTexture(device: device, val: 1.0, width: width, height: height)
        let (ii, _, output) = createTestSetup(width, height)

        let commandBuffer = commandQueue.makeCommandBuffer()
        ii.encode(commandBuffer, sourceTexture: input, destinationTexture: output)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        return true;

    }

    func assertWithinBounds(val1: Float, val2: Float, bound: Float) {
        assert(val1 >= val2 - bound && val1 <= val2 + bound)
    }


    func testTimes720p() -> Bool {

        print("[test-class] testTimes720p")

        let n = 10
        let (ii, input, output) = createTestSetup(1280, 720)

        var elapsedGPU : UInt64 = 0
        for _ in 0..<n {
            let commandBuffer = commandQueue.makeCommandBuffer()
            ii.encode(commandBuffer, sourceTexture: input, destinationTexture: output)
            let _t1 = mach_absolute_time()
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
            let _t2 = mach_absolute_time()
            elapsedGPU += _t2-_t1
        }
        var timeBaseInfo = mach_timebase_info_data_t()
        mach_timebase_info(&timeBaseInfo)

        let elapsedNanoGPU = elapsedGPU * UInt64(timeBaseInfo.numer) / UInt64(timeBaseInfo.denom);
        let nanoSecondsGPU = Float(elapsedNanoGPU)/Float(n)
        print("Nano Seconds 720p (GPU): \(nanoSecondsGPU)")
        let milliSecondsGPU = nanoSecondsGPU*Float(1e-6)
        print("Milli Seconds 720p (GPU): \(milliSecondsGPU)")
        print("Theoretical FPS 720p: \(1/(milliSecondsGPU/1000))·")
        return true
    }

    func testTimes1080p() -> Bool {

        let n = 1000
        let (ii, input, output) = createTestSetup(1920, 1080)

        var elapsedGPU : UInt64 = 0
        for _ in 0..<n {
            let commandBuffer = commandQueue.makeCommandBuffer()
            ii.encode(commandBuffer, sourceTexture: input, destinationTexture: output)
            let _t1 = mach_absolute_time()
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
            let _t2 = mach_absolute_time()
            elapsedGPU += _t2-_t1
        }
        var timeBaseInfo = mach_timebase_info_data_t()
        mach_timebase_info(&timeBaseInfo)

        let elapsedNanoGPU = elapsedGPU * UInt64(timeBaseInfo.numer) / UInt64(timeBaseInfo.denom);
        let nanoSecondsGPU = Float(elapsedNanoGPU)/Float(n)
        print("Nano Seconds 1080p (GPU): \(nanoSecondsGPU)")
        let milliSecondsGPU = nanoSecondsGPU*Float(1e-6)
        print("Milli Seconds 1080p (GPU): \(milliSecondsGPU)")
        print("Theoretical FPS 1080p: \(1/(milliSecondsGPU/1000))·")
        return true
    }

    private func createTestSetup(_ width: Int, _ height: Int, val: Float = 1.0, inclusive: Bool = true) -> (IntegralImage, MTLTexture, MTLTexture) {
        let ii = IntegralImage(device: device, library: library, width: width, height: height, inclusive: true)
        let input = TestClass.createTestTexture(device: device, val: val, width: width, height: height, useIncrease: false)
        let output = TestClass.createTestTexture(device: device, val: 0.0, width: width, height: height)
        return (ii, input, output)
    }

    class func createRandomTexture(device: MTLDevice, width: Int, height: Int) -> MTLTexture {
        var test = [Float](repeatElement(0.0, count: width*height))
        for i in 0..<width*height {
            test[i] = Float(Float(arc4random()) / Float(UINT32_MAX))
        }
        return TestClass.createTexture(device: device, format: .r32Float, width: width, height: height, bytes: test)
    }

    class func printTexture(texture: MTLTexture, displayBlockSize: Bool = true, blockSize: Int = 64) {
        let bytesPerRow = texture.width*MemoryLayout<Float>.size
        let region = MTLRegionMake2D(0, 0, texture.width, texture.height)
        var vals = [Float](repeatElement(0.0, count: texture.width*texture.height))
        texture.getBytes(&vals, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
        for y in 0..<texture.height {
            var rowStr = "";
            var blockCnt = 0;
            for x in 0..<texture.width {
                rowStr += "\(vals[y*texture.width+x])"

                if x < texture.width-1 {
                    rowStr += ","
                }
                if (((x+1)%blockSize==0 && x>0) || x == texture.width-1) && displayBlockSize {
                    rowStr += "||| (row: \(y), block: \(blockCnt))\n"
                    blockCnt+=1;
                }
            }
            print(rowStr)
        }
    }

    class func createTestTexture(device: MTLDevice, val: Float, width: Int, height: Int, useIncrease: Bool = false) -> MTLTexture {

        var test = [Float](repeatElement(val, count: width*height))
        if useIncrease {
            var cnt = 1;
            for i in 0..<test.count {
                if(i%width==0) {
                    cnt = 1
                };
                test[i]=Float(cnt)*val
                cnt+=1;
            }
        }

        return createTexture(device: device, format: .r32Float, width: width, height: height, bytes: test)
    }

    class func createTexture(device: MTLDevice, format: MTLPixelFormat, width: Int, height: Int, bytes: [Float]) -> MTLTexture {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: format, width: width, height: height, mipmapped: false)
        descriptor.usage = [.shaderRead,.shaderWrite]
        let t = device.makeTexture(descriptor: descriptor)
        t.replace(region: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0, withBytes: bytes, bytesPerRow: width*4)
        return t
    }

    class func textureToArray(texture: MTLTexture) -> [Float] {
        let bytesPerRow = texture.width*MemoryLayout<Float>.size
        let region = MTLRegionMake2D(0, 0, texture.width, texture.height)
        var vals = [Float](repeatElement(0.0, count: texture.width*texture.height))
        texture.getBytes(&vals, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
        return vals;
    }

    class func getBufferForFloat(device: MTLDevice) -> MTLBuffer {
        return device.makeBuffer(length: MemoryLayout<Float>.size, options: MTLResourceOptions.storageModeShared)
    }

    class func floatBufferToFloat(_ buffer: MTLBuffer) -> Float {
        let data = NSData(bytesNoCopy: buffer.contents(),
                          length: MemoryLayout<Float>.size, freeWhenDone: false)
        var rtn : Float = -1.0
        data.getBytes(&rtn, length:MemoryLayout<Float>.size)
        return rtn
    }

    func texture_to_array(texture: MTLTexture) -> [Float] {
        let bytesPerRow = texture.width*MemoryLayout<Float>.size
        let region = MTLRegionMake2D(0, 0, texture.width, texture.height)
        var vals = [Float](repeatElement(0.0, count: texture.width*texture.height))
        texture.getBytes(&vals, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
        return vals;
    }

    func display(img: [Float], width: Int, height: Int ) {
        var result:String = ""
        for y in 0...(height-1){
            for x in 0...(width-1){
                result +=  String(img[y * width + x]) + " "
            }
            result += "\n"
        }
        print("\(result)")
    }
}
