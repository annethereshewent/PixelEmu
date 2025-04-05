//
//  Shaders.metal
//  PixelEmu
//
//  Created by Anne Castrillon on 4/4/25.
//

// Vertex
vertex float4 vertex_main(const device float2* position [[ buffer(0) ]],
                          uint vid [[ vertex_id ]]) {
    return float4(position[vid], 0.0, 1.0);
}

// Fragment
fragment float4 fragment_main(const constant float4& color [[ buffer(0) ]]) {
    return color;
}
