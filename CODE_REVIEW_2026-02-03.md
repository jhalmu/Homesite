# Code Review Findings - 2026-02-03

## Executive Summary

**Status:** ✅ All tests passing (1686/1686)
**Test Coverage:** 62.76%
**Credo Issues:** 138 total (56 refactoring, 20 readability, 62 design)
**Compiler Warnings:** 14 unused variables

---

## Performance Issues (Critical - 3 Issues)

### P1: N+1 Query - Admin Dashboard Activity Logs
- **File:** `lib/homesite_web/live/admin_live/dashboard.ex:520-527`
- **Issue:** Fetches 1000 records then filters in memory
- **Impact:** High - affects dashboard load time
- **Fix:** Add date filtering to database query

### P2: N+1 Query - Public Feed Items
- **File:** `lib/homesite/external_feeds.ex:277-296`
- **Issue:** Separate query per feed source (10+ queries)
- **Impact:** High - affects feed page performance
- **Fix:** Use window functions or LATERAL join

### P3: Uncached OG Image Generation
- **File:** `lib/homesite_web/controllers/image_controller.ex:454-571`
- **Issue:** Regenerates images on every request
- **Impact:** Medium - slow social media previews
- **Fix:** Add Cachex caching + background generation

---

## Code Quality Issues (Important - 5 Issues)

### Q1: Code Duplication in Feed Adapters
- **Files:** All adapters in `lib/homesite/external_feeds/adapters/`
- **Issue:** Duplicated helpers (truncate_text, parse_date, generate_id, HTTP requests)
- **Lines:** ~150 lines of duplication
- **Fix:** Extract to `Adapters.Helpers` module

### Q2: Unused Variables in Tests
- **File:** `test/homesite_web/live/feedback_live_test.exs`
- **Lines:** 24, 35, 46, 59, 95, 137, 185, 293, 303
- **Issue:** Variables assigned but never used (9 occurrences)
- **Fix:** Prefix with underscore

### Q3: Large File Complexity
- **File:** `lib/homesite_web/live/project_live/stepped_form.ex`
- **Lines:** 2,075 lines (too large)
- **Issue:** Multiple responsibilities, hard to maintain
- **Fix:** Extract into focused components

### Q4: Missing Database Indexes
- **Tables:** activity_logs, posts, feed_items
- **Issue:** Common query patterns lack composite indexes
- **Impact:** Slower filtered queries
- **Fix:** Add migration with composite indexes

### Q5: Inconsistent Error Handling
- **Files:** All feed adapters
- **Issue:** Mixed rescue/with patterns, silent failures
- **Fix:** Standardize on `with` clauses

---

## Compiler Warnings (14 Total)

### Unused Variables in Tests

1. `test/homesite_web/live/feedback_live_test.exs:24` - unused `view`
2. `test/homesite_web/live/feedback_live_test.exs:35` - unused `view`
3. `test/homesite_web/live/feedback_live_test.exs:46` - unused `view`
4. `test/homesite_web/live/feedback_live_test.exs:59` - unused `result`
5. `test/homesite_web/live/feedback_live_test.exs:95` - unused `result`
6. `test/homesite_web/live/feedback_live_test.exs:137` - unused `flash`
7. `test/homesite_web/live/feedback_live_test.exs:185` - unused `result`
8. `test/homesite_web/live/feedback_live_test.exs:293` - unused `view`
9. `test/homesite_web/live/feedback_live_test.exs:303` - unused `view`
10. `test/homesite/workers/feedback_prompt_worker_test.exs:5` - unused alias `Feedback`
11. `test/homesite_web/live/media_live/index_test.exs:89` - unused `orphan`
12. `test/homesite_web/components/media_components_test.exs:34` - unused `view`
13. `test/homesite/external_feeds/feed_fetcher_test.exs:61` - unused `scope`
14. `test/homesite_web/live/search_live/index_test.exs:6` - unused import `ContentFixtures`

---

## Credo Issues (138 Total)

### Refactoring Opportunities (56)

