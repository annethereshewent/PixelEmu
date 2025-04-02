#pragma once

#include <cstdint>
#include "SPStatus.hpp"
#include "SPLength.hpp"
#include "DmaDirection.hpp"
#include <unordered_map>
#include <array>
#include <vector>

const uint32_t NUM_RSP_REGISTERS = 8;

enum InstructionType {
    Scalar,
    Vector
};

class SPDma {
public:
    DmaDirection direction = DmaDirection::Read;
    SPLength length;
    uint32_t dramAddress = 0;
    uint32_t memAddress = 0;
};

class Bus;

class RSP;

typedef void (*RSPInstruction)(RSP* rsp, uint32_t instruction);


class RSP {
public:
    SPStatus status;

    InstructionType lastInstructionType = Scalar;
    InstructionType instructionType = Scalar;

    bool pipelineFull = false;
    bool runAfterDma = false;

    uint32_t previousPc = 0;
    uint32_t pc = 0;
    uint32_t nextPc = 0;

    uint32_t semaphore;

    Bus& bus;

    std::array<uint16_t, 512> reciprocals = {};
    std::array<uint16_t, 512> inverseSquareRoots = {};

    std::unordered_map<uint32_t, std::vector<uint32_t>> found;

    RSP(Bus& bus) : bus(bus) {
        // gotten from https://github.com/hulkholden/n64js/blob/master/src/rsp.js#L147
        vecSelect = {
            0x76543210, // None
            0x76543210, // None
            0x66442200, // 0q
            0x77553311, // 1q
            0x44440000, // 0h
            0x55551111, // 1h
            0x66662222, // 2h
            0x77773333, // 3h
            0x00000000, // 0
            0x11111111, // 1
            0x22222222, // 2
            0x33333333, // 3
            0x44444444, // 4
            0x55555555, // 5
            0x66666666, // 6
            0x77777777  // 7
        };

        instructions = {
            RSP::reserved,
            RSP::reserved,
            RSP::j,
            RSP::jal,
            RSP::beq,
            RSP::bne,
            RSP::blez,
            RSP::bgtz,
            RSP::addi,
            RSP::addiu,
            RSP::slti,
            RSP::sltiu,
            RSP::andi,
            RSP::ori,
            RSP::xori,
            RSP::lui,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::lb,
            RSP::lh,
            RSP::reserved,
            RSP::lw,
            RSP::lbu,
            RSP::lhu,
            RSP::reserved,
            RSP::lwu,
            RSP::sb,
            RSP::sh,
            RSP::reserved,
            RSP::sw,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
        };

        secondary = {
            RSP::sll,
            RSP::reserved,
            RSP::srl,
            RSP::sra,
            RSP::sllv,
            RSP::reserved,
            RSP::srlv,
            RSP::srav,
            RSP::jr,
            RSP::jalr,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::break_,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::add,
            RSP::addu,
            RSP::sub,
            RSP::subu,
            RSP::and_,
            RSP::or_,
            RSP::xor_,
            RSP::nor,
            RSP::reserved,
            RSP::reserved,
            RSP::slt,
            RSP::sltu,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
            RSP::reserved,
        };

        lwc2 = {
            RSP::lbv,
            RSP::lsv,
            RSP::llv,
            RSP::ldv,
            RSP::lqv,
            RSP::lrv,
            RSP::lpv,
            RSP::luv,
            RSP::lhv,
            RSP::lfv,
            RSP::lwv,
            RSP::ltv,
        };
        swc2 = {
            RSP::sbv,
            RSP::ssv,
            RSP::slv,
            RSP::sdv,
            RSP::sqv,
            RSP::srv,
            RSP::spv,
            RSP::suv,
            RSP::shv,
            RSP::sfv,
            RSP::swv,
            RSP::stv
        };

        vecInstructions = {
            RSP::vmulf,
            RSP::vmulu,
            RSP::vrndp,
            RSP::vmulq,
            RSP::vmudl,
            RSP::vmudm,
            RSP::vmudn,
            RSP::vmudh,
            RSP::vmacf,
            RSP::vmacu,
            RSP::vrndn,
            RSP::vmacq,
            RSP::vmadl,
            RSP::vmadm,
            RSP::vmadn,
            RSP::vmadh,
            RSP::vadd,
            RSP::vsub,
            RSP::vzero,
            RSP::vabs,
            RSP::vaddc,
            RSP::vsubc,
            RSP::vzero,
            RSP::vzero,
            RSP::vzero,
            RSP::vzero,
            RSP::vzero,
            RSP::vzero,
            RSP::vzero,
            RSP::vsar,
            RSP::vzero,
            RSP::vzero,
            RSP::vlt,
            RSP::veq,
            RSP::vne,
            RSP::vge,
            RSP::vcl,
            RSP::vch,
            RSP::vcr,
            RSP::vmrg,
            RSP::vand,
            RSP::vnand,
            RSP::vor,
            RSP::vnor,
            RSP::vxor,
            RSP::vnxor,
            RSP::vzero,
            RSP::vzero,
            RSP::vrcp,
            RSP::vrcpl,
            RSP::vrcph,
            RSP::vmov,
            RSP::vrsq,
            RSP::vrsql,
            RSP::vrsqh,
            RSP::vnop,
            RSP::vzero,
            RSP::vzero,
            RSP::vzero,
            RSP::vzero,
            RSP::vzero,
            RSP::vzero,
            RSP::vzero,
            RSP::vnop,
        };

        reciprocals[0] = 0xffff;

        for (uint64_t i = 1; i < reciprocals.size(); i++) {
            uint64_t numerator = (uint64_t)1 << 34;
            uint64_t denominator = i + 512;

            uint64_t fraction = numerator / denominator;

            reciprocals[i] = (uint16_t)((fraction + 1) >> 8);
        }

        for (uint64_t i = 0; i < inverseSquareRoots.size(); i++) {
            uint64_t shift = 0;
            if ((i & 1) == 1) {
                shift = 1;
            }

            uint64_t a = (i + 512) >> shift;
            uint64_t b = 1 << 17;
            uint64_t c = (uint64_t)1 << 44;

            while (a * (b + 1) * (b + 1) < c) {
                b++;
            }

            inverseSquareRoots[i] = (uint16_t)(b >> 1);
        }
    };

