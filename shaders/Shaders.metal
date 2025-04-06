//
//  Shaders.metal
//  PixelEmu
//
//  Created by Anne Castrillon on 4/4/25.
//

// Vertex

#include <metal_stdlib>
using namespace metal;

struct FragmentUniforms {
    bool hasTexture;
};

vertex float4 vertex_basic(const device float2* position [[ buffer(0) ]],
                          uint vid [[ vertex_id ]]) {
    return float4(position[vid], 0.0, 1.0);
}

fragment float4 fragment_basic(constant float4& color [[buffer(0)]]) {
    return color;
}

struct VertexIn {
    float2 position [[attribute(0)]];
    float2 uv       [[attribute(1)]];
    float4 color    [[attribute(2)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 uv;
    float4 color;
};

vertex VertexOut vertex_main(VertexIn in [[stage_in]]) {
    VertexOut out;
    out.position = float4(in.position, 0.0, 1.0);
    out.uv = in.uv;
    out.color = in.color;
    return out;
}

// Fragment
fragment float4 fragment_main(VertexOut in [[stage_in]],
                              texture2d<float> tex [[texture(0)]],
                              constant FragmentUniforms& uniforms [[buffer(1)]])
{
    constexpr sampler textureSampler(address::repeat, filter::nearest);

    if (uniforms.hasTexture) {
        in.uv = clamp(in.uv, float2(0.0), float2(1.0));
        return tex.sample(textureSampler, in.uv);
    } else {
        return float4(in.color);
    }
}
