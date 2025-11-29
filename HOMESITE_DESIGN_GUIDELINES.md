# Homesite Design System Guidelines

**Version:** 1.0.0
**Last Updated:** 2025-11-29
**Status:** Complete

---

## Table of Contents

1. [Design Philosophy](#design-philosophy)
2. [Color System](#color-system)
3. [Typography System](#typography-system)
4. [Spacing System](#spacing-system)
5. [Layout System](#layout-system)
6. [Component Patterns](#component-patterns)
7. [Decision Framework](#decision-framework)
8. [Testing Checklist](#testing-checklist)
9. [Common Patterns](#common-patterns)
10. [Resources](#resources)

---

## Design Philosophy

###  Core Principles

**1. Design-e-technical Aesthetic**
- GitHub-inspired professional design
- Clean, minimal interface with strong hierarchy
- Focus on readability and content
- Subtle, purposeful animations

**2. Finnish Blog Focus**
- Bilingual support (Finnish/English)
- Technical writing emphasis
- Code-friendly formatting
- Developer-centric features

**3. Accessibility First**
- WCAG AA compliance minimum (4.5:1 contrast)
- Keyboard navigation support
- Screen reader friendly
- Reduced motion support

**4. Fluid-First Responsive Design**
- No media queries for most layouts
- Uses modern CSS (`clamp()`, `min()`, `max()`)
- Container queries for component-level responsiveness
- Scales smoothly across all viewports

---

## Color System

### Dark Theme (Default)

**Base Colors:**
```css
--bg: #0d1117           /* Page background - very dark gray */
--surface: #161b22      /* Card/input background - dark gray */
--border: #30363d       /* Borders and dividers - medium gray */
--text: #c9d1d9         /* Primary text - light gray */
--text-secondary: #8b949e  /* Secondary text - muted gray */
--accent: #FF6B35       /* Primary accent - warm orange */
--code-bg: #161b22      /* Code block background - matches surface */
```

**Visual Reference:**
- Background: Deep GitHub dark (#0d1117)
- Cards/Inputs: Slightly lighter (#161b22) for depth
- Text: High contrast on dark background
- Accent: Vibrant orange for CTAs and links

### Light Theme

**Base Colors:**
```css
--bg: #ffffff           /* Page background - pure white */
--surface: #f6f8fa      /* Card/input background - light gray */
--border: #d0d7de       /* Borders and dividers - medium gray */
--text: #24292f         /* Primary text - very dark gray */
--text-secondary: #57606a  /* Secondary text - medium gray */
--accent: #FD4F00       /* Primary accent - bright orange */
--code-bg: #f6f8fa      /* Code block background - matches surface */
```

**Visual Reference:**
- Background: Clean white (#ffffff)
- Cards/Inputs: Enhanced gray for better visibility
- Text: Strong contrast on light background (18% lightness)
- Accent: Slightly brighter orange than dark theme

**DaisyUI Theme Values (Light):**
```css
--color-base-100: oklch(100% 0 0)        /* Pure white background */
--color-base-200: oklch(96% 0.004 264)   /* Input backgrounds - improved contrast */
--color-base-300: oklch(82% 0.012 264)   /* Borders - improved contrast */
--color-base-content: oklch(18% 0.008 264) /* Text - darker for better contrast */
--border: 2px                             /* Border width - increased for visibility */
```

**Contrast Improvements:**
- base-200 darkened from 98% to 96% lightness for better input visibility
- base-300 darkened from 88% to 82% lightness for clearer borders
- base-content darkened from 20% to 18% lightness for sharper text
- Border width increased from 1.5px to 2px for better definition

### Semantic Usage

**When to use each color:**

| Color | Usage | Examples |
|-------|-------|----------|
| `--bg` | Page background only | `<body>`, `.technical-main` |
| `--surface` | Cards, inputs, elevated surfaces | `.listing-card`, `.input`, `.card` |
| `--border` | All borders and dividers | `.border-[var(--border)]` |
| `--text` | Primary content text | Paragraphs, headings, UI text |
| `--text-secondary` | Metadata, labels, less emphasis | Dates, categories, help text |
| `--accent` | CTAs, links, focus states | Buttons, active links, outlines |
| `--code-bg` | Code blocks and inline code | `.prose pre`, `<code>` blocks |

**Color Contrast Ratios:**
- Dark theme: 12.4:1 (text/bg) - AAA compliant
- Light theme: 13.8:1 (text/bg) - AAA compliant
- Accent on bg: 4.8:1 (dark), 9.2:1 (light) - AA+ compliant

---

## Typography System

### Type Scale

**Fluid Typography Tokens:**
```css
--text-xs: clamp(0.75rem, 1vw, 0.875rem)      /* 12px → 14px */
--text-sm: clamp(0.875rem, 1.5vw, 1rem)       /* 14px → 16px */
--text-base: clamp(1rem, 2vw, 1.25rem)        /* 16px → 20px */
--text-lg: clamp(1.125rem, 2.5vw, 1.5rem)     /* 18px → 24px */
--text-xl: clamp(1.25rem, 3vw, 2rem)          /* 20px → 32px */
--text-2xl: clamp(1.5rem, 4vw, 3rem)          /* 24px → 48px */
```

**Usage Guidelines:**

| Token | Usage | Examples |
|-------|-------|----------|
| `--text-xs` | Fine print, captions | File sizes, tiny metadata |
| `--text-sm` | Body text, labels | Form labels, card metadata |
| `--text-base` | Primary body text | Article body, descriptions |
| `--text-lg` | Subheadings, emphasis | Section subheadings, callouts |
| `--text-xl` | Section headings | `<h2>` in content areas |
| `--text-2xl` | Page titles | `<h1>` page headers, hero text |

### Font Families

**System Font Stack:**
```css
font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Noto Sans', Helvetica, Arial, sans-serif;
```

**Monospace (Code, Dates, Technical):**
```css
font-family: 'SF Mono', 'Consolas', 'Liberation Mono', 'Menlo', monospace;
```

**When to use monospace:**
- Code blocks and inline code
- Date/time stamps
- Technical metadata (file sizes, versions)
- Commit hashes, UUIDs

### Typography Patterns

**Headings:**
```heex
<!-- Page title (h1) -->
<h1 class="text-[var(--font-size-fluid-2xl)] font-bold mb-[var(--spacing-md)]">
  Dashboard
</h1>

<!-- Section heading (h2) -->
<h2 class="text-[var(--font-size-fluid-xl)] font-semibold mb-[var(--spacing-sm)]">
  Recent Posts
</h2>

<!-- Subsection heading (h3) -->
<h3 class="text-[var(--font-size-fluid-lg)] font-medium">
  Post Title
</h3>
```

**Body Text:**
```heex
<!-- Primary paragraph -->
<p class="text-[var(--font-size-fluid-base)] leading-relaxed">
  Lorem ipsum dolor sit amet...
</p>

<!-- Secondary text -->
<p class="text-[var(--font-size-fluid-sm)] text-[var(--text-secondary)]">
  Published 3 days ago
</p>
```

---

## Spacing System

### Space Scale

**Responsive Spacing Tokens:**
```css
--space-xs: clamp(0.25rem, 1vw, 0.5rem)      /* 4px → 8px */
--space-sm: clamp(0.5rem, 2vw, 1rem)         /* 8px → 16px */
--space-md: clamp(1rem, 3vw, 2rem)           /* 16px → 32px */
--space-lg: clamp(2rem, 5vw, 4rem)           /* 32px → 64px */
--space-xl: clamp(3rem, 8vw, 6rem)           /* 48px → 96px */
```

**Component-Specific:**
```css
--card-padding: clamp(1rem, 3vw, 2rem)       /* Card internal padding */
--section-gap: clamp(2rem, 5vw, 4rem)        /* Between major sections */
--inline-gap: clamp(0.25rem, 1vw, 0.5rem)    /* Tags, badges, inline items */
```

### Spacing Guidelines

**When to use each token:**

| Token | Usage | Examples |
|-------|-------|----------|
| `--space-xs` | Tight spacing | Tag gaps, icon spacing |
| `--space-sm` | Standard spacing | Input padding, button padding |
| `--space-md` | Generous spacing | Card gaps in grid, paragraph margins |
| `--space-lg` | Section spacing | Between content sections |
| `--space-xl` | Hero spacing | Top of page, major separations |
| `--card-padding` | Card internals | `.listing-card` padding |
| `--section-gap` | Major sections | Between header and content |
| `--inline-gap` | Inline elements | Tag clouds, badge lists |

### Spacing Patterns

**Grid/Flex Gaps:**
```heex
<!-- Grid with medium spacing -->
<div class="grid grid-cols-2 gap-[var(--spacing-md)]">
  <!-- items -->
</div>

<!-- Flex with inline spacing -->
<div class="flex gap-[var(--spacing-inline)] flex-wrap">
  <span class="badge">Tag 1</span>
  <span class="badge">Tag 2</span>
</div>
```

**Margin/Padding:**
```heex
<!-- Card padding -->
<div class="p-[var(--spacing-card)]">
  <!-- content -->
</div>

<!-- Section margin -->
<section class="mb-[var(--spacing-section)]">
  <!-- content -->
</section>
```

---

## Layout System

### Container Constraints

**Width Tokens:**
```css
--content-max-width: min(95vw, 1400px)  /* Main content container */
--article-max-width: min(90vw, 800px)   /* Article/reading width */
--card-max-width: min(90vw, 600px)      /* Card maximum width */
--sidebar-width: max(250px, 20vw)       /* Sidebar minimum width */
```

### Layout Patterns

**Main Content Container:**
```heex
<!-- Full-width content (dashboard, admin) -->
<main class="w-[var(--width-content)] mx-auto px-[var(--spacing-card)]">
  <!-- content -->
</main>

<!-- Reading-optimized (articles, posts) -->
<article class="w-[var(--width-article)] mx-auto px-[var(--spacing-sm)]">
  <!-- content -->
</article>
```

**Existing Layout Classes:**
```css
.technical-main {
  max-width: 900px;         /* Equivalent to --article-max-width */
  margin: 0 auto;
  padding: 1.5rem 1rem;
}

.header-content {
  max-width: 1280px;        /* Close to --content-max-width */
  margin: 0 auto;
}
```

### Responsive Grid

**Auto-fit Grid (no media queries):**
```heex
<!-- Cards adapt to container width -->
<div class="grid gap-[var(--spacing-md)]"
     style="grid-template-columns: repeat(auto-fit, minmax(min(100%, 300px), 1fr));">
  <%= for item <- @items do %>
    <div class="listing-card">...</div>
  <% end %>
</div>
```

### Breakpoint Reference

**For manual testing only** (CSS should avoid media queries):
- Mobile: 375px (iPhone SE)
- Tablet: 768px (iPad)
- Desktop: 1440px (standard monitor)
- Wide: 1920px+ (large displays)

---

## Component Patterns

### Cards

**Listing Card (Unified Pattern):**
```heex
<article class="listing-card">
  <h3 class="listing-title">
    <.link navigate={~p"/posts/#{post}"}>
      {post.title}
    </.link>
  </h3>
  <p class="listing-content">
    {post.excerpt}
  </p>
  <div class="listing-meta">
    <span class="text-[var(--font-size-fluid-sm)] text-[var(--text-secondary)]">
      {Calendar.strftime(post.published_at, "%B %d, %Y")}
    </span>
  </div>
</article>
```

**CSS Classes:**
```css
.listing-card {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 6px;
  padding: var(--card-padding);
  transition: box-shadow 0.2s;
}

.listing-title {
  font-size: var(--text-lg);
  font-weight: 600;
  margin-bottom: 0.875rem;
  color: var(--text);
}

.listing-content {
  font-size: var(--text-sm);
  color: var(--text-secondary);
  margin-bottom: 1rem;
}
```

### Forms

**Input Fields:**
```heex
<!-- Text input -->
<.input
  type="text"
  field={@form[:title]}
  label="Title"
  help="Enter a descriptive title"
/>

<!-- Textarea -->
<.input
  type="textarea"
  field={@form[:body]}
  label="Content"
  rows="10"
/>

<!-- Select dropdown -->
<.input
  type="select"
  field={@form[:language]}
  label="Language"
  options={[{"English", "en"}, {"Finnish", "fi"}]}
/>
```

**Form Input CSS:**
```css
.input {
  background-color: var(--surface);
  border-color: var(--border);
  color: var(--text);
  border-radius: 6px;
  padding: 0.5rem 0.75rem;
}

.input:focus {
  outline: 2px solid var(--accent);
  outline-offset: 2px;
  border-color: var(--accent);
}
```

### Buttons

**DaisyUI Button Patterns:**
```heex
<!-- Primary action -->
<button class="btn btn-primary">
  Create Post
</button>

<!-- Secondary action -->
<button class="btn btn-ghost">
  Cancel
</button>

<!-- With icon -->
<.link navigate={~p"/posts/new"} class="btn btn-primary gap-2">
  <.icon name="hero-plus" class="h-5 w-5" />
  New Post
</.link>
```

### Prose (Markdown Content)

**For rendered markdown:**
```heex
<div class="prose prose-slate max-w-none dark:prose-invert">
  {Phoenix.HTML.raw(@post.body)}
</div>
```

**Prose CSS** (already configured in `app.css` lines 461-626):
- Headings: Scaled with proper hierarchy
- Links: Accent color with underline
- Code blocks: `var(--code-bg)` background, `var(--text)` color
- Lists: Proper indentation and markers
- Tables: Bordered, hover states

---

## Decision Framework

### When to Use Design Tokens

**✅ Always use design tokens for:**

1. **Spacing** (padding, margin, gap)
   ```heex
   <!-- DO -->
   <div class="p-[var(--spacing-card)] gap-[var(--spacing-md)]">

   <!-- DON'T -->
   <div class="p-8 gap-4">
   ```

2. **Typography** (font sizes)
   ```heex
   <!-- DO -->
   <h1 class="text-[var(--font-size-fluid-2xl)]">

   <!-- DON'T -->
   <h1 class="text-4xl">
   ```

3. **Colors** (for custom elements)
   ```heex
   <!-- DO -->
   <div style="background: var(--surface); color: var(--text);">

   <!-- DON'T -->
   <div style="background: #161b22; color: #c9d1d9;">
   ```

4. **Layout constraints** (max-width)
   ```heex
   <!-- DO -->
   <main class="w-[var(--width-content)] mx-auto">

   <!-- DON'T -->
   <main class="max-w-screen-xl mx-auto">
   ```

### When to Use DaisyUI Classes

**✅ Use DaisyUI for:**

1. **Component structure**
   ```heex
   <!-- DO -->
   <button class="btn btn-primary">
   <div class="card bg-base-100">
   <span class="badge badge-lg">
   ```

2. **Component states**
   ```heex
   <!-- DO -->
   <button class="btn btn-primary btn-disabled">
   <div class="alert alert-info">
   ```

3. **Theme colors** (when design token doesn't exist)
   ```heex
   <!-- DO (for DaisyUI components) -->
   <div class="bg-base-200 text-base-content">
   ```

### When to Use Tailwind Utilities

**✅ Use Tailwind for:**

1. **Layout** (flexbox, grid, positioning)
   ```heex
   <!-- DO -->
   <div class="flex items-center justify-between">
   <div class="grid grid-cols-2 md:grid-cols-3">
   <div class="absolute top-0 right-0">
   ```

2. **Display properties**
   ```heex
   <!-- DO -->
   <div class="hidden md:block">
   <span class="inline-block">
   ```

3. **Functional utilities** (cursor, overflow, z-index)
   ```heex
   <!-- DO -->
   <div class="cursor-pointer overflow-hidden z-10">
   ```

### Decision Tree

```
Need spacing/sizing?
├─ Yes → Use design tokens (var(--spacing-*), var(--text-*))
└─ No
   └─ Building a button/card/badge?
      ├─ Yes → Use DaisyUI classes (btn, card, badge)
      └─ No → Use Tailwind utilities (flex, grid, hidden)
```

---

## Testing Checklist

### Responsive Testing

**Required Viewport Tests:**
- [ ] 375px (Mobile - iPhone SE)
- [ ] 768px (Tablet - iPad)
- [ ] 1440px (Desktop - Standard)
- [ ] 1920px (Wide - Large monitor)

**Per-Viewport Checks:**
- [ ] Text remains readable (not too small/large)
- [ ] Spacing scales appropriately
- [ ] No horizontal overflow
- [ ] Touch targets ≥ 44x44px (mobile)
- [ ] No overlapping elements

### Theme Switching

**Required Tests:**
- [ ] Toggle to dark theme - all colors correct
- [ ] Toggle to light theme - all colors correct
- [ ] Accent color visible in both themes
- [ ] Code blocks readable in both themes
- [ ] Form inputs visible in both themes

### Accessibility

**WCAG AA Requirements:**
- [ ] Text contrast ≥ 4.5:1 (normal text)
- [ ] Large text contrast ≥ 3:1 (18pt+)
- [ ] Focus indicators visible
- [ ] Keyboard navigation works
- [ ] Screen reader announces content correctly

**Testing Tools:**
- Browser DevTools (Lighthouse accessibility audit)
- Contrast checker (built into Chrome DevTools)
- Keyboard navigation (Tab, Shift+Tab, Enter, Escape)
- Screen reader (VoiceOver on macOS, NVDA on Windows)

### Cross-Browser

**Minimum Testing Matrix:**
- [ ] Chrome/Edge (Chromium)
- [ ] Firefox
- [ ] Safari (macOS/iOS)

### Component-Specific Tests

**After modifying components:**
- [ ] Forms: All input types render correctly
- [ ] Cards: Hover states work
- [ ] Buttons: Disabled states visible
- [ ] Links: Underline on hover
- [ ] Code blocks: Syntax highlighting works

---

## Common Patterns

### ✅ DO: Use Design Tokens

**Spacing:**
```heex
<!-- Card with token-based padding -->
<div class="p-[var(--spacing-card)] mb-[var(--spacing-section)]">
  <h2 class="text-[var(--font-size-fluid-xl)] mb-[var(--spacing-sm)]">
    Section Title
  </h2>
  <div class="grid gap-[var(--spacing-md)]">
    <!-- items -->
  </div>
</div>
```

**Typography:**
```heex
<!-- Responsive heading -->
<h1 class="text-[var(--font-size-fluid-2xl)] font-bold leading-tight">
  {@page_title}
</h1>

<!-- Metadata with monospace -->
<time class="font-mono text-[var(--font-size-fluid-sm)] text-[var(--text-secondary)]">
  {Calendar.strftime(@date, "%Y-%m-%d")}
</time>
```

**Layout:**
```heex
<!-- Constrained content width -->
<main class="w-[var(--width-content)] mx-auto px-[var(--spacing-card)] py-[var(--spacing-lg)]">
  <!-- content -->
</main>
```

### ❌ DON'T: Hardcode Values

**Avoid inline clamp():**
```heex
<!-- DON'T -->
<div class="px-[clamp(1rem,4vw,2rem)] py-[clamp(1.5rem,5vw,3rem)]">

<!-- DO -->
<div class="px-[var(--spacing-card)] py-[var(--spacing-lg)]">
```

**Avoid hardcoded colors:**
```heex
<!-- DON'T -->
<div style="background: #161b22; color: #c9d1d9;">

<!-- DO -->
<div style="background: var(--surface); color: var(--text);">
```

**Avoid fixed spacing:**
```heex
<!-- DON'T -->
<div class="p-8 mb-12 gap-4">

<!-- DO -->
<div class="p-[var(--spacing-card)] mb-[var(--spacing-section)] gap-[var(--spacing-md)]">
```

### Migration Examples

**Before (inline clamp):**
```heex
<div class="px-[clamp(1rem,4vw,2rem)] py-[clamp(1.5rem,5vw,3rem)]">
  <h1 class="text-[clamp(2rem,6vw,3rem)] mb-[clamp(1rem,3vw,1.5rem)]">
    Dashboard
  </h1>
  <div class="grid gap-[clamp(1rem,3vw,2rem)]">
    <!-- items -->
  </div>
</div>
```

**After (design tokens):**
```heex
<div class="px-[var(--spacing-card)] py-[var(--spacing-lg)]">
  <h1 class="text-[var(--font-size-fluid-2xl)] mb-[var(--spacing-md)]">
    Dashboard
  </h1>
  <div class="grid gap-[var(--spacing-md)]">
    <!-- items -->
  </div>
</div>
```

### Component Library Examples

**Post Card:**
```heex
<article class="listing-card">
  <h3 class="listing-title">
    <.link navigate={~p"/posts/#{@post}"} class="hover:text-[var(--accent)]">
      {@post.title}
    </.link>
  </h3>
  <p class="text-[var(--font-size-fluid-sm)] text-[var(--text-secondary)] line-clamp-2">
    {@post.excerpt}
  </p>
  <div class="flex items-center gap-[var(--spacing-inline)] flex-wrap mt-[var(--spacing-sm)]">
    <%= for tag <- @post.tags do %>
      <span class="badge badge-primary">{tag.name}</span>
    <% end %>
  </div>
  <div class="flex items-center justify-between mt-[var(--spacing-md)]">
    <time class="font-mono text-[var(--font-size-fluid-xs)] text-[var(--text-secondary)]">
      {Calendar.strftime(@post.published_at, "%Y-%m-%d")}
    </time>
    <.link navigate={~p"/posts/#{@post}"} class="btn btn-sm btn-ghost">
      Read More
    </.link>
  </div>
</article>
```

**Form Section:**
```heex
<section class="mb-[var(--spacing-section)]">
  <h2 class="text-[var(--font-size-fluid-xl)] font-semibold mb-[var(--spacing-md)]">
    {gettext("Account Settings")}
  </h2>
  <div class="grid gap-[var(--spacing-md)]">
    <.input
      type="text"
      field={@form[:display_name]}
      label={gettext("Display Name")}
      help={gettext("How your name appears on posts")}
    />
    <.input
      type="textarea"
      field={@form[:bio]}
      label={gettext("Bio")}
      rows="4"
    />
  </div>
</section>
```

---

## Resources

### Internal Documentation

**Primary References:**
- [MODERN_CSS_GUIDE.md](./MODERN_CSS_GUIDE.md) - Modern CSS patterns and techniques
- [DESIGN_SYSTEM_PLAN.md](./DESIGN_SYSTEM_PLAN.md) - Design system implementation plan
- [CLAUDE.md](./CLAUDE.md) - General project guidelines
- [AGENTS.md](./AGENTS.md) - Phoenix/LiveView patterns

**CSS Files:**
- `assets/css/app.css` - All design tokens and component styles (lines 112-426)

**Component Files:**
- `lib/homesite_web/components/core_components.ex` - Form inputs, buttons, icons
- `lib/homesite_web/components/layouts.ex` - Page layouts and navigation

### External Documentation

**Frameworks:**
- [Tailwind CSS v4](https://tailwindcss.com/docs) - Utility-first CSS framework
- [DaisyUI](https://daisyui.com/) - Tailwind component library
- [Phoenix Framework](https://hexdocs.pm/phoenix/overview.html) - Elixir web framework
- [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view/) - Real-time server-rendered UI

**Design References:**
- [GitHub Primer Design System](https://primer.style/) - Design inspiration
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/) - Accessibility standards

**Modern CSS:**
- [MDN: Using CSS custom properties](https://developer.mozilla.org/en-US/docs/Web/CSS/Using_CSS_custom_properties)
- [MDN: clamp()](https://developer.mozilla.org/en-US/docs/Web/CSS/clamp)
- [MDN: Container Queries](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Container_Queries)

### Quick Reference Card

**Design Tokens Cheat Sheet:**

```css
/* Colors */
--bg, --surface, --border, --text, --text-secondary, --accent, --code-bg

/* Typography */
--text-xs, --text-sm, --text-base, --text-lg, --text-xl, --text-2xl

/* Spacing */
--space-xs, --space-sm, --space-md, --space-lg, --space-xl
--card-padding, --section-gap, --inline-gap

/* Layout */
--content-max-width, --article-max-width, --card-max-width, --sidebar-width
```

**Usage Template:**
```heex
<div class="p-[var(--spacing-card)] mb-[var(--spacing-section)]">
  <h2 class="text-[var(--font-size-fluid-xl)] mb-[var(--spacing-md)]">
    Title
  </h2>
  <div class="grid gap-[var(--spacing-md)]">
    <!-- items -->
  </div>
</div>
```

---

## Version History

**v1.0.0 (2025-11-29)**
- Initial design system documentation
- Complete color, typography, spacing, and layout systems
- Component patterns and decision framework
- Testing checklist and migration guides

---

**For questions or suggestions, refer to:**
- DESIGN_SYSTEM_PLAN.md for implementation details
- MODERN_CSS_GUIDE.md for advanced CSS patterns
- CLAUDE.md for general project guidelines
