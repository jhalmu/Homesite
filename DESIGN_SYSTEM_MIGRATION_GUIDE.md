# Design System Migration Guide

**Purpose:** Convert hardcoded Tailwind values to fluid design tokens for consistent, responsive scaling.

**Target:** Template files (`.html.heex`) and component files (`.ex` with `~H""" ... """` blocks)

**Status:** Active - 15% of templates migrated, 85% remaining

---

## Table of Contents

1. [Quick Reference](#quick-reference)
2. [Find/Replace Patterns](#findreplace-patterns)
3. [Common Mistakes & Gotchas](#common-mistakes--gotchas)
4. [Before/After Examples](#beforeafter-examples)
5. [Migration Checklist](#migration-checklist)

---

## Quick Reference

### Spacing Conversions

| Hardcoded | Design Token | Fluid Range | Usage |
|-----------|--------------|-------------|-------|
| `gap-1`, `m-1`, `p-1` | `[var(--space-inline)]` | 4px → 8px | Tiny gaps, inline spacing |
| `gap-2`, `mt-2`, `mb-2`, `px-2`, `py-2` | `[var(--space-xs)]` | 4px → 8px | Extra small spacing |
| `gap-4`, `mb-4`, `p-4`, `ml-4` | `[var(--space-sm)]` | 8px → 16px | Small spacing, card padding |
| `gap-6`, `pb-6`, `mt-6` | `[var(--space-md)]` | 16px → 32px | Medium spacing, sections |
| `gap-8`, `mt-8`, `mb-8` | `[var(--space-lg)]` | 32px → 64px | Large spacing, major sections |
| `gap-12`, `mt-12` | `[var(--space-xl)]` | 48px → 96px | Extra large spacing, page sections |

### Typography Conversions

| Hardcoded | Design Token | Fluid Range | Usage |
|-----------|--------------|-------------|-------|
| `text-xs` | `[var(--text-xs)]` | 12px → 14px | Fine print, captions |
| `text-sm` | `[var(--text-sm)]` | 14px → 16px | Body text, labels |
| `text-base` | `[var(--text-base)]` | 16px → 20px | Primary body text |
| `text-lg` | `[var(--text-lg)]` | 18px → 24px | Subheadings |
| `text-xl` | `[var(--text-xl)]` | 20px → 32px | Section headings (h2) |
| `text-2xl` | `[var(--text-2xl)]` | 24px → 48px | Page titles (h1) |

### Layout Constraint Conversions

| Hardcoded | Design Token | Value | Usage |
|-----------|--------------|-------|-------|
| `max-w-7xl` | `max-w-[var(--content-max-width)]` | min(95vw, 1400px) | Main content containers |
| `max-w-4xl`, `max-w-3xl` | `max-w-[var(--article-max-width)]` | min(90vw, 800px) | Article/prose width |
| `max-w-xl` | `max-w-[var(--card-max-width)]` | min(90vw, 600px) | Card max width |
| `w-64` (sidebar) | `w-[var(--sidebar-width)]` | max(250px, 20vw) | Sidebar width |

---

## Find/Replace Patterns

### Spacing Patterns

Use your editor's find/replace with regex support:

#### Gap Utilities
```
Find: \bgap-1\b
Replace: gap-[var(--space-inline)]

Find: \bgap-2\b
Replace: gap-[var(--space-xs)]

Find: \bgap-4\b
Replace: gap-[var(--space-sm)]

Find: \bgap-6\b
Replace: gap-[var(--space-md)]

Find: \bgap-8\b
Replace: gap-[var(--space-lg)]
```

#### Margin Utilities
```
Find: \bm(t|b|l|r)-1\b
Replace: m$1-[var(--space-inline)]

Find: \bm(t|b|l|r)-2\b
Replace: m$1-[var(--space-xs)]

Find: \bm(t|b|l|r)-4\b
Replace: m$1-[var(--space-sm)]

Find: \bm(t|b|l|r)-6\b
Replace: m$1-[var(--space-md)]

Find: \bm(t|b|l|r)-8\b
Replace: m$1-[var(--space-lg)]
```

#### Padding Utilities
```
Find: \bp(x|y|t|b|l|r)-2\b
Replace: p$1-[var(--space-xs)]

Find: \bp(x|y|t|b|l|r)-4\b
Replace: p$1-[var(--space-sm)]

Find: \bp(x|y|t|b|l|r)-6\b
Replace: p$1-[var(--space-md)]
```

#### Typography
```
Find: \btext-xs\b
Replace: text-[var(--text-xs)]

Find: \btext-sm\b
Replace: text-[var(--text-sm)]

Find: \btext-base\b
Replace: text-[var(--text-base)]

Find: \btext-lg\b
Replace: text-[var(--text-lg)]

Find: \btext-xl\b
Replace: text-[var(--text-xl)]

Find: \btext-2xl\b
Replace: text-[var(--text-2xl)]
```

### Automated Migration (Elixir Components)

For `.ex` component files, use the Edit tool with `replace_all: true`:

```elixir
# Example using Claude Code Edit tool
Edit file_path: "lib/homesite_web/components/example.ex"
  old_string: "gap-2"
  new_string: "gap-[var(--space-xs)]"
  replace_all: true
```

---

## Common Mistakes & Gotchas

### 1. Don't Migrate DaisyUI Component Classes

**❌ Wrong:**
```heex
<button class="btn btn-[var(--space-sm)]">  <!-- DON'T DO THIS -->
```

**✅ Correct:**
```heex
<button class="btn btn-primary gap-[var(--space-xs)]">  <!-- Migrate spacing only -->
```

**Why:** DaisyUI component classes (`btn`, `card`, `badge`, etc.) are semantic and shouldn't be tokenized. Only migrate spacing/typography utilities.

### 2. Mixed Token Usage is OK

**✅ Correct:**
```heex
<div class="flex items-center gap-[var(--space-xs)] text-[var(--text-sm)] text-gray-600">
```

**Why:** Color utilities (`text-gray-600`) and utility classes (`flex`, `items-center`) don't need migration. Only spacing and typography values.

### 3. Don't Break Existing Patterns

**❌ Wrong:**
```heex
<!-- Before: Using Tailwind size utilities -->
<.icon name="hero-tag" class="h-5 w-5" />

<!-- After: DON'T change icon sizes -->
<.icon name="hero-tag" class="h-[var(--space-sm)] w-[var(--space-sm)]" />
```

**✅ Correct:**
```heex
<!-- Keep icon sizes as-is -->
<.icon name="hero-tag" class="h-5 w-5" />
```

**Why:** Fixed-size utilities (`h-5`, `w-5`, `size-6`) are intentional and shouldn't be fluid. Only migrate layout spacing and typography.

### 4. Container Queries Already Handle Responsive Cards

**✅ No migration needed:**
```heex
<div class="post-card">  <!-- Container queries handle padding automatically -->
  <div class="card-body">
    <!-- Content -->
  </div>
</div>
```

**Why:** If using `.post-card` or `.listing-card` classes, container queries in `app.css` already apply fluid tokens. Don't duplicate by adding tokens manually.

### 5. Watch Out for Fractional Values

**❌ Wrong:**
```heex
<!-- px-3 is 0.75rem, which doesn't map cleanly -->
<div class="px-3">  <!-- What token to use? -->
```

**✅ Correct:**
```heex
<!-- Use closest semantic token -->
<div class="px-[var(--space-xs)]">  <!-- 0.25rem → 0.5rem fluid -->

<!-- OR keep fractional if intentional -->
<div class="px-3">  <!-- Keep if specific value needed -->
```

**Why:** Not all Tailwind values map 1:1 to design tokens. Use semantic judgment.

### 6. Performance: CSS Variables Have Zero Runtime Cost

**✅ Safe to use:**
```heex
<!-- Design tokens are CSS custom properties - no performance penalty -->
<div class="gap-[var(--space-xs)] mb-[var(--space-sm)]">
```

**Why:** CSS custom properties are resolved at render time, not runtime. No JavaScript overhead.

### 7. Testing After Migration

**⚠️ Critical:**
```bash
# ALWAYS run tests after migration
mix test.all

# Visually compare before/after
# 1. Screenshot before migration
# 2. Apply migration
# 3. Screenshot after migration
# 4. Compare side-by-side
```

**Why:** Fluid tokens change at different viewport sizes. Test on mobile (375px), tablet (768px), and desktop (1440px).

---

## Before/After Examples

### Example 1: Card Component Migration

**Before (Hardcoded):**
```heex
<div class="card bg-base-200 shadow-lg">
  <div class="card-body">
    <div class="flex items-start justify-between gap-4">
      <div class="min-w-0 flex-1">
        <h3 class="card-title mb-2 text-xl">
          <.icon name="hero-tag" class="h-5 w-5" />
          {tag.name}
        </h3>

        <div class="flex gap-2 text-sm">
          <div class="badge badge-neutral">{post_count} posts</div>
          <div class="badge badge-ghost gap-1">
            <.icon name="hero-globe-alt" class="h-3 w-3" />
            Public
          </div>
        </div>
      </div>

      <div class="flex flex-shrink-0 gap-1">
        <.link navigate={~p"/tags/#{tag}/edit"} class="btn btn-sm btn-ghost">
          Edit
        </.link>
      </div>
    </div>
  </div>
</div>
```

**After (Design Tokens):**
```heex
<div class="card bg-base-200 shadow-lg">
  <div class="card-body">
    <div class="flex items-start justify-between gap-[var(--space-sm)]">
      <div class="min-w-0 flex-1">
        <h3 class="card-title mb-[var(--space-xs)] text-[var(--text-xl)]">
          <.icon name="hero-tag" class="h-5 w-5" />
          {tag.name}
        </h3>

        <div class="flex gap-[var(--space-xs)] text-[var(--text-sm)]">
          <div class="badge badge-neutral">{post_count} posts</div>
          <div class="badge badge-ghost gap-[var(--space-inline)]">
            <.icon name="hero-globe-alt" class="h-3 w-3" />
            Public
          </div>
        </div>
      </div>

      <div class="flex flex-shrink-0 gap-[var(--space-inline)]">
        <.link navigate={~p"/tags/#{tag}/edit"} class="btn btn-sm btn-ghost">
          Edit
        </.link>
      </div>
    </div>
  </div>
</div>
```

**Changes:**
- `gap-4` → `gap-[var(--space-sm)]` (main container gap)
- `mb-2` → `mb-[var(--space-xs)]` (heading margin)
- `text-xl` → `text-[var(--text-xl)]` (heading size)
- `gap-2` → `gap-[var(--space-xs)]` (badge container gap)
- `text-sm` → `text-[var(--text-sm)]` (badge text size)
- `gap-1` → `gap-[var(--space-inline)]` (small inline gaps)

**Impact:**
- Mobile (375px): Tighter spacing, smaller text
- Desktop (1440px): Spacious layout, larger text
- Smooth transition across all viewport sizes

### Example 2: Form Layout Migration

**Before:**
```heex
<div class="space-y-4">
  <div class="form-control">
    <label class="label">
      <span class="label-text text-sm">Email</span>
    </label>
    <input type="email" class="input input-bordered" />
  </div>

  <div class="form-control">
    <label class="label">
      <span class="label-text text-sm">Password</span>
    </label>
    <input type="password" class="input input-bordered" />
    <label class="label">
      <span class="label-text-alt text-xs">Min 12 characters</span>
    </label>
  </div>

  <div class="flex gap-2 mt-6">
    <button class="btn btn-primary">Submit</button>
    <button class="btn btn-ghost">Cancel</button>
  </div>
</div>
```

**After:**
```heex
<div class="space-y-[var(--space-sm)]">
  <div class="form-control">
    <label class="label">
      <span class="label-text text-[var(--text-sm)]">Email</span>
    </label>
    <input type="email" class="input input-bordered" />
  </div>

  <div class="form-control">
    <label class="label">
      <span class="label-text text-[var(--text-sm)]">Password</span>
    </label>
    <input type="password" class="input input-bordered" />
    <label class="label">
      <span class="label-text-alt text-[var(--text-xs)]">Min 12 characters</span>
    </label>
  </div>

  <div class="flex gap-[var(--space-xs)] mt-[var(--space-md)]">
    <button class="btn btn-primary">Submit</button>
    <button class="btn btn-ghost">Cancel</button>
  </div>
</div>
```

**Changes:**
- `space-y-4` → `space-y-[var(--space-sm)]`
- `text-sm` → `text-[var(--text-sm)]`
- `text-xs` → `text-[var(--text-xs)]`
- `gap-2` → `gap-[var(--space-xs)]`
- `mt-6` → `mt-[var(--space-md)]`

### Example 3: Grid/Flex Layout Migration

**Before:**
```heex
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
  <div class="card">
    <div class="card-body p-4">
      <h3 class="text-lg font-semibold mb-2">Card Title</h3>
      <p class="text-sm text-base-content/60">Description text here.</p>
    </div>
  </div>
  <!-- More cards -->
</div>
```

**After:**
```heex
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-[var(--space-md)]">
  <div class="card">
    <div class="card-body p-[var(--space-sm)]">
      <h3 class="text-[var(--text-lg)] font-semibold mb-[var(--space-xs)]">Card Title</h3>
      <p class="text-[var(--text-sm)] text-base-content/60">Description text here.</p>
    </div>
  </div>
  <!-- More cards -->
</div>
```

**Changes:**
- `gap-6` → `gap-[var(--space-md)]`
- `p-4` → `p-[var(--space-sm)]`
- `text-lg` → `text-[var(--text-lg)]`
- `mb-2` → `mb-[var(--space-xs)]`
- `text-sm` → `text-[var(--text-sm)]`

**Note:** Grid columns (`grid-cols-1 md:grid-cols-2 lg:grid-cols-3`) are structural and don't need migration.

---

## Migration Checklist

Use this checklist for each file/component you migrate:

### Pre-Migration

- [ ] **Grep for hardcoded values:**
  ```bash
  grep -E "gap-[0-9]|m(t|b|l|r|x|y)-[0-9]|p(t|b|l|r|x|y)-[0-9]|text-(xs|sm|base|lg|xl|2xl)" <file>
  ```
- [ ] **Count occurrences:** Note how many values need replacement
- [ ] **Screenshot current appearance:** Visual reference for comparison
- [ ] **Check if container queries apply:** If using `.post-card` or `.listing-card`, verify container query behavior

### Migration

- [ ] **Replace spacing values:**
  - [ ] `gap-*` utilities
  - [ ] `mt-*`, `mb-*`, `ml-*`, `mr-*` utilities
  - [ ] `mx-*`, `my-*` utilities
  - [ ] `p-*`, `px-*`, `py-*` utilities
- [ ] **Replace typography values:**
  - [ ] `text-xs`, `text-sm`, `text-base`
  - [ ] `text-lg`, `text-xl`, `text-2xl`
- [ ] **Replace layout constraints (if applicable):**
  - [ ] `max-w-*` for content containers
  - [ ] `w-*` for sidebars
- [ ] **Keep unchanged:**
  - [ ] DaisyUI component classes (`btn`, `card`, `badge`)
  - [ ] Fixed-size utilities (`h-5`, `w-5`, `size-6`)
  - [ ] Color utilities (`text-gray-600`, `bg-base-200`)
  - [ ] Structural utilities (`flex`, `grid`, `items-center`)

### Post-Migration

- [ ] **Visual comparison:**
  - [ ] Screenshot after migration
  - [ ] Compare before/after side-by-side
  - [ ] Test on mobile (375px), tablet (768px), desktop (1440px)
- [ ] **Run tests:**
  ```bash
  mix test.all  # Precompile, format, test, credo
  ```
- [ ] **Verify:**
  - [ ] All tests passing
  - [ ] No visual regressions
  - [ ] Responsive behavior correct
- [ ] **Commit:**
  ```bash
  git add <file>
  git commit -m "refactor: migrate <component> to design tokens"
  ```

### Success Metrics

After completing migration:

- ✅ Zero hardcoded spacing values in migrated file
- ✅ Zero hardcoded typography values in migrated file
- ✅ All tests passing (0 failures)
- ✅ Visual parity with original design
- ✅ Improved responsive behavior at all viewport sizes

---

## Additional Resources

- **Token Reference:** `assets/css/tokens/spacing.css`, `assets/css/tokens/typography.css`
- **Design Guidelines:** `HOMESITE_DESIGN_GUIDELINES.md` (archived_docs/)
- **Practical Patterns:** `MODERN_CSS_GUIDE.md`
- **Container Queries:** `assets/css/app.css` (lines 405-474)

---

**Questions or Issues?** Check CLAUDE.md or consult the design system documentation.
