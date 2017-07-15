//
//  simple_square.metal
//  study_integral_macos
//
//  Created by Hoàng Xuân Quang on 7/13/17.
//  Copyright © 2017 Hoang Xuan Quang. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

//square each texel
kernel void square_function(texture2d<float, access::read>  inTexture   [[ texture(0) ]],
                               texture2d<float, access::write> outTexture  [[ texture(1) ]],
                               uint2                          gid          [[ thread_position_in_grid ]]){
    if((gid.x < inTexture.get_width()) && (gid.y < inTexture.get_height())){
        float4 inValue  = inTexture.read(gid);
        outTexture.write(inValue*inValue, gid);
    }
}