    std::array<uint32_t, 32> r = {};
    std::array<std::array<uint8_t, 16>, 32> vpr = {};

    uint16_t vco = 0;
    uint16_t vcc = 0;
    uint8_t vce = 0;

    bool divDp = false;
    int16_t divIn = 0;
    int16_t divOut = 0;

    std::array<uint8_t, 16> accLo = {};
    std::array<uint8_t, 16> accMid = {};
    std::array<uint8_t, 16> accHi = {};

    std::array<uint32_t, 16> vecSelect;

    bool cpuHalted = false;
    bool cpuBroken = false;
    bool isRunning = false;
    bool inDelaySlot = false;

    uint64_t cycleCounter = 0;

    uint32_t lastStatus = 0;

    uint32_t dmaMemAddress = 0;
    uint32_t dmaRamAddress = 0;
    SPLength spReadLength;
    SPLength spWriteLength;

    std::array<SPDma, 2> fifo;

    std::array<uint8_t, 0x1000> imem = {};
    std::array<uint8_t, 0x1000> dmem = {};

    std::array<RSPInstruction, 64> instructions = {};
    std::array<RSPInstruction, 64> secondary = {};
    std::array<RSPInstruction, 12> lwc2 = {};
    std::array<RSPInstruction, 12> swc2 = {};
    std::array<RSPInstruction, 64> vecInstructions = {};

    static uint16_t getAccumulator16(uint8_t* ptr);

    uint8_t memRead8(uint32_t address);
    uint16_t memRead16(uint32_t address);
    // this one uses a ptr because need to read from either imem or dmem, other methods just read from dmem
    uint32_t memRead32(uint8_t* ptr);
    void memWrite32(uint32_t address, uint32_t value);
    void memWrite16(uint32_t address, uint16_t value);
    void memWrite8(uint32_t address, uint8_t value);

    void handleDma(SPDma dma);

    void pushDma(DmaDirection direction);
    void popDma();

    void updateStatus(uint32_t value);
    uint64_t runRsp();
    void startRsp();
    void restartRsp();

    void setVec8(uint8_t vt, uint8_t velement, uint8_t value);
    void setVec16UnalignedNoWrap(uint8_t vt, uint8_t velement, uint16_t value);
    uint8_t getVec8(uint8_t vt, uint8_t velement);
    uint16_t getVec16(uint8_t vt, uint8_t element);
    void setVec16(uint8_t vt, uint8_t element, uint16_t value);

    void updateAccumulatorMid32(int element, int32_t result, bool accumulate);
    void updateAccumulatorHiLo(int element, int32_t v1, int32_t result, bool accumulate);
    void updateAccumulatorLow32(int element, uint32_t result, bool accumulate);
    void updateAccumulatorHigh32(int element, int32_t result, bool accumulate);

    void setAccumulatorFromVector(uint8_t vd, uint8_t vt, uint8_t vte);

