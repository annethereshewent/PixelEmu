//
//  Compute.metal
//  PixelEmu
//
//  Created by Anne Castrillon on 4/15/25.
//

#include <metal_stdlib>
using namespace metal;

enum TextureSize {
    Bpp4 = 0,
    Bpp8 = 1,
    Bpp16 = 2,
    Bpp32 = 3
};

enum TextureFormat {
    RGBA = 0,
    YUV = 1,
    CI = 2,
    IA = 3,
    I = 4
};

struct TileProps {
    uint mirrorSBit;
    uint clampSBit;
    uint mirrorTBit;
    uint clampTBit;

    uint offset;
    uint stride;
    TextureSize size;
    TextureFormat fmt;
    uint palette;

    uint shiftS;
    uint shiftT;
    uint maskS;
    uint maskT;
};

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
    float3 stw;

    float4 drdx_dgdx_dbdx_dadx;
    float4 drdy_dgdy_dbdy_dady;
    float4 drde_dgde_dbde_dade;

    float3 dsdx_dtdx_dwdx;
    float3 dsdy_dtdy_dwdy;
    float3 dsde_dtde_dwde;

    uint bufferOffset;
    uint validTexelCount;
    uint textureWidth;
    uint textureHeight;

    uint flip;
    uint hasTexture;

    TileProps tileProps;
};

kernel void clear_framebuffer(
    texture2d<float, access::write> framebuffer [[texture(0)]],
    uint2 tid [[thread_position_in_grid]]
) {
    if (tid.x >= framebuffer.get_width() || tid.y >= framebuffer.get_height())
        return;

    framebuffer.write(float4(0, 0, 0, 1), tid); // Black clear
}

float4 decodeRGBA16(uint16_t texel) {
    float r = float((texel >> 11) & 0x1F) / 31.0;
    float g = float((texel >> 6) & 0x1F) / 31.0;
    float b = float((texel >> 1) & 0x1F) / 31.0;
    float a = (texel & 0x01) != 0 ? 1.0 : 0.0;
    return float4(r, g, b, a);
}

kernel void rasterize_triangle(
    device const Triangle* triangles [[buffer(0)]],
    device const uchar* textureBuffer [[buffer(1)]],
    texture2d<float, access::write> framebuffer [[texture(0)]],
    uint tid [[thread_position_in_grid]]
)
{
    Triangle tri = triangles[tid];

    int ymin = int(tri.yh);
    int ymax = int(tri.yl);

    uint validHeight = tri.validTexelCount / tri.textureWidth;

    for (int y = ymin; y <= ymax; y++) {
        float xLeft;
        float xRight;

        float4 rgba = tri.rgba + (y - ymin) * tri.drdy_dgdy_dbdy_dady;
        float3 stw = tri.stw + (y - ymin) * tri.dsdy_dtdy_dwdy;

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
            float4 finalColor;

            if (tri.hasTexture) {
                float2 st = (stw.xy / stw.z);

                int s = int(st.x);
                int t = int(st.y);

                uint maskedS = s & ((1 << tri.tileProps.maskS) - 1);
                if (tri.tileProps.mirrorSBit && ((s >> tri.tileProps.maskS) & 1) == 1) {
                    maskedS = ((1 << tri.tileProps.maskS) - 1) - maskedS;
                }
                if (tri.tileProps.clampSBit) {
                    maskedS = min(maskedS, tri.textureWidth); // max S for clamp
                }

                uint maskedT = t & ((1 << tri.tileProps.maskT) - 1);
                if (tri.tileProps.mirrorTBit && ((t >> tri.tileProps.maskT) & 1)) {
                    maskedT = ((1 << tri.tileProps.maskT) - 1) - maskedT;
                }
                if (tri.tileProps.clampTBit) {
                    maskedT = min(maskedT, validHeight); // max T for clamp
                }

                int index = tri.bufferOffset + tri.tileProps.offset + s + t * tri.textureWidth;

                uint16_t texel = uint16_t(textureBuffer[index]) << 8 | uint16_t(textureBuffer[index + 1]);

                float4 decoded = decodeRGBA16(texel);

                finalColor = decoded * rgba;
            } else {
                finalColor = clamp(rgba / 255.0, 0 ,1);
            }

            framebuffer.write(finalColor, uint2(x, yClamped));
            rgba += tri.drde_dgde_dbde_dade;
            stw += tri.dsde_dtde_dwde;
        }
    }
}