**Nested Depth Issues (15):**
- `lib/mix/tasks/seed_users.ex:212` - nested depth 3
- `lib/mix/tasks/seed_users.ex:144` - nested depth 3
- `lib/mix/tasks/seed_admin.ex:159` - nested depth 3
- `lib/mix/tasks/lighthouse.ex:217` - nested depth 3
- `lib/homesite_web/user_auth.ex:321` - nested depth 3
- `lib/homesite_web/helpers/date_helpers.ex:185` - nested depth 3
- `lib/homesite_web/controllers/feed_controller.ex:141` - nested depth 3
- `lib/homesite_web/components/table_of_contents.ex:113` - nested depth 3
- `lib/homesite/external_feeds/opml.ex:203` - nested depth 3
- `lib/homesite/external_feeds.ex:491` - nested depth 3
- `lib/homesite/analytics/geo.ex:198` - nested depth 3
- `lib/homesite/accounts.ex:182` - nested depth 3
- `lib/homesite/external_feeds/adapters/twitter_adapter.ex:61` - nested depth 3
- `lib/homesite/external_feeds/adapters/tiktok_adapter.ex:56` - nested depth 3
- `lib/homesite/external_feeds/adapters/instagram_adapter.ex:53` - nested depth 3

**High Complexity (9):**
- `lib/homesite_web/live/admin_live/dashboard.ex:803` - cyclomatic complexity 13
- `lib/homesite/external_feeds/adapters/bluesky_adapter.ex:113` - cyclomatic complexity 12
- `lib/mix/tasks/seed_users.ex:157` - cyclomatic complexity 11
- `lib/homesite_web/controllers/feed_controller.ex:108` - cyclomatic complexity 11
- `lib/homesite/faqs.ex:228` - cyclomatic complexity 11
- `lib/mix/tasks/seed_admin.ex:71` - cyclomatic complexity 10
- `lib/homesite_web/live/project_live/stepped_form.ex:1843` - cyclomatic complexity 10
- `lib/homesite_web/live/admin_live/dashboard.ex:714` - cyclomatic complexity 10
- `lib/homesite_web/controllers/image_controller.ex:454` - cyclomatic complexity 10
- `lib/homesite/accounts.ex:168` - cyclomatic complexity 10

**Other (32):**
- Cond statements with only one condition (should use `if`)
- Various nested module references
- Function body nesting issues

### Design Suggestions (62)
- Module attribute naming
- Function organization
- Pattern matching improvements

### Readability Issues (20)
- Long parameter lists
- Large modules
- Complex expressions

---

## Additional Findings

### Missing Test Coverage
- Feed adapters: Need edge case tests (malformed responses, network failures)
- Admin dashboard: Missing metrics calculation edge cases
- Project stepped form: Complex state management needs integration tests

### External Warnings
- ImageMagick deprecation: `convert` command should be `magick`

### Magic Numbers
- `bluesky_adapter.ex:138` - hardcoded `100` for text truncation
- Various timeout values not extracted to constants

---

## Recommended Action Plan

### Phase 1: Quick Wins (2-3 hours)
1. Fix all 14 compiler warnings (unused variables)
2. Fix unused imports and aliases
3. Add missing database indexes

### Phase 2: Performance (4-6 hours)
1. Fix N+1 query in admin dashboard
2. Fix N+1 query in feed system
3. Add OG image caching
4. Add dashboard stats caching

### Phase 3: Code Quality (8-10 hours)
1. Extract feed adapter helpers
2. Refactor complex functions (reduce cyclomatic complexity)
3. Standardize error handling
4. Reduce nested depth in flagged functions

### Phase 4: Architecture (16-20 hours)
1. Refactor stepped_form.ex into components
2. Split large context modules
3. Improve test coverage to 80%+

---

## Priority Matrix

| Issue | Impact | Effort | Priority |
|-------|--------|--------|----------|
| Compiler warnings | Low | Low | High (easy wins) |
| N+1 queries | High | Medium | High |
| OG image caching | Medium | Low | High |
| Missing indexes | Medium | Low | High |
| Feed adapter duplication | Medium | Medium | Medium |
| Error handling | Low | Medium | Medium |
| Large file refactoring | Medium | High | Low |
| Test coverage | Medium | High | Low |

---

## Success Metrics

- ✅ Zero compiler warnings
- ✅ Zero Credo errors (only suggestions allowed)
- ✅ All tests passing
- 🎯 Dashboard load time < 200ms (from current ~500ms)
- 🎯 Feed page load time < 300ms (from current ~800ms)
- 🎯 Test coverage > 70% (from current 62.76%)
