#pragma once

#include <cstdint>
#include <vector>
#include <SDL3/SDL.h>
#include "PeripheralInterface.hpp"
#include "RSP.hpp"
#include "VideoInterface.hpp"
#include "AudioInterface.hpp"
#include "SerialInterface.hpp"
#include "RDPInterface.hpp"
#include "PIF.hpp"
#include "RDInterface.hpp"
#include "MIPSInterface.hpp"
#include "ICache.hpp"
#include "DCache.hpp"
#include "TlbEntry.hpp"
#include "Controller.hpp"
#include <iostream>
#include <fstream>

const uint32_t SP_INTERRUPT_FLAG = 1;
const uint32_t SI_INTERRUPT_FLAG = 1 << 1;
const uint32_t AI_INTERRUPT_FLAG = 1 << 2;
const uint32_t VI_INTERRUPT_FLAG = 1 << 3;
const uint32_t PI_INTERRUPT_FLAG = 1 << 4;
const uint32_t DP_INTERRUPT_FLAG = 1 << 5;

const uint32_t EEPROM_4K = 0x8000;
const uint32_t EEPROM_16K = 0xc000;

const uint32_t SRAM_SIZE = 0x8000;
const uint32_t FLASH_SIZE = 0x20000;
const uint32_t SECTOR_SIZE = 0x4000;

const uint32_t FLASH_ID = 0x11118001;
const uint32_t SILICON_ID = 0xc2001e;
const uint32_t FLASHBUF_SIZE = 128;

enum SaveType {
    Sram,
    Flash,
    Eeprom4k,
    Eeprom16k,
    Mempak,
    NoSave
};

enum Width {
    WidthICache = 16,
    WidthDCache = 32,
    Bit64 = 8,
    Bit32 = 4
};

enum FlashMode {
    EraseSector,
    EraseChip,
    Status,
    PageProgram,
    ReadSilliconId,
    ReadArray
};

class Bus {
public:
    std::vector<uint8_t> rdram = {};
    std::vector<bool> rdram9 = {};

    std::vector<TlbLut> tlbReadLut = {};
    std::vector<TlbLut> tlbWriteLut = {};
    std::vector<uint8_t> consoleBuffer = {};

    std::array<TlbEntry, 32> tlbEntries = {};

    std::vector<uint8_t> eeprom = {};
    std::vector<uint8_t> sram = {};
    std::vector<uint8_t> flash = {};

    std::array<uint8_t, 128> flashBuffer = {};

    std::fstream saveFile;

    uint64_t timeSinceSaveWrite = 0;

    char gameId[4];
    std::vector<SaveType> saveTypes = {};

    SDL_Gamepad* gamepad = nullptr;

    uint32_t input = 0;

    CPU& cpu;
    RSP rsp;

    FlashMode flashMode = ReadArray;
    uint32_t flashStatus = 0;
    uint16_t flashSector = 0;

    Bus(CPU& cpu): cpu(cpu), rsp(*this), audioInterface(*this), rdp(*this), pif(*this) {
        // reserve is needed to ensure rdram is aligned for use with parallel-rdp
        rdram.reserve(0x800000);
        rdram.resize(0x800000);
        rdram9.reserve(0x800000);
        rdram9.resize(0x800000);

        tlbReadLut.resize(0x100000);
        tlbWriteLut.resize(0x100000);

        consoleBuffer.resize(0x10000);

        rsp.status.value = 1;

        for (int i = 0; i < icache.size(); i++) {
            icache[i].index = (uint16_t)(i << 5) & 0xfe0;
        }
        for (int i = 0; i < dcache.size(); i++) {
            dcache[i].index = (uint16_t)(i << 4) & 0xff0;
        }

        // set rdram size in rdram itself as part of initialization
        uint32_t rdramSize = (uint32_t)rdram.size();

        memcpy(&rdram[0x318], &rdramSize, sizeof(uint32_t));
        memcpy(&rdram[0x3f0], &rdramSize, sizeof(uint32_t));
    };

