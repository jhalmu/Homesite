# Template Migration Checklist

**File:** ________________

**Date:** ________________

**Migration Type:** [ ] Component  [ ] LiveView Template  [ ] Page Layout

---

## Pre-Migration

- [ ] **Grep for hardcoded values:**
  ```bash
  grep -E "gap-[0-9]|m(t|b|l|r|x|y)-[0-9]|p(t|b|l|r|x|y)-[0-9]|text-(xs|sm|base|lg|xl|2xl)" <file>
  ```
- [ ] **Count occurrences:** _____ total values to replace
- [ ] **Screenshot current appearance:**
  - Mobile (375px): [ ] Captured
  - Tablet (768px): [ ] Captured
  - Desktop (1440px): [ ] Captured
- [ ] **Check for container queries:** Does this use `.post-card` or `.listing-card`?
  - [ ] Yes - verify container query behavior
  - [ ] No - proceed with manual migration

---

## Migration Tasks

### Spacing Values

- [ ] **Gap utilities:**
  - [ ] `gap-1` → `gap-[var(--space-inline)]`
  - [ ] `gap-2` → `gap-[var(--space-xs)]`
  - [ ] `gap-4` → `gap-[var(--space-sm)]`
  - [ ] `gap-6` → `gap-[var(--space-md)]`
  - [ ] `gap-8` → `gap-[var(--space-lg)]`

- [ ] **Margin utilities (mt, mb, ml, mr, mx, my):**
  - [ ] `m*-1` → `m*-[var(--space-inline)]`
  - [ ] `m*-2` → `m*-[var(--space-xs)]`
  - [ ] `m*-4` → `m*-[var(--space-sm)]`
  - [ ] `m*-6` → `m*-[var(--space-md)]`
  - [ ] `m*-8` → `m*-[var(--space-lg)]`

- [ ] **Padding utilities (p, px, py, pt, pb, pl, pr):**
  - [ ] `p*-2` → `p*-[var(--space-xs)]`
  - [ ] `p*-4` → `p*-[var(--space-sm)]`
  - [ ] `p*-6` → `p*-[var(--space-md)]`
  - [ ] `p*-8` → `p*-[var(--space-lg)]`

### Typography Values

- [ ] **Text size utilities:**
  - [ ] `text-xs` → `text-[var(--text-xs)]`
  - [ ] `text-sm` → `text-[var(--text-sm)]`
  - [ ] `text-base` → `text-[var(--text-base)]`
  - [ ] `text-lg` → `text-[var(--text-lg)]`
  - [ ] `text-xl` → `text-[var(--text-xl)]`
  - [ ] `text-2xl` → `text-[var(--text-2xl)]`

### Layout Constraints (if applicable)

- [ ] **Max width utilities:**
  - [ ] `max-w-7xl` → `max-w-[var(--content-max-width)]`
  - [ ] `max-w-4xl`, `max-w-3xl` → `max-w-[var(--article-max-width)]`
  - [ ] `max-w-xl` → `max-w-[var(--card-max-width)]`
  - [ ] `w-64` (sidebar) → `w-[var(--sidebar-width)]`

### Keep Unchanged

- [ ] **Verified DaisyUI classes unchanged:** `btn`, `card`, `badge`, `input`, etc.
- [ ] **Verified fixed sizes unchanged:** `h-5`, `w-5`, `size-6` (for icons)
- [ ] **Verified color utilities unchanged:** `text-gray-600`, `bg-base-200`, etc.
- [ ] **Verified structural utilities unchanged:** `flex`, `grid`, `items-center`, etc.

---

## Post-Migration

### Visual Verification

- [ ] **Screenshot after migration:**
  - Mobile (375px): [ ] Captured
  - Tablet (768px): [ ] Captured
  - Desktop (1440px): [ ] Captured

- [ ] **Compare before/after screenshots:**
  - Mobile: [ ] No regressions
  - Tablet: [ ] No regressions
  - Desktop: [ ] No regressions

- [ ] **Check responsive scaling:**
  - [ ] Text scales smoothly across viewports
  - [ ] Spacing scales smoothly across viewports
  - [ ] No layout breakage at intermediate sizes

### Testing

- [ ] **Run format:** `mix format`
- [ ] **Run tests:** `mix test`
- [ ] **Run credo:** `mix credo --strict`
- [ ] **Run all checks:** `mix test.all`
- [ ] **All tests passing:** 0 failures

### Code Review

- [ ] **No hardcoded spacing values remaining**
- [ ] **No hardcoded typography values remaining**
- [ ] **All token references use correct syntax:** `[var(--token-name)]`
- [ ] **No breaking changes to existing patterns**
- [ ] **Component semantics preserved**

---

## Commit

- [ ] **Stage changes:** `git add <file>`
- [ ] **Write commit message:**
  ```
  refactor: migrate <component/template> to design tokens

  Migrated <file> from hardcoded Tailwind values to fluid design tokens.

  Changes:
  - Spacing: [count] replacements (gap, margin, padding)
  - Typography: [count] replacements (text-sm, text-xl, etc.)
  - Layout: [count] replacements (max-w, w, etc.)

  Testing:
  - ✅ Visual parity maintained across all viewports
  - ✅ All tests passing (0 failures)
  - ✅ Responsive behavior improved with fluid scaling

  🤖 Generated with [Claude Code](https://claude.com/claude-code)

  Co-Authored-By: Claude <noreply@anthropic.com>
  ```
- [ ] **Commit:** `git commit`

---

## Success Metrics

After migration is complete, verify:

- ✅ **Zero hardcoded spacing values** in migrated file
- ✅ **Zero hardcoded typography values** in migrated file
- ✅ **All tests passing** (0 failures)
- ✅ **Visual parity** with original design
- ✅ **Improved responsive behavior** at all viewport sizes
- ✅ **No breaking changes** to existing components or patterns
- ✅ **Faster migration** with find/replace patterns (< 30 minutes per file)

---

## Notes

### Lessons Learned

_Document any challenges, gotchas, or insights discovered during this migration:_

---

### Time Tracking

- Pre-migration prep: _____ minutes
- Migration execution: _____ minutes
- Testing & verification: _____ minutes
- Total time: _____ minutes

**Target:** < 30 minutes per template file
