#pragma once
namespace base_types {
enum class JOBTYPE : uint8_t {
    INVALID = 0,
    FORAGER = 1,
    FARMER = 2,
    LABOURER = 3,
    ARTISAN = 4,
    CLERK = 5,
    WARRIOR = 6,
    HAULING = 7,
    HUNTING = 8,
};

enum class NEED : uint8_t {
    INVALID = 0,
    FOOD = 1,
    TOOLS = 2,
    CONTAINER = 3,
    CLOTHING = 4,
    FURNITURE = 5,
    HEALTHCARE = 6,
    LUXURY = 7,
};

enum class CHARACTER_RANK : uint8_t {
    INVALID = 0,
    POP = 1,
    NOBLE = 2,
    CHIEF = 3,
};

enum class TRAIT : uint8_t {
    INVALID = 0,
    AMBITIOUS = 1,
    CONTENT = 2,
    LOYAL = 3,
    GREEDY = 4,
    WARLIKE = 5,
    BAD_ORGANISER = 6,
    GOOD_ORGANISER = 7,
    LAZY = 8,
    HARDWORKER = 9,
    TRADER = 10,
};

enum class TRADE_GOOD_CATEGORY : uint8_t {
    INVALID = 0,
    GOOD = 1,
    SERVICE = 2,
    CAPACITY = 3,
};

enum class WARBAND_STATUS : uint8_t {
    INVALID = 0,
    IDLE = 1,
    RAIDING = 2,
    PREPARING_RAID = 3,
    PREPARING_PATROL = 4,
    PATROL = 5,
    ATTACKING = 6,
    TRAVELLING = 7,
    OFF_DUTY = 8,
};

enum class WARBAND_STANCE : uint8_t {
    INVALID = 0,
    WORK = 1,
    FORAGE = 2,
};

enum class BUILDING_ARCHETYPE : uint8_t {
    INVALID = 0,
    GROUNDS = 1,
    FARM = 2,
    MINE = 3,
    WORKSHOP = 4,
    DEFENSE = 5,
};

enum class FORAGE_RESOURCE : uint8_t {
    INVALID = 0,
    WATER = 1,
    FRUIT = 2,
    GRAIN = 3,
    GAME = 4,
    FUNGI = 5,
    SHELL = 6,
    FISH = 7,
    WOOD = 8,
};

enum class BUDGET_CATEGORY : uint8_t {
    INVALID = 0,
    EDUCATION = 1,
    COURT = 2,
    INFRASTRUCTURE = 3,
    MILITARY = 4,
    TRIBUTE = 5,
};

enum class ECONOMY_REASON : uint8_t {
    INVALID = 0,
    BASIC_NEEDS = 1,
    WELFARE = 2,
    RAID = 3,
    DONATION = 4,
    MONTHLY_CHANGE = 5,
    YEARLY_CHANGE = 6,
    INFRASTRUCTURE = 7,
    EDUCATION = 8,
    COURT = 9,
    MILITARY = 10,
    EXPLORATION = 11,
    UPKEEP = 12,
    NEW_MONTH = 13,
    LOYALTY_GIFT = 14,
    BUILDING = 15,
    BUILDING_INCOME = 16,
    TREASURY = 17,
    BUDGET = 18,
    WASTE = 19,
    TRIBUTE = 20,
    INHERITANCE = 21,
    TRADE = 22,
    WARBAND = 23,
    WATER = 24,
    FOOD = 25,
    OTHER_NEEDS = 26,
    FORAGE = 27,
    WORK = 28,
    OTHER = 29,
    SIPHON = 30,
    TRADE_SIPHON = 31,
    QUEST = 32,
    NEIGHBOR_SIPHON = 33,
    COLONISATION = 34,
    TAX = 35,
    NEGOTIATIONS = 36,
};

enum class POLITICS_REASON : uint8_t {
    INVALID = 0,
    NOTENOUGHNOBLES = 1,
    INITIALNOBLE = 2,
    POPULATIONGROWTH = 3,
    EXPEDITIONLEADER = 4,
    SUCCESSION = 5,
    COUP = 6,
    INITIALRULER = 7,
    OTHER = 8,
};

enum class LAW_TRADE : uint8_t {
    INVALID = 0,
    NO_REGULATION = 1,
    LOCALS_ONLY = 2,
    PERMISSION_ONLY = 3,
};

enum class LAW_BUILDING : uint8_t {
    INVALID = 0,
    NO_REGULATION = 1,
    LOCALS_ONLY = 2,
    PERMISSION_ONLY = 3,
};

    struct budget_per_category_data {
        float ratio;
        float budget;
        float to_be_invested;
        float target;
    };

    struct trade_good_container {
        dcon::trade_good_id good;
        float amount;
    };

    struct use_case_container {
        dcon::use_case_id use;
        float amount;
    };

    struct forage_container {
        dcon::trade_good_id output_good;
        float output_value;
        float amount;
        FORAGE_RESOURCE forage;
    };

    struct resource_location {
        dcon::resource_id resource;
        dcon::tile_id location;
    };

    struct need_satisfaction {
        NEED need;
        dcon::use_case_id use_case;
        float consumed;
        float demanded;
    };

    struct need_definition {
        NEED need;
        dcon::use_case_id use_case;
        float required;
    };

    struct job_container {
        dcon::job_id job;
        uint32_t amount;
    };

}