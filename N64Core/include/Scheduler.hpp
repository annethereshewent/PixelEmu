#pragma once

#include <cstdint>
#include <queue>
#include <vector>
#include <queue>

enum EventType {
    VideoInterrupt,
    PIFExecuteCommand,
    RspDmaPop,
    RunRspPc,
    PIDma,
    CompareCount,
    SIDma,
    AIDma,
    RDPEvent,
    NoEvent
};

class Event {
public:
    uint64_t cycles;
    EventType eventType;

    Event(EventType eventType, uint64_t cycles) {
        this->eventType = eventType;
        this->cycles = cycles;
    };

    Event() {
        this->eventType = NoEvent;
        this->cycles = 0xffffffffffffffff;
    };

    std::string getEventName();
};

class Scheduler {
private:
    std::array<Event, 9> events = {};
    uint64_t timeToNextEvent = 0xffffffffffffffff;
    EventType nextEvent = NoEvent;
public:
    void addEvent(Event event);
    void removeEvent(EventType eventType);

    void updateNextEvent();

    bool hasNextEvent(uint64_t cycles);

    Event getNextEvent();

    void rebaseEvents(uint64_t oldCount, uint64_t newCount);
    uint64_t getTimeToNext();
    Event getEvent(EventType eventType);
};
