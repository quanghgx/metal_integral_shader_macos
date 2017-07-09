//
//  Created by Hoàng Xuân Quang on 7/9/17.
//  Copyright © 2017 Hoang Xuan Quang. All rights reserved.
//

import Foundation
import MetalKit

class simple_transpose{

    class func process(device: MTLDevice,library: MTLLibrary, commandBuffer: MTLCommandBuffer, sourceTexture: MTLTexture, destinationTexture: MTLTexture){
        let pipelineState = build_pipleline_state(device: device, library: library)

        assert(sourceTexture.width == destinationTexture.height && sourceTexture.height == destinationTexture.width)

        // 4. thread group
        let w = pipelineState!.threadExecutionWidth
        let h = pipelineState!.maxTotalThreadsPerThreadgroup / w

        let threads_per_group = MTLSizeMake(w,h,1)
        let threadgroups_per_grid = MTLSize(width: (sourceTexture.width + w - 1) / w,
                                            height: (sourceTexture.height + h - 1) / h,
                                            depth: 1)

        let commandEncoder = commandBuffer.makeComputeCommandEncoder()
        commandEncoder.setComputePipelineState(pipelineState!)
        commandEncoder.setTexture(sourceTexture, index: 0)
        commandEncoder.setTexture(destinationTexture, index: 1)
        commandEncoder.dispatchThreadgroups(threadgroups_per_grid, threadsPerThreadgroup: threads_per_group)
        commandEncoder.endEncoding()
    }

    class func build_pipleline_state(device: MTLDevice, library: MTLLibrary)-> MTLComputePipelineState!{
        let kernelFunction = library.makeFunction(name: "transpose_function")
        do{
            let pipelineState = try device.makeComputePipelineState(function: kernelFunction!)
            return pipelineState
        }catch let error as NSError{
            print("\(error)")
            return nil
        }
    }
}
