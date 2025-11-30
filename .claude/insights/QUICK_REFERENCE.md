# Insights Logger - Quick Reference Guide

A quick reference for capturing, reviewing, and integrating coding patterns discovered during development.

---

## 🎯 Quick Commands

| Command | What It Does |
|---------|--------------|
| `"Log this insight: [description]"` | Manual capture with full details |
| `"Gotcha: [issue]"` | Auto-capture bug/mistake (Bugs category) |
| `"Important pattern: [pattern]"` | Auto-capture architecture pattern |
| `"Security note: [issue]"` | Auto-capture security pattern |
| `"Review insights"` | Review all captured insights |
| `"Review insights #security #critical"` | Filter by tags |

---

## 📝 Capture Methods

### Manual Capture (Full Details)
```
User: "Log this insight: Scope-first argument pattern"

Claude: [Creates entry with full Problem/Solution/Rationale/Why format]
```

### Auto-Capture (Quick)
```
User: "Gotcha: DaisyUI buttons don't support ghost variant"

Claude: 📝 Auto-captured as Bugs insight!

        1. Add details now
        2. Minimal note (expand later)  ← Pick this for speed
        3. Skip
```

### Trigger Keywords → Categories

| Trigger | Category |
|---------|----------|
| `"Gotcha: ..."` | Bugs |
| `"Important pattern: ..."` | Architecture |
| `"Tricky: ..."` | Bugs |
| `"Security note: ..."` | Security |
| `"Performance: ..."` | Performance/Database |
| `"Testing pattern: ..."` | Testing |
| `"UI note: ..."` | UI/UX |

---

## 🏷️ Tag System

### Tag Categories

**Severity** (always include one):
- `#critical` - Fix immediately, security/data risk
- `#important` - Apply to all new features
- `#nice-to-know` - Optional optimization

**Type**:
- `#pattern` - Reusable solution
- `#gotcha` - Common mistake/pitfall
- `#bug` - Specific bug fix
- `#optimization` - Performance improvement

**Domain**:
- `#security` - Security-related
- `#performance` - Speed/efficiency
- `#ui` - User interface
- `#database` - Data layer
- `#testing` - Test patterns

**Technology**:
- `#ecto` - Ecto ORM
- `#liveview` - Phoenix LiveView
- `#postgresql` - PostgreSQL
- `#phoenix` - Phoenix framework
- `#daisyui` - DaisyUI components

### Tag Examples
```markdown
**Tags**: #security #auth #liveview #critical #pattern
**Tags**: #database #postgresql #performance #important
**Tags**: #ui #daisyui #gotcha #nice-to-know
```

---

## 🔍 Review & Filter

### Review All Insights
```
User: "Review insights"

Claude: Shows all insights grouped by category
        → Select all/by category/individually
```

### Filter by Tags
```
# High priority only
User: "Review insights #critical"

# Security patterns
User: "Review insights #security"

# Database performance
User: "Review insights #postgresql #performance"

# Common mistakes
User: "Review insights #gotcha"

# LiveView patterns
User: "Review insights #liveview #pattern"
```

---

## 📂 File Structure

```
.claude/insights/
├── session-2025-11-30-140000.md    # Current session
├── template.md                      # Template for new sessions
└── archive/
    ├── session-2025-11-27-220000.md  # Processed session
    ├── session-2025-11-28-161913.md
    ├── session-2025-11-29-104435.md
    └── ARCHIVE_INDEX.md              # Traceability index
```

---

## 📋 Session File Format

```markdown
# Session: 2025-11-30 14:00:00

**Context**: Brief description of what you're working on

---

## Category: Architecture

### Insight: Clear, Descriptive Title
**File**: `lib/homesite/context.ex:120-145`
**Tags**: #architecture #pattern #important

**Problem**: What issue or gap did you discover?

**Solution**: How did you solve it? Include code examples.

**Rationale**: Why does this solution work?

**Why it matters**: When should this pattern be applied?

---

## Category: Security

### Insight: Another Pattern
...
```

---

## 🔄 Complete Workflow

