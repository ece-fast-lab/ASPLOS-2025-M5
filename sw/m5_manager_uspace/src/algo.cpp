#include "algo.h"
#include "util.h"
#include "nmmintrin.h"

#define DO_SELECTION

Repetition::Repetition(int hist) : Selection(hist) {
    iter_cnt = 0;
    repetition_threshold = -1;
    hist_map.resize(hist);
}

Repetition::Repetition(int hist, int rep_thld) : Selection(hist) {
    iter_cnt = 0;
    repetition_threshold = rep_thld;
    hist_map.resize(hist);
}

// has to appear in all prev hist
void Repetition::selection_simple(unordered_map<uint64_t, uint64_t>& migration_pfn, uint64_t pfn) {
    uint64_t idx = iter_cnt % num_hist;

    for (int j = 0; j < num_hist; j++) {
        if (j == idx) continue;
        auto it = hist_map[j].find(pfn);
        if (it == hist_map[idx].end()) {
            // cleared not migrating this time
            migration_pfn[pfn] = -1;
            break;
        }
    }
}

void Repetition::selection_thresold(unordered_map<uint64_t, uint64_t>& migration_pfn, uint64_t pfn) {
    uint64_t idx = iter_cnt % num_hist;
    int sum = 0;

    for (int j = 0; j < num_hist; j++) {
        if (j == idx) continue;
        auto it = hist_map[j].find(pfn);
        if (it != hist_map[idx].end()) {
            sum += it->second; 
        }
    }

    if (sum < repetition_threshold) {
        migration_pfn[pfn] = -1;
    }
}

void Repetition::insert_new_pfn(unordered_map<uint64_t, uint64_t>& migration_pfn) {
    uint64_t idx = iter_cnt % num_hist;
    hist_map[idx].clear();

    for (const auto& pair : migration_pfn) {
        uint64_t pfn = pair.first;
        auto it = hist_map[idx].find(pfn);
        if (it == hist_map[idx].end()) {
            hist_map[idx][pfn] = 0;
        }
        hist_map[idx][pfn] += 1;

#ifdef DO_SELECTION
        // selection!
        if (repetition_threshold >= 0) {
            selection_thresold(migration_pfn, pfn);
        } else {
            selection_simple(migration_pfn, pfn);
        }
        // if the migration_pfn entry is not cleared
        //  migration will happen
#endif
    }
    iter_cnt++;
}

/**
 * PID-Selection
 *   @brief Initialize data structures for the PID selection algorithm.
 *   @param hist_len The number of history that we look back, must be less than 63 and considering overflow.
 *   @param p_weight The weight of P component, which detects the presence of PFN in most recent list.
 *   @param i_weight The weight of I component, which detects page usage history in historical lists.
 *   @param d_weight The weight of D component, which detects page activation (rising edges) in access pattern.
 *   @param threshold Cutoff percentage for promotion list (0-100). Only threshold% pages will be migrated for each input batch.
 *   @param mode PID scoring mode selection.
 *     SCORE_LOCAL only considers pages in current P list which is faster but less accurate.
 *     SCORE_GLOBAL considers the entire CXL device which may be slow.
 */
PID::PID(int hist_len, int p_weight, int i_weight, int d_weight, int threshold, score_mode mode) : Selection(hist_len)
{
    hist_cnt = hist_len;
    hist_ver = 0;
    p_score = p_weight;
    i_score = i_weight;
    d_score = d_weight;
    thres = threshold;
    scorer = mode;

    if (p_score < 0 || i_score < 0 || d_score < 0)
        throw std::invalid_argument("p/i/d_weight is smaller than zero");

    if (thres > 100)
        throw std::invalid_argument("threshold is above 100%");

    // d_score uses mul/div so need to be checked as well
    if (hist_cnt > 63 || std::max(p_score + i_score + d_score, d_score * 3) >= (~0ULL >> hist_cnt))
        throw std::invalid_argument("hist_len may overflow");

    if (scorer != SCORE_GLOBAL && mode != SCORE_LOCAL)
        throw std::invalid_argument("invalid mode");
}

/**
 * pfn_scoring_global
 *   @brief This function runs the PID scoring algorithm on all previously-touched CXL pages.
 *     It may be slow.
 */
void PID::pfn_scoring_global(unordered_map<uint64_t, uint64_t>& migration_pfn, std::map<uint64_t, std::deque<uint64_t>>& bucket_sorter)
{
    uint64_t curr_mask = 1ULL << hist_cnt;
    uint64_t hist_mask = curr_mask - 1;

    // Update map status
    for (const auto& pair : migration_pfn) {
        auto pfn = pair.first;
        auto& hist = hist_map[pfn];

        // Adjust hist bitmap
        hist.histbits >>= std::min((uint64_t)63, hist_ver - hist.version); // min() to avoid undefined behavior
        hist.version = hist_ver;

        // Trace current status
        hist.histbits |= curr_mask;
    }

    // Calculate score
    for (auto& rec : hist_map) {
        auto pfn = rec.first;
        auto& hist = rec.second;

        // Don't bother if the page is too inactive
        if (hist.version + hist_cnt < hist_ver)
            continue;

        // Adjust hist bitmap for records not in migration_pfn
        if (hist.version != hist_ver) {
            hist.histbits >>= std::min((uint64_t)63, hist_ver - hist.version);
            hist.version = hist_ver;
        }

        // Detect rising edge in histbits
        // It works as follows:
        //   raw = 0 1 0 0 1 1 0 0 0 1 1 1 0 input
        //   shl = 1 0 0 1 1 0 0 0 1 1 1 0 0 SHL(raw)
        //   xor = 1 1 0 1 0 1 0 0 1 0 0 1 0 XOR(raw, shl)
        //   ris = 0 1 0 0 0 1 0 0 0 0 0 1 0 AND(raw, xor)
        auto h = hist.histbits;
        auto rising = (h ^ (h << 1)) & h;

        // Calculate score
        auto score =
            p_score * (hist.histbits & curr_mask) + // give p * CURR if present, or 0 if otherwise
            i_score * (hist.histbits & hist_mask) + // give i * [0, CURR) based on history value
            d_score * rising * 3 / 4;               // give d * [0, CURR) based on history rising edge

        bucket_sorter[score].push_back(pfn);
    }
}

