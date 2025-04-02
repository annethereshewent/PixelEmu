#pragma once

#include <vector>
#include <cstdint>
#include "CPUInstruction.hpp"
#include "Cop0Status.hpp"

typedef union FCSR {
    struct {
        unsigned int roundingMode: 2;
        unsigned int flagInexact: 1;
        unsigned int flagUnderflow: 1;
        unsigned int flagOverflow: 1;
        unsigned int flagDivisionByZero: 1;
        unsigned int flagInvalidOp: 1;
        unsigned int inexactOperationEnable: 1;
        unsigned int underflowEnable: 1;
        unsigned int overflowEnable: 1;
        unsigned int divisionByZeroEnable: 1;
        unsigned int invalidOpEnable: 1;
        unsigned int causeUnderflow: 1;
        unsigned int causeOverflow: 1;
        unsigned int causeDivisionByZero: 1;
        unsigned int causeInvalidOp: 1;
        unsigned int caseUnimplemented: 1;
        unsigned int unused: 5;
        unsigned int condition: 1;
        unsigned int flushDenormToZero: 1;
    };

    uint32_t value = 0;
} fcsrbitset;

// gotten from https://stackoverflow.com/questions/11611787/convert-a-32-bits-to-float-value
union convu32 {
    uint32_t u32; // here_write_bits
    float    f32; // here_read_float
};

union convi32 {
    int32_t i32; // here_write_bits
    float   f32; // here_read_float
};

union convu64 {
    uint64_t u64;
    double f64;
};
union convi64 {
    int64_t i64;
    double f64;
};

class CPU;

class COP1 {
public:
    FCSR fcsr;

    std::array<uint32_t, 32> fgr32 = {};
    std::array<uint64_t, 32> fgr64 = {};

    std::array<CPUInstruction, 32> instructions;
    std::array<CPUInstruction, 64> sInstructions;
    std::array<CPUInstruction, 4> bInstructions;
    std::array<CPUInstruction, 64> dInstructions;

    CPU& cpu;

    COP1(CPU& cpu);

    float getFloat(uint32_t index);
    double getDouble(uint32_t index);

    void setFloat(uint32_t index, float value);
    void setDouble(uint32_t index, double value);

    static void reserved(CPU* cpu, uint32_t instruction);
    static void lwc1(CPU* cpu, uint32_t instruction);
    static void ldc1(CPU* cpu, uint32_t instruction);
    static void swc1(CPU* cpu, uint32_t instruction);
    static void sdc1(CPU* cpu, uint32_t instruction);

    static void mfc1(CPU* cpu, uint32_t instructon);
    static void dmfc1(CPU* cpu, uint32_t instructon);
    static void cfc1(CPU* cpu, uint32_t instructon);
    static void dcfc1(CPU* cpu, uint32_t instructon);
    static void mtc1(CPU* cpu, uint32_t instructon);
    static void dmtc1(CPU* cpu, uint32_t instructon);
    static void ctc1(CPU* cpu, uint32_t instructon);
    static void dctc1(CPU* cpu, uint32_t instructon);

    // TODO: rename these to camel case
    static void cop1_b_instrs(CPU* cpu, uint32_t instructon);
    static void cop1_s_instrs(CPU* cpu, uint32_t instructon);
    static void cop1_d_instrs(CPU* cpu, uint32_t instructon);
    static void cop1_w_instrs(CPU* cpu, uint32_t instructon);
    static void cop1_l_instrs(CPU* cpu, uint32_t instructon);

    static void cvtSW(CPU* cpu, uint32_t instruction);
    static void cvtDW(CPU* cpu, uint32_t instruction);

