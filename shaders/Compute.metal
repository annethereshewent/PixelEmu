//
//  Compute.metal
//  PixelEmu
//
//  Created by Anne Castrillon on 4/15/25.
//

#include <metal_stdlib>
using namespace metal;

struct RDPVertex {
    float3 position;
    float2 uv;
    float4 color;
};

struct Triangle {
    RDPVertex v0;
    RDPVertex v1;
    RDPVertex v2;
    float3 dsdx_dtdx_dwdx;
    float3 dsdy_dtdy_dwdy;
};

kernel void clear_framebuffer(
    texture2d<float, access::write> framebuffer [[texture(0)]],
    uint2 tid [[thread_position_in_grid]]
) {
    if (tid.x >= framebuffer.get_width() || tid.y >= framebuffer.get_height())
        return;

    framebuffer.write(float4(0, 0, 0, 1), tid); // Black clear
}


kernel void rasterize_triangle(
    device const Triangle* triangles [[buffer(0)]],
    texture2d<float, access::write> framebuffer [[texture(0)]],
    uint tid [[thread_position_in_grid]]
)
{
    Triangle tri = triangles[tid];

    float3 pos1 = tri.v0.position;
    float3 pos2 = tri.v1.position;
    float3 pos3 = tri.v2.position;

    float minX = min(pos1.x, min(pos2.x, pos3.x));
    float maxX = max(pos1.x, max(pos2.x, pos3.x));

    float minY = min(pos1.y, min(pos2.y, pos3.y));
    float maxY = max(pos1.y, max(pos2.y, pos3.y));

    int minXi = max(int(floor(minX)), 0);
    int maxXi = min(int(ceil(maxX)), int(framebuffer.get_width()));

    int minYi = max(int(floor(minY)), 0);
    int maxYi = min(int(ceil(maxY)), int(framebuffer.get_height()));


    float2 a = pos1.xy;
    float2 b = pos2.xy;
    float2 c = pos3.xy;

    for (int y = minYi; y <= maxYi; y++) {
        for (int x = minXi; x <= maxXi; x++) {
            float2 p = float2(x, y);

            float2 ab = b - a;
            float2 bc = c - b;
            float2 ca = a - c;

            float2 ap = p - a;
            float2 bp = p - b;
            float2 cp = p - c;

            float abEdge = ab.x * ap.y - ab.y * ap.x;
            float bcEdge = bc.x * bp.y - bc.y * bp.x;
            float caEdge = ca.x * cp.y - ca.y * cp.x;

            if ((abEdge <= 0 && bcEdge <= 0 && caEdge <= 0) || (abEdge >= 0 && bcEdge >= 0 && caEdge >= 0)) {
                framebuffer.write(float4(1, 0.411764, 0.705888, 1), uint2(x, y));
            }
        }
    }
}
