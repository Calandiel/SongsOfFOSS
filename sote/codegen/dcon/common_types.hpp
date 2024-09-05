namespace base_types {
    struct budget_per_category_data {
        float ratio;
        float budget;
        float to_be_invested;
        float target;
    };

    struct trade_good_container {
        uint32_t good;
        float amount;
    };

    struct use_case_container {
        uint32_t use;
        float amount;
    };

    struct forage_container {
        uint32_t output_good;
        float output_value;
        float amount;
        uint8_t forage;
    };

    struct resource_location {
        uint32_t resource;
        uint32_t location;
    };

    struct need_satisfaction {
        uint8_t need;
        uint32_t use_case;
        float consumed;
        float demanded;
    };

    struct need_definition {
        uint8_t need;
        uint32_t use_case;
        float required;
    };

    struct job_container {
        uint32_t job;
        uint32_t amount;
    };

}