    PIF pif;

    std::vector<uint8_t> cartridge = {};

    std::array<ICache, 512> icache;
    std::array<DCache, 512> dcache;

    PeripheralInterface peripheralInterface;
    RDPInterface rdp;
    AudioInterface audioInterface;
    VideoInterface videoInterface;

    SerialInterface serialInterface;

    RDInterface rdInterface;

    MIPSInterface mips;

    SDL_AudioStream* stream;

    uint64_t memRead64(uint64_t address, bool cached);
    uint32_t memRead32(uint64_t address, bool cached, Width bitWidth = Bit32, bool ignoreCycles = false);
    uint16_t memRead16(uint64_t address, bool cached);
    uint8_t memRead8(uint64_t address, bool cached);

    uint32_t readDataCache(uint64_t address, bool ignoreCycles = false);
    uint32_t readInstructionCache(uint64_t address);

    void formatEeprom();
    void loadRom(std::string filename);
    void loadRomBytes(uint8_t* romBytes, uint32_t romSize);
    void openSaves(std::vector<std::string> saveNames);
    void writeSave();
    std::vector<std::string> getSaveNames(std::string filename);

    void writeDataCache(uint64_t address, uint32_t value, int64_t mask = -1);
    bool dcacheHit(uint32_t lineIndex, uint64_t address);
    bool icacheHit(uint32_t lineIndex, uint64_t address);
    void fillDataCache(uint32_t lineIndex, uint64_t address, bool ignoreCycles = false);
    void fillInstructionCache(uint32_t lineIndex, uint64_t address);
    void dcacheWriteback(uint64_t line, bool ignoreCycles = false);

    void memWrite64(uint64_t address, uint64_t value, bool cached, uint64_t mask = 0xffffffffffffffff);
    void memWrite32(uint64_t address, uint32_t value, bool cached, bool ignoreCache = false, int64_t mask = -1);
    void memWrite16(uint64_t address, uint16_t value, bool cached);
    void memWrite8(uint64_t address, uint8_t value, bool cached);

    void pushSamples(uint64_t length, uint64_t dramAddress);

    void setInterrupt(uint32_t flag);
    void clearInterrupt(uint32_t flag);

    void dmaFlashWrite();
    void dmaFlashRead();
    void dmaSramWrite();
    void dmaSramRead();
    void dmaCartWrite();
    void handleRspDma(SPDma dma);

    void checkIrqs();

    void tlbRead(uint32_t index);
    void tlbWrite(uint32_t index);
    void tlbMap(uint32_t index);
    void tlbUnmap(uint32_t index);
    void tlbProbe();

    void recalculateDelay();
    void finishPiDma();

    void initAudio();
    void restartAudio();

    void updateButton(JoypadButton button, bool state);
    void updateAxis(uint8_t xAxis, uint8_t yAxis);

    std::tuple<uint64_t, bool, bool> translateAddress(uint64_t address, bool isWrite = false);
    std::tuple<uint64_t, bool, bool> getTlbAddress(uint64_t address, bool isWrite = false);

    std::string sha256();
    void setCic();

    void formatSram();
    void formatFlash();
    void executeFlashCommand(uint32_t command);

    void tlbException(uint64_t address, bool isWrite);

    void writeRumblePak(int channel, uint16_t address, int data);

    void initRdp(SDL_Window* window);

    static void writeValueLE(uint8_t* ptr, uint32_t value, int size);
    static void writeWord(uint8_t* ptr, uint32_t value);
    static void writeHalf(uint8_t* ptr, uint16_t value);
    static void writeDoubleWord(uint8_t* ptr, uint64_t value);
    static uint32_t calculateRdRamCycles(uint32_t length);

    static void writeWithMask32(uint32_t* oldVal, uint32_t newVal, uint32_t mask);
};
