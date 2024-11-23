//
//  camerashader.metal
//  Cameramera
//
//  Created by Antoine Bollengier on 23.11.2024.
//  Copyright © 2024 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

#include <metal_stdlib>
using namespace metal;
kernel void shader1(
  texture2d<float, access::write> outTex [[texture(0)]],
  texture2d<float, access::read> inTex [[texture(1)]],
  uint2 gid [[thread_position_in_grid]],
                    constant uint8_t &volume[[buffer(0)]]
                    )
{
    float convertedVolume = float(volume);
    float3 currentPixelColor = inTex.read(gid).rgb;
    
    float luminance = (0.2126*currentPixelColor.r + 0.7152*currentPixelColor.g + 0.0722*currentPixelColor.b);
    
    if (luminance < 0.45 - convertedVolume / 1000) {
        outTex.write(float4(0, 0, 0, 1), gid);
    } else if (luminance < 0.46 - convertedVolume / 1000) {
        outTex.write(float4(1, 0, 0, 1), gid);
    } else if (luminance < 0.47 - convertedVolume / 1000) {
        outTex.write(float4(1, 1, 0, 1), gid);
    } else if (luminance < 0.48 - convertedVolume / 1000) {
        outTex.write(float4(0, 1, 0, 1), gid);
    } else if (luminance < 0.49 - convertedVolume / 1000) {
        outTex.write(float4(0, 1, 1, 1), gid);
    } else if (luminance < 0.50 - convertedVolume / 1000) {
        outTex.write(float4(0, 0, 1, 1), gid);
    } else if (luminance < 0.51 - convertedVolume / 1000) {
        outTex.write(float4(1, 0, 1, 1), gid);
    } else {
        outTex.write(float4(1, 1, 1, luminance), gid);
    }
}