### 1. During Development
```
# Discover pattern/gotcha while coding
User: "Gotcha: Context functions need scope as first arg"

# Quick capture (option 2)
→ Saved to current session
```

### 2. End of Sprint/Week
```
User: "Review insights"

→ Claude parses all sessions
→ Shows 8 insights across 4 categories
→ Select which to integrate

User: "All insights"

→ Claude generalizes patterns
→ Integrates into AGENTS.md/CLAUDE.md
→ Archives processed sessions
```

### 3. Later Reference
```
User: "Where did the Scope pattern come from?"

→ Claude checks ARCHIVE_INDEX.md
→ Shows original session
→ Can read full context
```

---

## 🎨 Best Practices

### When to Capture
✅ Non-obvious solutions
✅ Security-critical patterns
✅ Common mistakes/gotchas
✅ Performance optimizations
✅ Library-specific quirks
✅ Architectural decisions

❌ Feature-specific implementation
❌ Obvious/well-known patterns
❌ Temporary workarounds
❌ Incomplete thoughts

### Good Insight Titles
✅ "Scope-First Argument Order" (clear, actionable)
✅ "Dual Search Strategy (Trigram + ILIKE)" (describes what)
✅ "DaisyUI Button Variant Support" (specific component)

❌ "Fix for users" (too vague)
❌ "That thing we did" (unclear)
❌ "Bug #123" (not descriptive)

### Tag Best Practices
- Always include severity (`#critical`, `#important`, `#nice-to-know`)
- Add 1-2 domain tags (`#security`, `#performance`, etc.)
- Include technology tags for library-specific patterns
- Use `#pattern` for solutions, `#gotcha` for pitfalls

---

## 📊 Where Insights Get Integrated

| Category | Destination | Section |
|----------|-------------|---------|
| Architecture | AGENTS.md | Architecture Patterns |
| Database | AGENTS.md | Database Patterns |
| Security | AGENTS.md | Security Patterns |
| Testing | AGENTS.md | Testing Patterns |
| Bugs | AGENTS.md | Common Mistakes |
| UI/UX | AGENTS.md | UI/UX Patterns |
| Dependencies | AGENTS.md | Dependency Patterns |
| Documentation | CLAUDE.md | After Automated Workflows |

---

## 🔧 Troubleshooting

**"Session file not found"**
→ Create new session: `touch .claude/insights/session-$(date +%Y-%m-%d-%H%M%S).md`
→ Copy structure from `template.md`

**"Can't find archived session"**
→ Check `.claude/insights/archive/ARCHIVE_INDEX.md`
→ Lists all archived sessions with dates

**"Want to update integrated pattern"**
→ Edit AGENTS.md directly (patterns are living documentation)
→ Or capture new insight and integrate again

**"Too many sessions piling up"**
→ Run review regularly (weekly/bi-weekly)
→ Keeps sessions fresh and patterns relevant

---

## 💡 Pro Tips

1. **Capture immediately** - Don't wait, context fades quickly
2. **Use minimal capture** - Fast during dev, expand during review
3. **Tag consistently** - Makes filtering powerful
4. **Review regularly** - Weekly prevents backlog
5. **Update patterns** - AGENTS.md is living documentation
6. **Reference file paths** - Makes patterns concrete and findable
7. **Include examples** - Code speaks louder than words
8. **Explain "why"** - Future you needs context

---

## 📚 Example Queries

```bash
# Security audit
"Review insights #security #critical"

# Performance optimization sprint
"Review insights #performance #database"

# Before refactoring LiveView
"Review insights #liveview #pattern"

# Teaching new developer
"Review insights #gotcha"

# Weekly review
"Review insights"

# After discovering pattern
"Gotcha: [quick description]"
```

---

## 🎯 Success Metrics

After using Insights Logger, you should have:
- ✅ Less repeated mistakes (gotchas captured)
- ✅ Faster onboarding (patterns documented)
- ✅ Better code quality (patterns applied consistently)
- ✅ Knowledge retention (insights preserved across sessions)
- ✅ Living documentation (AGENTS.md grows with project)

---

**Last Updated**: 2025-11-30
**System Version**: 1.0 (Phases 3-7 complete)
