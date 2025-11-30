# Insights Archive Index

This index tracks all archived session files and shows where their insights were integrated into the project documentation.

---

## Session: 2025-11-27 22:00:00

**File**: `session-2025-11-27-220000.md`
**Archived**: 2025-11-30
**Insights**: 4 total
**Integrated**: 4 of 4 (100%)

### Context
Project cleanup - GitHub issues audit, documentation organization, and automation implementation

### Insights Integrated

1. **[Architecture] Documentation-Driven Automation**
   - **→ Integrated**: AGENTS.md - Architecture Patterns section
   - **Pattern**: Using detailed documentation as executable automation spec
   - **Tags**: #automation #documentation #workflow

2. **[Testing] Always Verify Implementation Before Closing Issues**
   - **→ Integrated**: AGENTS.md - Testing Patterns section
   - **Pattern**: Verification steps before closing GitHub issues (grep, find, git log)
   - **Tags**: #testing #verification #github

3. **[Documentation] .md File Evaluation Framework**
   - **→ Integrated**: CLAUDE.md - Documentation Organization Pattern section (after Automated Workflows)
   - **Pattern**: Essential/Important/Valuable/Keep & Update framework for organizing docs
   - **Tags**: #documentation #organization

4. **[Dependencies] GitHub CLI for Issue Management**
   - **→ Integrated**: AGENTS.md - Dependency Patterns section
   - **Pattern**: Using `gh` CLI instead of web interface for all issue operations
   - **Tags**: #github #cli #automation

---

## Session: 2025-11-28 16:19:13

**File**: `session-2025-11-28-161913.md`
**Archived**: 2025-11-30
**Insights**: 6 total
**Integrated**: 6 of 6 (100%)

### Context
FAQ LiveView implementation and comprehensive testing - fixed all errors before completing the feature

### Insights Integrated

1. **[Testing] Always Fix All Errors - Zero Tolerance Testing Policy**
   - **→ Integrated**: AGENTS.md - Testing Patterns section
   - **Pattern**: Fix ALL failing tests immediately before considering feature complete
   - **Tags**: #testing #quality #workflow #bestpractice

2. **[Security] Admin Authorization Requires Dedicated on_mount Hook**
   - **→ Integrated**: AGENTS.md - Security Patterns section
   - **Pattern**: Separate `on_mount(:require_admin)` hook for admin-only LiveViews
   - **Reference**: `lib/homesite_web/user_auth.ex:251-264`
   - **Tags**: #security #auth #liveview #authorization

3. **[Bugs] DaisyUI Button Component Has Limited Variant Support**
   - **→ Integrated**: AGENTS.md - Common Mistakes section
   - **Pattern**: Phoenix `<.button>` only supports primary/nil, use `<.link class="btn">` for other variants
   - **Reference**: `lib/homesite_web/live/faq_live/index.ex:21-26`
   - **Tags**: #bug #ui #daisyui #component

4. **[Bugs] Context Function Argument Order Must Match Definition**
   - **→ Integrated**: AGENTS.md - Common Mistakes section
   - **Pattern**: Scope-first argument order for ALL context functions, avoid piping
   - **Reference**: `lib/homesite_web/live/faq_live/form.ex:141`
   - **Tags**: #bug #elixir #context #pattern

5. **[Architecture] FAQ Category Loading Requires Separate Function Calls**
   - **→ Integrated**: AGENTS.md - Architecture Patterns section
   - **Pattern**: Database WHERE clauses happen before Elixir - call different functions for different filters
   - **Reference**: `lib/homesite_web/live/faq_live/index.ex:120-134`
   - **Tags**: #liveview #context #filtering #architecture

6. **[Not separately integrated] Documentation-Driven Automation**
   - **Note**: This insight duplicated insight #1 from session 2025-11-27, so not separately integrated
   - **Tags**: #automation #documentation

---

## Session: 2025-11-29 10:44:35

**File**: `session-2025-11-29-104435.md`
**Archived**: 2025-11-30
**Insights**: 7 total
**Integrated**: 7 of 7 (100%)

### Context
Implemented full-text search with PostgreSQL pg_trgm, social sharing system with 6 platforms, comprehensive edge case testing (62+ tests), and security validation

### Insights Integrated

