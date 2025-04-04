#pragma once

#include <cstdint>
#include <vector>
#include <array>

class Bus;

enum DPCStatusBits {
    Xbus = 0,
    Freeze = 1,
    Flush = 2,
    Gclk = 3,
    TmemBusy = 4,
    PipeBusy = 5,
    CmdBusy = 6,
    CbufReady = 7,
    DPCDmaBusy = 8,
    EndPending = 9,
    StartPending = 10
};

const unsigned cmdLengths[64] = {
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    4,
    6,
    12,
    14,
    12,
    14,
    20,
    22,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    2,
    2,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
};
enum class RdpOp {
    Nop = 0,

    MetaSignalTimeline = 1,
    MetaFlush = 2,
    MetaIdle = 3,
    MetaSetQuirks = 4,

    FillTriangle = 0x08,
    FillZBufferTriangle = 0x09,
    TextureTriangle = 0x0a,
    TextureZBufferTriangle = 0x0b,
    ShadeTriangle = 0x0c,
    ShadeZBufferTriangle = 0x0d,
    ShadeTextureTriangle = 0x0e,
    ShadeTextureZBufferTriangle = 0x0f,
    TextureRectangle = 0x24,
    TextureRectangleFlip = 0x25,
    SyncLoad = 0x26,
    SyncPipe = 0x27,
    SyncTile = 0x28,
    SyncFull = 0x29,
    SetKeyGB = 0x2a,
    SetKeyR = 0x2b,
    SetConvert = 0x2c,
    SetScissor = 0x2d,
    SetPrimDepth = 0x2e,
    SetOtherModes = 0x2f,
    LoadTLut = 0x30,
    SetTileSize = 0x32,
    LoadBlock = 0x33,
    LoadTile = 0x34,
    SetTile = 0x35,
    FillRectangle = 0x36,
    SetFillColor = 0x37,
    SetFogColor = 0x38,
    SetBlendColor = 0x39,
    SetPrimColor = 0x3a,
    SetEnvColor = 0x3b,
    SetCombine = 0x3c,
    SetTextureImage = 0x3d,
    SetMaskImage = 0x3e,
    SetColorImage = 0x3f
};


class RDPInterface {
public:
    uint32_t status = 0;

    uint32_t start = 0;
    uint32_t end = 0;
    uint32_t current = 0;

    uint32_t pipeBusy = 0xffffff;

    std::array<uint32_t, 0x10000> cmdBuffer = {};
    int currCmd = 0;
    int cmdPtr = 0;
    uint32_t region = 0;

    bool cmdsReady = false;

    std::vector<std::vector<uint32_t>> enqueuedWords = {};

    uint32_t clockCounter = 0;
    bool isFrozen = false;
    bool frameFinished = false;

    RDPInterface(Bus& bus): bus(bus) {};

    Bus& bus;

    uint64_t processRdpCommands();
    void enqueueCommandWords(int numWords, uint32_t* words);

    void clearCommands();

    uint32_t readRegisters(uint32_t offset);
    void writeRegisters(uint32_t offset, uint32_t value);
    void updateStatus(uint32_t value);
};
