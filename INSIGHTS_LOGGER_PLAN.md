# Insights Logger Implementation Plan

## Overview

This document outlines the plan for implementing an automated insights logger system for the homesite project. The system is inspired by the approach described in https://www.nathanonn.com/make-claude-code-remember-everything-with-this-skill/.

**Status:** Planning phase - implementation deferred until after current feature work is complete.

## Goals

- **Capture**: Automatically log coding insights, decisions, and patterns during development
- **Organize**: Structure insights by category for easy review
- **Integrate**: Selectively merge valuable insights into CLAUDE.md for future reference
- **Compound**: Build a knowledge base that improves coding efficiency over time

## System Architecture

### Three-Phase Workflow

1. **Automatic Capture** → Log insights during development without interrupting flow
2. **Structured Review** → Present categorized insights for user selection
3. **Selective Integration** → Merge chosen insights into CLAUDE.md with context

## Phase 1: Setup Infrastructure

### Directory Structure

Create `.claude/insights/` directory hierarchy:

```
.claude/
├── insights/
│   ├── session-2025-11-26-143000.md
│   ├── session-2025-11-27-091500.md
│   └── archive/
│       ├── session-2025-11-20-102000.md (processed)
│       └── session-2025-11-21-154500.md (processed)
└── CLAUDE.md (enhanced with integrated patterns)
```

### Implementation Steps

1. **Create directory structure**:
   ```bash
   mkdir -p .claude/insights/archive
   ```

2. **Add .gitignore rules** (optional - decide if insights should be committed):
   ```
   # Option 1: Ignore all insights (temporary notes only)
   .claude/insights/**/*.md
   !.claude/insights/archive/

   # Option 2: Commit insights (knowledge base versioned)
   # (no gitignore needed)
   ```

3. **Create session template**:
   - File: `.claude/insights/session-template.md`
   - Contains structure for consistent insight capture

### Session File Format

```markdown
# Session: YYYY-MM-DD HH:MM:SS

## Category: Architecture

### Insight: Scope Pattern Enforcement
**File**: `lib/homesite/content.ex:415`
**Tags**: #security #elixir #pattern

**Problem**: Need to ensure all context functions enforce user scope isolation.

**Solution**:
```elixir
def update_post(%Scope{} = scope, %Post{} = post, attrs) do
  true = post.user_id == scope.user.id  # Security check
  # ... rest of function
end
```

**Rationale**: Using pattern matching with `true =` raises MatchError if user tries to access another user's data. This is more explicit and fail-fast than if/else checks.

**Why it matters**: Security-critical pattern that prevents unauthorized data access. Should be applied consistently across all scoped operations.

---

## Category: Database

### Insight: Ecto Preloading for Feeds
**File**: `lib/homesite/content.ex:460`
**Tags**: #ecto #performance #query

... (more insights)
```

## Phase 2: Session Logging System

### Insight Categories

Organize insights into these categories:

- **Architecture**: Design patterns, system structure, module organization
- **Database**: Ecto queries, migrations, schema patterns, performance
- **Security**: Authentication, authorization, data protection, vulnerability fixes
- **UI/UX**: LiveView patterns, component design, styling decisions
- **Performance**: Optimizations, caching, query improvements
- **Bugs**: Bug fixes, root cause analysis, prevention strategies
- **Testing**: Test patterns, coverage strategies, edge cases
- **Dependencies**: Library-specific quirks, API changes, version issues

### Capture Triggers

**Manual Triggers** (user-initiated):
- "Log this insight"
- "Remember this pattern"
- "Add to insights: [description]"

**Automatic Triggers** (context-aware):
- After fixing a non-trivial bug
- When making architectural decisions
- When discovering library quirks
- When implementing security measures
- After performance optimizations

### Insight Entry Structure

Each entry must include:
1. **Category tag** - For organization
2. **File reference** - `path/to/file.ex:line_number`
3. **Tags** - Searchable keywords
4. **Problem statement** - What was the issue/question
5. **Solution** - Code or approach taken
6. **Rationale** - Why this solution was chosen
7. **Why it matters** - Impact and applicability

## Phase 3: Review & Integration Workflow

### Review Command

**Trigger**: "Review insights from existing sessions"

**Process**:
1. Read all session files from `.claude/insights/`
2. Parse and categorize insights
3. Present to user grouped by category
4. Show file references and tags for context
5. User selects insights worth keeping (30-50% expected selection rate)

### Presentation Format

```markdown
# Insights Review - 5 sessions analyzed

## Architecture (12 insights)

### ✓ Scope Pattern Enforcement
**Files**: content.ex:415, accounts.ex:89
**Impact**: Security-critical
**Tags**: #security #pattern
Would you like to integrate this? (y/n)

### ✓ PubSub for Real-time Updates
**Files**: content.ex:28-32
**Impact**: Feature pattern
**Tags**: #pubsub #liveview
Would you like to integrate this? (y/n)

... (more insights)

## Database (8 insights)
... (continues)
```