/**
 * pfn_scoring_global
 *   @brief This function runs the PID scoring algorithm on pages presented in migration_pfn.
 *     It may be less accurate.
 */
void PID::pfn_scoring_local(unordered_map<uint64_t, uint64_t>& migration_pfn, std::map<uint64_t, std::deque<uint64_t>>& bucket_sorter)
{
    uint64_t curr_mask = 1ULL << hist_cnt;
    uint64_t hist_mask = curr_mask - 1;

    // Update map status
    for (const auto& pair : migration_pfn) {
        auto pfn = pair.first;
        auto& hist = hist_map[pfn];

        // Adjust hist bitmap
        hist.histbits >>= std::min((uint64_t)63, hist_ver - hist.version); // min() to avoid undefined behavior
        hist.version = hist_ver;

        // Trace current status
        hist.histbits |= curr_mask;

        // Detect rising edge in histbits (see comments in pfn_scoring_global)
        auto h = hist.histbits;
        auto rising = (h ^ (h << 1)) & h;

        // Calculate score
        auto score =
            p_score * (hist.histbits & curr_mask) + // give p * CURR if present, or 0 if otherwise
            i_score * (hist.histbits & hist_mask) + // give i * [0, CURR) based on history value
            d_score * rising * 3 / 4;               // give d * [0, CURR) based on history rising edge

        bucket_sorter[score].push_back(pfn);
    }
}

/**
 * insert_new_pfn
 *   @brief This function takes in an array of pfn and modifies the entry such that,
 *      for each non zero entry of the array, the pfn is the target for page migration.
 *      The function should set the entry to 0 if it desires to skip the pfn.
 *   @param migration_pfn The array of pfn outputed by the FPGA hardware tracker.
 */
void PID::insert_new_pfn(unordered_map<uint64_t, uint64_t>& migration_pfn)
{
    // <score, <pfn>>
    std::map<uint64_t, std::deque<uint64_t>> bucket_sorter;

    // Run the PID scorer
    switch (scorer) {
    case SCORE_GLOBAL:
        pfn_scoring_global(migration_pfn, bucket_sorter);
        break;
    case SCORE_LOCAL:
        pfn_scoring_local(migration_pfn, bucket_sorter);
        break;
    }

    // Rebuild hist array
    uint64_t added = 0;
    uint64_t limit = migration_pfn.size() * thres / 100;
    migration_pfn.clear();

    // Reverse iteration to go from highest score to lowest
    for (auto it = bucket_sorter.rbegin(); it != bucket_sorter.rend(); ++it) {
        auto& list = it->second;

        // Safe to append the entire list
        for (const auto pfn : list) {
            //migration_pfn[added] = pfn;
            migration_pfn[pfn] = 1;
            added++;

            if (added >= limit)
                goto done;
        }
    }

done:
    // Update history version
    hist_ver++;
}

Filter::Filter(int hist) : Selection(hist) {
    num_min = hist;
}

void Filter::insert_new_pfn(unordered_map<uint64_t, uint64_t>& migration_pfn) {
    int skip_cnt = 0;
    int valid_cnt = 0;
    for (auto& pair : migration_pfn) {
        // TODO maybe sum the value mask to see how many cl are accessed
        //auto bitsOn = _mm_popcnt_u64(pair.second);

        // skipping any thing with a hot cacheline
        if (pair.second > num_min) {
            valid_cnt++;
        } else {
            pair.second = -1;
            skip_cnt++;
        }
    }
    LOG_DEBUG("S2: cacheline inv selection, skip cnt: %d, valid cnt: %d\n", skip_cnt, valid_cnt);
}

Pass::Pass(int hist) : Selection(hist) {
    // do nothing
}

void Pass::insert_new_pfn(unordered_map<uint64_t, uint64_t>& migration_pfn) {
    LOG_DEBUG("S2: pass through, do nothing\n");
}


HWT::HWT(int hist) : Selection(hist) {
    // do nothing
    bit_min = hist;
}

void HWT::insert_new_pfn(unordered_map<uint64_t, uint64_t>& migration_pfn) {
    int skip_cnt = 0;
    int valid_cnt = 0;
    for (auto& pair : migration_pfn) {
        auto bitsOn = _mm_popcnt_u64(pair.second);
        //LOG_DEBUG("S2: %llu, %d\n", bitsOn, bit_min, bitsOn < bit_min);
        if (bitsOn < bit_min) {
            pair.second = -1;
            skip_cnt++;
        } else {
            pair.second = 0; // in case all bit is set
            valid_cnt++;
        }
    }
    LOG_DEBUG("S2: cacheline bit selection, skip cnt: %d, valid cnt: %d, min = %d\n", skip_cnt, valid_cnt, bit_min);
}