    void setVecFromAccLow(uint8_t vd);
    void setVecFromAccSignedMid(uint8_t vd);
    void setVecFromAccSignedLow(uint8_t vd);
    void setVecFromAccMid(uint8_t vd);
    void setVecFromAccUnsignedMid(uint8_t vd);

    void writeAcc32(uint8_t* ptr, int upperOffset, uint32_t value, bool isLo);

    uint32_t readRegisters(uint32_t offset);
    void writeRegisters(uint32_t offset, uint32_t value);

    static void reserved(RSP* rsp, uint32_t instruction);
    static void j(RSP* rsp, uint32_t instruction);
    static void jal(RSP* rsp, uint32_t instruction);
    static void beq(RSP* rsp, uint32_t instruction);
    static void bne(RSP* rsp, uint32_t instruction);
    static void blez(RSP* rsp, uint32_t instruction);
    static void bgtz(RSP* rsp, uint32_t instruction);
    static void addi(RSP* rsp, uint32_t instruction);
    static void addiu(RSP* rsp, uint32_t instruction);
    static void slti(RSP* rsp, uint32_t instruction);
    static void sltiu(RSP* rsp, uint32_t instruction);
    static void andi(RSP* rsp, uint32_t instruction);
    static void xori(RSP* rsp, uint32_t instruction);
    static void ori(RSP* rsp, uint32_t instruction);
    static void lui(RSP* rsp, uint32_t instruction);
    static void lb(RSP* rsp, uint32_t instruction);
    static void lh(RSP* rsp, uint32_t instruction);
    static void lw(RSP* rsp, uint32_t instruction);
    static void lbu(RSP* rsp, uint32_t instruction);
    static void lhu(RSP* rsp, uint32_t instruction);
    static void lwu(RSP* rsp, uint32_t instruction);
    static void sb(RSP* rsp, uint32_t instruction);
    static void sh(RSP* rsp, uint32_t instruction);
    static void sw(RSP* rsp, uint32_t instruction);

    static void sll(RSP* rsp, uint32_t instruction);
    static void srl(RSP* rsp, uint32_t instruction);
    static void sra(RSP* rsp, uint32_t instruction);
    static void sllv(RSP* rsp, uint32_t instruction);
    static void srlv(RSP* rsp, uint32_t instruction);
    static void srav(RSP* rsp, uint32_t instruction);
    static void jr(RSP* rsp, uint32_t instruction);
    static void jalr(RSP* rsp, uint32_t instruction);
    static void break_(RSP* rsp, uint32_t instruction);
    static void add(RSP* rsp, uint32_t instruction);
    static void addu(RSP* rsp, uint32_t instruction);
    static void sub(RSP* rsp, uint32_t instruction);
    static void subu(RSP* rsp, uint32_t instruction);
    static void and_(RSP* rsp, uint32_t instruction);
    static void or_(RSP* rsp, uint32_t instruction);
    static void xor_(RSP* rsp, uint32_t instruction);
    static void nor(RSP* rsp, uint32_t instruction);
    static void slt(RSP* rsp, uint32_t instruction);
    static void sltu(RSP* rsp, uint32_t instruction);

    static void mfc0(RSP* rsp, uint32_t instruction);
    static void mtc0(RSP* rsp, uint32_t instruction);

    static void lbv(RSP* rsp, uint32_t instruction);
    static void lsv(RSP* rsp, uint32_t instruction);
    static void llv(RSP* rsp, uint32_t instruction);
    static void ldv(RSP* rsp, uint32_t instruction);
    static void lqv(RSP* rsp, uint32_t instruction);
    static void lrv(RSP* rsp, uint32_t instruction);
    static void lpv(RSP* rsp, uint32_t instruction);
    static void luv(RSP* rsp, uint32_t instruction);
    static void lhv(RSP* rsp, uint32_t instruction);
    static void lfv(RSP* rsp, uint32_t instruction);
    static void lwv(RSP* rsp, uint32_t instruction);
    static void ltv(RSP* rsp, uint32_t instruction);

    static void sbv(RSP* rsp, uint32_t instruction);
    static void ssv(RSP* rsp, uint32_t instruction);
    static void slv(RSP* rsp, uint32_t instruction);
    static void sdv(RSP* rsp, uint32_t instruction);
    static void sqv(RSP* rsp, uint32_t instruction);
    static void srv(RSP* rsp, uint32_t instruction);
    static void spv(RSP* rsp, uint32_t instruction);
    static void suv(RSP* rsp, uint32_t instruction);
    static void shv(RSP* rsp, uint32_t instruction);
    static void sfv(RSP* rsp, uint32_t instruction);
    static void swv(RSP* rsp, uint32_t instruction);
    static void stv(RSP* rsp, uint32_t instruction);