### Integration Process

1. **User selects insights** - Mark chosen insights for integration
2. **Claude synthesizes** - Generalizes patterns for broader applicability
3. **Update CLAUDE.md** - Adds insights to appropriate sections with surgical precision
4. **Archive sessions** - Moves processed sessions to `.claude/insights/archive/`
5. **Confirmation** - Shows user what was added to CLAUDE.md

### CLAUDE.md Integration Strategy

**Where to add insights:**

- **Architecture patterns** → Add to "Architecture Overview" or create new section
- **Security patterns** → Add to "Security (MANDATORY)" section
- **Testing patterns** → Add to "Testing & Code Quality" section
- **Elixir quirks** → Add to "Elixir Patterns" in AGENTS.md
- **Phoenix patterns** → Add to "Phoenix v1.8 guidelines" in AGENTS.md
- **Library-specific** → Create "Known Issues & Patterns" section per library

**Format for integrated insights:**

```markdown
## Pattern: Scope Isolation with Pattern Matching

**When to use**: All context functions that operate on scoped resources

**Implementation**:
```elixir
def update_resource(%Scope{} = scope, %Resource{} = resource, attrs) do
  true = resource.user_id == scope.user.id  # Enforces scope
  # ... proceed with update
end
```

**Why**: Pattern matching with `true =` raises MatchError on scope violations,
preventing unauthorized access. More explicit than if/else checks.

**Related files**: `lib/homesite/content.ex:415`, `lib/homesite/accounts.ex:89`
```

## Phase 4: Selection Criteria

### Include Insights That Are:

✅ **Universal and reusable** - Patterns applicable across features
✅ **Security-related** - Authentication, authorization, data protection
✅ **Performance optimizations** - Query improvements, caching strategies
✅ **Dependency quirks** - Library-specific gotchas, API changes
✅ **Architectural principles** - System design patterns, module organization
✅ **Non-obvious solutions** - Clever fixes that aren't intuitive
✅ **Error-prone areas** - Common mistakes to avoid

### Skip Insights That Are:

❌ **Feature-specific details** - One-off implementations
❌ **Temporary workarounds** - Technical debt, to be replaced
❌ **Obvious patterns** - Well-known best practices Claude already knows
❌ **Context-dependent** - Only makes sense for specific files
❌ **Incomplete** - Half-finished thoughts or unclear decisions

## Example Use Cases

### Use Case 1: Elixir-Specific Patterns

**Captured Insight**:
```markdown
### No `else if` in Elixir
**Problem**: Tried to use `else if` for multiple conditions
**Solution**: Use `cond` for multiple conditions or `case` for pattern matching
**Why it matters**: Common mistake for developers from other languages
```

**Integrated to AGENTS.md**:
```markdown
## Elixir Core Patterns

### Conditional Logic
- **No `else if`** - Use `cond` for multiple conditions or `case` for pattern matching
  ```elixir
  # Wrong
  if condition1 do
  else if condition2 do  # Syntax error!

  # Right
  cond do
    condition1 -> ...
    condition2 -> ...
    true -> ...
  end
  ```
```

### Use Case 2: Phoenix LiveView Gotcha

**Captured Insight**:
```markdown
### LiveView Form Handling
**Problem**: Form not submitting in LiveView
**Solution**: Must use `to_form/2` and `@form` pattern, not raw changeset
**File**: user_live/login.ex:101
**Why it matters**: Common LiveView mistake, causes silent failures
```

**Integrated to AGENTS.md**:
```markdown
## LiveView Form Handling

Always use `to_form/2` in LiveView:

```elixir
# In mount or handle_event
assign(socket, form: to_form(changeset))

# In template
<.form for={@form} id="unique-id">
  <.input field={@form[:email]} />
</.form>
```

**Never** pass raw changeset as `for={@changeset}` - will cause silent failures.
```

### Use Case 3: Ecto Query Optimization

**Captured Insight**:
```markdown
### Preload Associations for Feeds
**Problem**: N+1 queries when generating RSS feeds
**Solution**: Use `preload: [:user, :tags]` in feed queries
**File**: content.ex:460
**Performance**: Reduced 100+ queries to 3 queries
```

**Integrated to AGENTS.md**:
```markdown
## Ecto Query Optimization

### Preload Associations

Always preload associations that will be accessed:

```elixir
# Bad - N+1 queries
posts = Repo.all(from p in Post)
Enum.map(posts, fn post -> post.user.name end)