1. **[Database] PostgreSQL Trigram Search with Dual Matching Strategy**
   - **→ Integrated**: AGENTS.md - Database Patterns section
   - **Pattern**: Combine pg_trgm similarity with ILIKE fallback, GIN indexes
   - **Reference**: `lib/homesite/content.ex:724-764`, `priv/repo/migrations/20251129081009_add_search_index_to_posts.exs`
   - **Tags**: #postgresql #search #performance #fts

2. **[Security] Empty Query String Handling Prevents Database Overload**
   - **→ Integrated**: AGENTS.md - Security Patterns section
   - **Pattern**: Validate queries before DB access, return [] for empty/whitespace, validate numeric params
   - **Reference**: `lib/homesite/content.ex:726-728`
   - **Tags**: #security #validation #performance #dos

3. **[Testing] Database Constraint Violations Should Be Tested with assert_raise**
   - **→ Integrated**: AGENTS.md - Testing Patterns section
   - **Pattern**: Use `assert_raise Postgrex.Error` for DB constraints, not changeset errors
   - **Reference**: `test/homesite/social_test.exs:113-127`
   - **Tags**: #testing #ecto #database #constraints

4. **[Architecture] Social Sharing as Separate Context with Analytics Foundation**
   - **→ Integrated**: AGENTS.md - Architecture Patterns section
   - **Pattern**: Dedicated contexts for features needing analytics (Social, activity logging, metrics)
   - **Reference**: `lib/homesite/social.ex`, `lib/homesite/social/share_log.ex`
   - **Tags**: #context #analytics #separation-of-concerns

5. **[UI/UX] Responsive Social Share Buttons with Platform-Specific URLs**
   - **→ Integrated**: AGENTS.md - UI/UX Patterns section
   - **Pattern**: Component-based, platform URL builders, mobile-first responsive, security attributes
   - **Reference**: `lib/homesite_web/components/social_components.ex`
   - **Tags**: #components #responsive #social #ux

6. **[Testing] Edge Case Tests Should Cover Injection Attempts and Constraints**
   - **→ Integrated**: AGENTS.md - Testing Patterns section
   - **Pattern**: Test empty, very long, SQL injection, XSS, Unicode, boundaries for all public features
   - **Reference**: `test/homesite/content_search_test.exs:142-268`, `test/homesite/social_test.exs:105-285`
   - **Tags**: #testing #security #edge-cases #validation

7. **[Security] Scope Isolation Must Be Tested for All New Features**
   - **→ Integrated**: AGENTS.md - Security Patterns section
   - **Pattern**: Dedicated security tests verifying users cannot access other users' data
   - **Reference**: `test/homesite_web/security_test.exs:338-468`
   - **Tags**: #security #testing #scope #isolation

---

## Integration Summary

**Total Sessions Archived**: 3
**Total Insights Captured**: 16 (1 duplicate = 15 unique)
**Integration Rate**: 100% of unique insights

### Files Modified

**AGENTS.md** (15 patterns added):
- Architecture Patterns: 3 insights
- Database Patterns: 1 insight
- Security Patterns: 3 insights
- Testing Patterns: 4 insights
- Common Mistakes: 2 insights
- UI/UX Patterns: 1 insight
- Dependency Patterns: 1 insight

**CLAUDE.md** (1 pattern added):
- Documentation Organization Pattern: 1 insight

### Archive Statistics

- **Sessions with 100% integration**: 3/3
- **Insights per session**: 4-7 insights (avg 5.3)
- **Categories covered**: 8 (Architecture, Database, Security, Testing, Bugs, UI/UX, Dependencies, Documentation)
- **Total lines captured**: 859 lines
- **Date range**: 2025-11-27 to 2025-11-29 (3 days)

---

## Bidirectional References

### From Archive to Documentation

Each insight in the archive sessions contains a marker comment:
```markdown
<!-- Integrated from .claude/insights sessions on 2025-11-30 -->
```

### From Documentation to Archive

To find the original session for any integrated pattern:
1. Look for the `<!-- Integrated from .claude/insights sessions -->` comment
2. Check the **Reference** field for file paths and line numbers
3. Consult this index to find the full session context

### Traceability

All insights maintain full traceability:
- **Source**: Session file + category + title + tags
- **Integration**: Target file (AGENTS.md or CLAUDE.md) + section
- **References**: Original code locations (file:line)
- **Context**: Session summary explaining when/why pattern emerged

---

## Notes

- All archived sessions are preserved for historical reference
- Sessions can be re-extracted if documentation needs updating
- Future sessions will be archived here after integration
- This index should be updated each time insights are integrated