    static void mtc2(RSP* rsp, uint32_t instruction);
    static void ctc2(RSP* rsp, uint32_t instruction);
    static void mfc2(RSP* rsp, uint32_t instruction);
    static void cfc2(RSP* rsp, uint32_t instruction);

    static void vmulf(RSP* rsp, uint32_t instruction);
    static void vmulu(RSP* rsp, uint32_t instruction);
    static void vrndp(RSP* rsp, uint32_t instruction);
    static void vmulq(RSP* rsp, uint32_t instruction);
    static void vmudl(RSP* rsp, uint32_t instruction);
    static void vmudm(RSP* rsp, uint32_t instruction);
    static void vmudn(RSP* rsp, uint32_t instruction);
    static void vmudh(RSP* rsp, uint32_t instruction);
    static void vmacf(RSP* rsp, uint32_t instruction);
    static void vmacu(RSP* rsp, uint32_t instruction);
    static void vrndn(RSP* rsp, uint32_t instruction);
    static void vmacq(RSP* rsp, uint32_t instruction);
    static void vmadl(RSP* rsp, uint32_t instruction);
    static void vmadm(RSP* rsp, uint32_t instruction);
    static void vmadn(RSP* rsp, uint32_t instruction);
    static void vmadh(RSP* rsp, uint32_t instruction);
    static void vadd(RSP* rsp, uint32_t instruction);
    static void vsub(RSP* rsp, uint32_t instruction);
    static void vzero(RSP* rsp, uint32_t instruction);
    static void vabs(RSP* rsp, uint32_t instruction);
    static void vaddc(RSP* rsp, uint32_t instruction);
    static void vsubc(RSP* rsp, uint32_t instruction);
    static void vsar(RSP* rsp, uint32_t instruction);
    static void vlt(RSP* rsp, uint32_t instruction);
    static void veq(RSP* rsp, uint32_t instruction);
    static void vne(RSP* rsp, uint32_t instruction);
    static void vge(RSP* rsp, uint32_t instruction);
    static void vcl(RSP* rsp, uint32_t instruction);
    static void vch(RSP* rsp, uint32_t instruction);
    static void vcr(RSP* rsp, uint32_t instruction);
    static void vmrg(RSP* rsp, uint32_t instruction);
    static void vand(RSP* rsp, uint32_t instruction);
    static void vnand(RSP* rsp, uint32_t instruction);
    static void vor(RSP* rsp, uint32_t instruction);
    static void vnor(RSP* rsp, uint32_t instruction);
    static void vxor(RSP* rsp, uint32_t instruction);
    static void vnxor(RSP* rsp, uint32_t instruction);
    static void vrcp(RSP* rsp, uint32_t instruction);
    static void vrcpl(RSP* rsp, uint32_t instruction);
    static void vrcph(RSP* rsp, uint32_t instruction);
    static void vmov(RSP* rsp, uint32_t instruction);
    static void vrsq(RSP* rsp, uint32_t instruction);
    static void vrsql(RSP* rsp, uint32_t instruction);
    static void vrsqh(RSP* rsp, uint32_t instruction);
    static void vnop(RSP* rsp, uint32_t instruction);
    static void bgezal(RSP* rsp, uint32_t instruction);
    static void bltzal(RSP* rsp, uint32_t instruction);
    static void bltz(RSP* rsp, uint32_t instruction);
    static void bgez(RSP* rsp, uint32_t instruction);

    static void vectorMultiplyFractions(RSP* rsp, uint32_t instruction, bool accumulate, int32_t round);
    static void vectorMultiplyPartialLow(RSP* rsp, uint32_t instruction, bool accumulate);
    static void vectorMultiplyPartialHigh(RSP* rsp, uint32_t instruction, bool accumulate);
    static void vectorMulPartialMidM(RSP* rsp, uint32_t instruction, bool accumulate);
    static void vectorMultiplyPartialMidN(RSP* rsp, uint32_t instruction, bool accumulate);
    static void vectorLogicalOp(RSP* rsp, uint32_t instruction, auto fn);
    static void vectorCalculateReciprocal(RSP* rsp, uint32_t instruction, bool useDp, bool inverseSquareRoot);

    static void vectorSetAccumulatorFromRegister(RSP* rsp, uint32_t instruction);

    static int32_t getVOffset(uint32_t instruction);
    static uint8_t getVElement(uint32_t instruction);
    static uint8_t getVt(uint32_t instruction);
    static uint8_t getVs(uint32_t instruction);
    static uint8_t getVte(uint32_t instruction);
    static uint8_t getVd(uint32_t instruction);
    static uint8_t getDe(uint32_t instruction);
};
