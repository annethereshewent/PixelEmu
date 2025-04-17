//
//  Compute.metal
//  PixelEmu
//
//  Created by Anne Castrillon on 4/15/25.
//

#include <metal_stdlib>
using namespace metal;

struct Triangle {
    float xl;
    float xh;
    float xm;

    float yl;
    float yh;
    float ym;

    float dxldy;
    float dxmdy;
    float dxhdy;

    float4 rgba;

    float s;
    float t;

    float4 drdx_dgdx_dbdx_dadx;
    float4 drdy_dgdy_dbdy_dady;
    float4 drde_dgde_dbde_dade;

    float3 dsdx_dtdx_dwdx;
    float3 dsdy_dtdy_dwdy;

    bool flip;
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

    int ymin = int(tri.yh);
    int ymax = int(tri.yl);

    for (int y = ymin; y <= ymax; y++) {
        float xLeft;
        float xRight;

        float4 rgba = tri.rgba + (y - ymin) * tri.drdy_dgdy_dbdy_dady;

//        if (tri.flip) {
//            // xLeft = tri.xm - (y - tri.yh) * tri.dxmdy;
//            xLeft = tri.xm + (y - tri.yh) * tri.dxmdy;
//
//            float xRightTop = tri.xh + (y - tri.yh) * tri.dxhdy;
//            float xRightBottom = tri.xl + (y - tri.ym) * tri.dxldy;
//
//            xRight = y <= tri.ym ? xRightTop : xRightBottom;
//        } else {
//            xLeft = tri.xh - (y - tri.yh) * tri.dxhdy;
//            float xRightTop = tri.xm + (y - tri.yh) * tri.dxmdy;
//            float xRightBottom = tri.xl - (y - tri.ym) * tri.dxldy;
//            xRight = y <= tri.ym ? xRightTop : xRightBottom;
//        }
        if (tri.flip) {
            // Right-major triangle: right edge = xh, left = xm/xl
            float xLeftMid = tri.xm + (y - tri.yh) * tri.dxmdy;
            float xLeftLow = tri.xl + (y - tri.ym) * tri.dxldy;
            xLeft = y <= tri.ym ? xLeftMid : xLeftLow;

            xRight = tri.xh + (y - tri.yh) * tri.dxhdy;
        } else {
            // Left-major triangle: left edge = xh, right = xm/xl
            xLeft = tri.xh + (y - tri.yh) * tri.dxhdy;

            float xRightMid = tri.xm + (y - tri.yh) * tri.dxmdy;
            float xRightLow = tri.xl + (y - tri.ym) * tri.dxldy;
            xRight = y <= tri.ym ? xRightMid : xRightLow;
        }

        int xStart = max(int(floor(xLeft)), 0);
        int xEnd = min(int(ceil(xRight)), int(framebuffer.get_width()) - 1);
        int yClamped = clamp(y, 0, int(framebuffer.get_height()) - 1);

        for (int x = xStart; x <= xEnd; x++) {
            framebuffer.write(clamp(rgba / 255.0, 0, 1), uint2(x, yClamped));
            rgba += tri.drde_dgde_dbde_dade;
        }
    }
}