# Good - Single query with joins
posts = Repo.all(from p in Post, preload: [:user, :tags])
```

**RSS Feeds**: Always preload `:user` and `:tags` for feed generation.
```

## Phase 5: Activation & Usage

### Activation Methods

1. **Explicit command**:
   - "Please use the insights logger"
   - "Log this insight: [description]"
   - "Remember this pattern"

2. **Automatic (future enhancement)**:
   - Triggered by keywords: "gotcha", "tricky", "important"
   - After non-trivial bug fixes
   - When making security changes

3. **End-of-session summary**:
   - "Summarize insights from this session"
   - Auto-generates session file

### Workflow Example

```
User: "Please log this insight: Scope pattern enforcement"

Claude: "Logged to session-2025-11-26-143000.md under Architecture category.
This insight captures the security pattern of using pattern matching to enforce
scope isolation in context functions."

[Later in the session]

User: "Review insights from existing sessions"

Claude: "I found 23 insights across 5 sessions. Here are the highlights:

Architecture (8 insights):
- ✓ Scope Pattern Enforcement (HIGH PRIORITY - security)
- Context module organization
- PubSub real-time updates
...

Would you like to integrate the high-priority insights?"

User: "Yes, integrate security and database insights"

Claude: "Integrated 5 insights into CLAUDE.md and AGENTS.md:
- Added Scope Pattern Enforcement to Security section
- Added Ecto preloading pattern to Database section
- Added N+1 query prevention to Performance section
...
Archived 5 processed session files."
```

## Compound Effect

### Week 1-2: Foundation
- Capture 10-15 insights per session
- Build initial knowledge base
- Identify recurring patterns

### Month 1: Pattern Recognition
- 50-100 insights captured
- 15-25 integrated into docs
- Patterns become reusable

### Month 3: Efficiency Gains
- Future sessions apply captured patterns automatically
- Avoid recurring bugs from documented pitfalls
- Implement proven architectures without manual lookup

### Month 6+: Knowledge Compounding
- Comprehensive pattern library
- Project-specific best practices codified
- Onboarding new developers faster
- Reduce technical debt from repeated mistakes

## Implementation Timeline

### Phase 1: Infrastructure (1 hour)
- Create directory structure
- Design session file template
- Add gitignore rules (if needed)
- Document activation commands

### Phase 2: Capture System (2-3 hours)
- Implement manual logging triggers
- Create insight entry format
- Build session file generation
- Test with sample insights

### Phase 3: Review System (3-4 hours)
- Build session file parser
- Create categorization logic
- Design presentation format
- Implement user selection interface

### Phase 4: Integration System (2-3 hours)
- Build CLAUDE.md updater
- Implement pattern generalization
- Create archival system
- Add confirmation feedback

### Total Estimate: 8-11 hours

**Note**: Implementation is deferred until after current feature work (i18n, RSS feeds, etc.) is completed and tested.

## Success Metrics

### Quantitative
- **Capture rate**: 10-20 insights per coding session
- **Integration rate**: 30-50% of captured insights integrated
- **Reuse rate**: Patterns referenced in 3+ future sessions
- **Time saved**: 15-30% reduction in time spent on similar problems

### Qualitative
- **Knowledge retention**: Patterns remembered without manual lookup
- **Code consistency**: Architectural decisions align with documented patterns
- **Onboarding speed**: New developers can reference pattern library
- **Technical debt**: Fewer repeated mistakes from undocumented gotchas

## Future Enhancements

### Phase 2 Enhancements
- **Tagging system**: Searchable tags for quick lookup
- **Linking**: Cross-reference related insights
- **Versioning**: Track pattern evolution over time

### Phase 3 Enhancements
- **Search interface**: Query insights by keyword, file, or category
- **Pattern templates**: Pre-built structures for common patterns
- **Diff view**: Show before/after when integrating to CLAUDE.md

### Automation
- **AI-assisted capture**: Auto-detect potential insights
- **Smart categorization**: ML-based category suggestion
- **Conflict detection**: Warn if new pattern contradicts existing ones

## Related Files

- `.claude/insights/` - Session files (to be created)
- `CLAUDE.md` - Integration target
- `AGENTS.md` - Integration target for Elixir/Phoenix patterns
- `MEMO.md` - Session notes (different purpose - historical context)

## Notes

- **Different from MEMO.md**: Insights focus on reusable patterns, MEMO.md focuses on session history
- **Opt-in system**: Requires explicit activation, doesn't capture automatically initially
- **Privacy-friendly**: All data stays local, no external services
- **Git-friendly**: Markdown files can be versioned and shared

---

**Document created:** 2025-11-26
**Status:** Planning complete - awaiting implementation phase
**Next step:** Complete current feature work, then begin Phase 1 implementation