    static void addS(CPU* cpu, uint32_t instruction);
    static void subS(CPU* cpu, uint32_t instruction);
    static void mulS(CPU* cpu, uint32_t instruction);
    static void divS(CPU* cpu, uint32_t instruction);
    static void sqrtS(CPU* cpu, uint32_t instruction);
    static void absS(CPU* cpu, uint32_t instruction);
    static void movS(CPU* cpu, uint32_t instruction);
    static void negS(CPU* cpu, uint32_t instruction);
    static void roundLS(CPU* cpu, uint32_t instruction);
    static void truncLS(CPU* cpu, uint32_t instruction);
    static void ceilLS(CPU* cpu, uint32_t instruction);
    static void floorLS(CPU* cpu, uint32_t instruction);
    static void roundWS(CPU* cpu, uint32_t instruction);
    static void truncWS(CPU* cpu, uint32_t instruction);
    static void ceilWS(CPU* cpu, uint32_t instruction);
    static void floorWS(CPU* cpu, uint32_t instruction);
    static void cvtDS(CPU* cpu, uint32_t instruction);
    static void cvtWS(CPU* cpu, uint32_t instruction);
    static void cvtLS(CPU* cpu, uint32_t instruction);
    static void CFS(CPU* cpu, uint32_t instruction);
    static void cUnS(CPU* cpu, uint32_t instruction);
    static void cEqS(CPU* cpu, uint32_t instruction);
    static void cUeqS(CPU* cpu, uint32_t instruction);
    static void cOltS(CPU* cpu, uint32_t instruction);
    static void cUltS(CPU* cpu, uint32_t instruction);
    static void cOleS(CPU* cpu, uint32_t instruction);
    static void cUleS(CPU* cpu, uint32_t instruction);
    static void cSfS(CPU* cpu, uint32_t instruction);
    static void cNgleS(CPU* cpu, uint32_t instruction);
    static void cSeqS(CPU* cpu, uint32_t instruction);
    static void cNglS(CPU* cpu, uint32_t instruction);
    static void cLtS(CPU* cpu, uint32_t instruction);
    static void cNgeS(CPU* cpu, uint32_t instruction);
    static void cLeS(CPU* cpu, uint32_t instruction);
    static void cNgtS(CPU* cpu, uint32_t instruction);

    static void bc1f(CPU* cpu, uint32_t instruction);
    static void bc1t(CPU* cpu, uint32_t instruction);
    static void bc1fl(CPU* cpu, uint32_t instruction);
    static void bc1tl(CPU* cpu, uint32_t instruction);

    static void addD(CPU* cpu, uint32_t instruction);
    static void subD(CPU* cpu, uint32_t instruction);
    static void mulD(CPU* cpu, uint32_t instruction);
    static void divD(CPU* cpu, uint32_t instruction);
    static void sqrtD(CPU* cpu, uint32_t instruction);
    static void absD(CPU* cpu, uint32_t instruction);
    static void movD(CPU* cpu, uint32_t instruction);
    static void negD(CPU* cpu, uint32_t instruction);
    static void roundLD(CPU* cpu, uint32_t instruction);
    static void truncLD(CPU* cpu, uint32_t instruction);
    static void ceilLD(CPU* cpu, uint32_t instruction);
    static void floorLD(CPU* cpu, uint32_t instruction);
    static void roundWD(CPU* cpu, uint32_t instruction);
    static void truncWD(CPU* cpu, uint32_t instruction);
    static void ceilWD(CPU* cpu, uint32_t instruction);
    static void floorWD(CPU* cpu, uint32_t instruction);
    static void cvtSD(CPU* cpu, uint32_t instruction);
    static void cvtWD(CPU* cpu, uint32_t instruction);
    static void cvtLD(CPU* cpu, uint32_t instruction);
    static void cFD(CPU* cpu, uint32_t instruction);
    static void cUnD(CPU* cpu, uint32_t instruction);
    static void cEqD(CPU* cpu, uint32_t instruction);
    static void cUeqD(CPU* cpu, uint32_t instruction);
    static void cOltD(CPU* cpu, uint32_t instruction);
    static void cUltD(CPU* cpu, uint32_t instruction);
    static void cOleD(CPU* cpu, uint32_t instruction);
    static void cUleD(CPU* cpu, uint32_t instruction);
    static void cSfD(CPU* cpu, uint32_t instruction);
    static void cNgleD(CPU* cpu, uint32_t instruction);
    static void cSeqD(CPU* cpu, uint32_t instruction);
    static void cNglD(CPU* cpu, uint32_t instruction);
    static void cLtD(CPU* cpu, uint32_t instruction);
    static void cNgeD(CPU* cpu, uint32_t instruction);
    static void cLeD(CPU* cpu, uint32_t instruction);
    static void cNgtD(CPU* cpu, uint32_t instruction);

    static void cvtSL(CPU* cpu, uint32_t instruction);
    static void cvtDL(CPU* cpu, uint32_t instruction);

    void writeRegister(uint32_t index, uint64_t value);
    void setCop1Registers(Cop0Status cop0Status);
    uint32_t readRegister(uint32_t index);
};
