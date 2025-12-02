# FAQ Quality Check Automation

**Purpose**: Ensure FAQ pages remain accurate, up-to-date, and helpful as the codebase evolves.

**Frequency**: Every 2 weeks (bi-weekly)

**Automation Level**: Semi-automated (mix task + manual review)

---

## 🤖 Automated Quality Checks

### Mix Task: `mix faqs.quality_check`

Creates a report analyzing FAQ content against current codebase state.

#### Checks Performed

1. **Code Example Validation**
   - Extract code blocks from all FAQs
   - Attempt to compile Elixir code examples
   - Flag outdated function signatures
   - Detect deprecated modules/functions

2. **Route Verification**
   - Extract mentioned routes (e.g., `/feed`, `/admin`)
   - Compare against `router.ex`
   - Flag removed or renamed routes

3. **Feature References**
   - Scan for feature mentions ("External Feeds", "Username Routing", etc.)
   - Cross-reference with implemented features
   - Detect references to removed features

4. **Broken Links**
   - Extract all URLs (internal and external)
   - Verify internal routes exist
   - Check external links (HTTP 200 status)

5. **Freshness Score**
   - Calculate days since last FAQ update
   - Compare against recent git commits
   - Flag FAQs >90 days old during active development

#### Output Format

```
FAQ Quality Report
Generated: 2025-12-15 10:30:00

=== USER FAQs ===

[1] How to create your first blog post (✅ GOOD)
   - Code examples: Valid
   - Routes: All exist
   - Last updated: 15 days ago

[2] Using External Feeds (⚠️ NEEDS UPDATE)
   - Code examples: 1 deprecated function found
     `ExternalFeeds.refresh_feed_source/1` → `ExternalFeeds.refresh_feed_source/2`
   - Routes: All exist
   - Last updated: 45 days ago
   - Recommendation: Update code example, add folder organization info

[3] Markdown formatting guide (❌ STALE)
   - Last updated: 120 days ago
   - Recommendation: Review against current MDEx configuration

=== DEV FAQs ===

[005] External Feeds System (✅ GOOD)
   - Code examples: Valid
   - Routes: All exist
   - Last updated: 2 days ago

[006] Recent Features & Updates (⚠️ NEEDS UPDATE)
   - Last updated: 18 days ago
   - Recommendation: Add December 2025 features

=== SUMMARY ===

Total FAQs: 12
✅ Good: 8 (67%)
⚠️ Needs Update: 3 (25%)
❌ Stale: 1 (8%)

Priority Actions:
1. Update "Markdown formatting guide" (stale 120 days)
2. Fix code example in "Using External Feeds"
3. Review "Recent Features & Updates" for completeness
```

---

## 📋 Manual Review Checklist

Every 2 weeks, review the automated report and:

### 1. Content Accuracy (15 min)
- [ ] All code examples compile and run correctly
- [ ] Route references match current `router.ex`
- [ ] Feature descriptions match implementation
- [ ] No references to removed/deprecated features

### 2. Completeness (10 min)
- [ ] Recent features (last 2 weeks) documented
- [ ] Common user questions addressed
- [ ] Admin features explained for DEV FAQs
- [ ] No major feature missing from FAQs

### 3. Clarity & Helpfulness (10 min)
- [ ] Language is clear and professional
- [ ] Examples are easy to follow
- [ ] Edge cases documented
- [ ] Common pitfalls addressed

### 4. Structure & Organization (5 min)
- [ ] FAQs logically ordered (basic → advanced)
- [ ] Categories make sense
- [ ] No duplicate content across FAQs
- [ ] Table of contents renders correctly

---

## 🔧 Implementation Guide

### Step 1: Create Mix Task

**File**: `lib/mix/tasks/faqs.quality_check.ex`

```elixir
defmodule Mix.Tasks.Faqs.QualityCheck do
  use Mix.Task

  @shortdoc "Check FAQ content quality and accuracy"

  def run(_args) do
    Mix.Task.run("app.start")

    # TODO: Implement checks
    # 1. Load all FAQs (user + dev)
    # 2. Extract code blocks, routes, features
    # 3. Validate against codebase
    # 4. Generate report

    Mix.shell().info("FAQ Quality Check: Not yet implemented")
    Mix.shell().info("See: .claude/workflows/faq-quality-check.md")
  end
end
```

### Step 2: Schedule Reviews

Add to calendar/project management:
- **Frequency**: Every 2 weeks (Monday mornings recommended)
- **Duration**: 40-60 minutes total
- **Assignee**: Developer responsible for documentation

### Step 3: Update Workflow

After each review:
1. Run `mix faqs.quality_check`
2. Review automated report
3. Complete manual checklist
4. Update FAQs as needed
5. Document changes in commit message

Example commit:
```
docs: Update FAQ content (bi-weekly quality check)

- Fixed deprecated code example in "Using External Feeds"
- Added December features to "Recent Features & Updates"
- Updated route references in "Admin Features"

Quality check report: 12 FAQs reviewed, 3 updated
```

---

## 📊 Success Metrics

Track these metrics over time:

1. **Freshness Score**
   - % of FAQs updated in last 30 days
   - Target: >50% during active development

2. **Accuracy Rate**
   - % of code examples that compile
   - % of routes that exist
   - Target: 100%

3. **Coverage Score**
   - % of major features documented in FAQs
   - Target: >90%

4. **User Impact**
   - Search queries for FAQ topics (from search analytics)
   - Time spent on FAQ pages (future metric)

---

## 🚀 Future Enhancements

### Phase 1: Basic Automation (Current)
- [x] Define quality check workflow
- [ ] Implement `mix faqs.quality_check` task
- [ ] Schedule bi-weekly reviews

### Phase 2: Enhanced Validation
- [ ] Compile code examples in isolated environment
- [ ] Test route accessibility with Phoenix.Test
- [ ] Detect module/function deprecations via AST analysis
- [ ] Check external links with HTTP client

### Phase 3: Continuous Monitoring
- [ ] Git pre-push hook to warn if FAQs >90 days old
- [ ] GitHub Action to run quality check on CI
- [ ] Auto-generate "needs update" issues
- [ ] Dashboard widget showing FAQ health

### Phase 4: User-Driven Updates
- [ ] "Was this helpful?" buttons on FAQ pages
- [ ] User-submitted FAQ suggestions
- [ ] Analytics: Which FAQs get most views?
- [ ] A/B test FAQ improvements

---

## 🎯 When to Update FAQs

### Immediate Updates Required
- ✅ Breaking API changes (route removals, function signature changes)
- ✅ Security-critical information changes
- ✅ Major feature launches

### Bi-Weekly Review
- ✅ New features added
- ✅ Code examples need refactoring
- ✅ User feedback indicates confusion

### Monthly Review
- ✅ General clarity improvements
- ✅ Add missing edge cases
- ✅ Reorganize for better flow

---

## 📝 Template: FAQ Update Commit

```
docs(faqs): [Category] - [Change Summary]

## Changes
- [User FAQ #3] Updated code example for External Feeds
- [Dev FAQ #006] Added December 2025 features
- [User FAQ #1] Clarified username routing behavior

## Quality Check Results
- ✅ All code examples compile
- ✅ All routes verified
- ✅ Freshness score: 75% (up from 58%)

## References
- Quality check run: 2025-12-15
- Issues addressed: #XYZ (if applicable)

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

---

**Created**: 2025-12-02
**Next Review**: 2025-12-16
**Owner**: Development Team
**Status**: Active (implementation pending)
