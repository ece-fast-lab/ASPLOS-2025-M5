#ifndef ALGO_H
#define ALGO_H
#include <iostream>
#include <thread>
#include <vector>
#include <fstream>
#include <mutex>
#include <condition_variable>
#include <chrono>
#include <queue>
#include <csignal>
#include <atomic>
#include <chrono>
#include <cstdint>
#include <iomanip>
#include <unordered_map>
#include <map>

using std::vector;
using std::thread;
using std::cout;
using std::endl;
using std::cerr;
using std::string;
using std::ofstream;
using std::unique_lock;
using std::mutex;
using std::shared_ptr;
using std::condition_variable;
using std::unordered_map;
using std::pair;

class Selection {
protected:
    int num_hist;
public: 
    Selection(int hist) : num_hist(hist) {}
    virtual void insert_new_pfn(unordered_map<uint64_t, uint64_t>& migration_pfn) = 0;
};

class Repetition : public Selection {
    private:
        vector<unordered_map<uint64_t, uint64_t>> hist_map;
        uint64_t iter_cnt; 
        int repetition_threshold;
        void selection_simple(unordered_map<uint64_t, uint64_t>& migration_pfn, uint64_t pfn);
        void selection_thresold(unordered_map<uint64_t, uint64_t>& migration_pfn, uint64_t pfn);
    public:
        Repetition(int hist); 
        Repetition(int hist, int repetition_threshold); 
        virtual void insert_new_pfn(unordered_map<uint64_t, uint64_t>& migration_pfn) override;
};


class PID : public Selection {
    public:
        enum score_mode
        {
            SCORE_GLOBAL,
            SCORE_LOCAL,
        };

        PID(int hist_len, int p_weight, int i_weight, int d_weight, int threshold, score_mode mode);
        virtual void insert_new_pfn(unordered_map<uint64_t, uint64_t>& migration_pfn) override;

    private:
        struct hist_record
        {
            uint64_t version;
            uint64_t histbits;
        };

        // <pfn, hist>
        unordered_map<uint64_t, hist_record> hist_map;
        uint64_t hist_cnt;
        uint64_t hist_ver;
        int p_score, i_score, d_score, thres;
        score_mode scorer;

        void selection_simple(unordered_map<uint64_t, uint64_t>& migration_pfn, int arr_idx);
        void pfn_scoring_global(unordered_map<uint64_t, uint64_t>& migration_pfn, std::map<uint64_t, std::deque<uint64_t>>& bucket_sorter);
        void pfn_scoring_local(unordered_map<uint64_t, uint64_t>& migration_pfn, std::map<uint64_t, std::deque<uint64_t>>& bucket_sorter);
};

class Filter : public Selection {
    public:
        Filter(int hist);
        virtual void insert_new_pfn(unordered_map<uint64_t, uint64_t>& migration_pfn) override;
    private:
        int num_min;
};

class HWT: public Selection {
    public:
        HWT(int hist);
        virtual void insert_new_pfn(unordered_map<uint64_t, uint64_t>& migration_pfn) override;
    private:
        int bit_min;
};

class Pass : public Selection {
    public:
        Pass(int hist);
        virtual void insert_new_pfn(unordered_map<uint64_t, uint64_t>& migration_pfn) override;
};
#endif // ALGO_H
