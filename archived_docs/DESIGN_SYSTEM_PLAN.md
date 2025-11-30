# Design System Implementation Plan

**Based on:** https://www.nathanonn.com/claude-skill-design-system-reusable-frontend/

**Status:** Planning complete - ready for implementation

**Estimated Time:** 30 minutes initial setup + ongoing refinement

---

## Overview

Transform the Homesite application's current Tailwind CSS + DaisyUI design into a documented, reusable design system using Claude Skills. This ensures consistency across all pages and makes the design portable to future projects.

## Goals

- 📐 **Codify current design** - Document existing Tailwind + DaisyUI patterns
- 🎨 **Create design variants** - Generate alternative themes for future use
- 📚 **Build component library** - Interactive reference with all UI components
- ♻️ **Make it reusable** - Package as Claude Skill for instant application
- 🚀 **Enable rapid iteration** - Apply design changes across entire app instantly

## Current Design Context

**Technology Stack:**
- Tailwind CSS v4 (no config file, uses `@import "tailwindcss"`)
- DaisyUI components
- Custom CSS in `assets/css/app.css`
- Phoenix LiveView templates (.heex files)

**Existing Components:**
- Navigation (desktop + mobile)
- Forms (posts, tags, user settings)
- Cards (post listings, tag badges)
- Buttons (primary, secondary, icon-only)
- Tables (admin dashboards)
- Modals (LiveView)
- Flash messages
- Language toggle
- Theme toggle (light/dark)

**Color Scheme:**
- Primary: DaisyUI defaults
- Backgrounds: Base colors
- Text: Neutral grays
- Accents: Theme-aware

---

## Six-Step Implementation Process

### Step 1: Design Exploration (5 minutes)

**Objective:** Generate 5 design variants from current Homesite design

**Action:**
1. Extract current homepage/dashboard HTML
2. Use Claude Code `frontend-design` skill (if available)
3. Request 5 personality variants:
   - "Neo-Brutalist blog platform"
   - "Glass Aurora minimal design"
   - "Editorial Mono typography-focused"
   - "Warm Nordic minimalism"
   - "Tech publication modern"

**Alternative (if no skill):**
Manually create design exploration document with:
- Current design screenshot/HTML
- Desired aesthetic directions
- Component inventory

**Output:** 5 HTML files with different design personalities

---

### Step 2: Design Refinement (2 minutes)

**Objective:** Select preferred variant and create theme variations

**Action:**
1. Review 5 variants
2. Select best match for Homesite brand
3. Request complementary themes:
   - Light mode optimization
   - Dark mode optimization
   - High contrast accessibility
   - Reduced motion version

**Decision Criteria:**
- Maintains Finnish blog aesthetic
- Works with existing DaisyUI components
- Accessible and readable
- Mobile-responsive

**Output:** Refined design with theme variations

---

### Step 3: Documentation Generation (10 minutes)

**Objective:** Create comprehensive design system documentation

**Action:** Use Claude Web with both HTML files

**Request Part A: Design Guidelines Markdown**

Create `HOMESITE_DESIGN_GUIDELINES.md` with:

```markdown
# Homesite Design System

## Design Philosophy
- Finnish minimalism
- Typography-first content
- Accessible by default
- Mobile-responsive patterns

## CSS Variables
### Colors
- Primary palette
- Neutral grays
- Semantic colors (success, error, warning)
- Background layers

### Spacing
- Base unit: 0.25rem (4px)
- Scale: 0, 1, 2, 3, 4, 6, 8, 12, 16, 24, 32

### Typography
- Font families (system fonts)
- Size scale (xs, sm, base, lg, xl, 2xl, 3xl, 4xl)
- Line heights
- Font weights

## Component Classes
### Layout
- Container widths
- Grid systems
- Flexbox patterns

### Cards
- Post cards
- Tag badges
- User profiles

### Buttons
- Primary, secondary, ghost
- Sizes: sm, base, lg
- States: hover, active, disabled

### Forms
- Input fields
- Textareas
- Checkboxes/toggles
- Select dropdowns
- Validation states

### Navigation
- Desktop navbar
- Mobile menu
- Breadcrumbs
- Pagination

## Responsive Breakpoints
- sm: 640px
- md: 768px
- lg: 1024px
- xl: 1280px
- 2xl: 1536px

## Animation Guidelines
- Transition timing
- Hover effects
- Loading states
- Page transitions

## Accessibility
- ARIA patterns
- Focus indicators
- Color contrast ratios
- Screen reader support
```

**Request Part B: Interactive Style Guide HTML**

Create `homesite-style-guide.html` with:

```html
<!DOCTYPE html>
<html>
<head>
  <title>Homesite Design System</title>
  <!-- Self-contained CSS -->
</head>
<body>
  <!-- Live component examples -->
  <section id="colors">
    <h2>Color Palette</h2>
    <!-- Color swatches with hex codes -->
  </section>

  <section id="typography">
    <h2>Typography</h2>
    <!-- Font examples at all sizes -->
  </section>

  <section id="buttons">
    <h2>Buttons</h2>
    <!-- All button variants, sizes, states -->
  </section>

  <section id="forms">
    <h2>Form Elements</h2>
    <!-- Input fields, validation states -->
  </section>

  <section id="cards">
    <h2>Cards & Content</h2>
    <!-- Post cards, tag badges -->
  </section>

  <section id="navigation">
    <h2>Navigation</h2>
    <!-- Nav examples -->
  </section>

  <section id="layout">
    <h2>Layout Patterns</h2>
    <!-- Grid examples, containers -->
  </section>
</body>
</html>
```

**Output:**
- HOMESITE_DESIGN_GUIDELINES.md (~300 lines)
- homesite-style-guide.html (interactive reference)

---

### Step 3.5: Design Tokens Implementation (NEW)

**Objective:** Integrate MODERN_CSS_GUIDE.md patterns into design system documentation

**Action:** Enhance HOMESITE_DESIGN_GUIDELINES.md with proven CSS patterns

**CSS Custom Properties (from MODERN_CSS_GUIDE.md):**

```css
/* assets/css/app.css */
:root {
  /* Layout Constraints */
  --content-max-width: min(95vw, 1400px);
  --article-max-width: min(90vw, 800px);
  --card-max-width: min(90vw, 600px);
  --sidebar-width: max(250px, 20vw);

  /* Fluid Typography */
  --text-xs: clamp(0.75rem, 1vw, 0.875rem);
  --text-sm: clamp(0.875rem, 1.5vw, 1rem);
  --text-base: clamp(1rem, 2vw, 1.25rem);
  --text-lg: clamp(1.125rem, 2.5vw, 1.5rem);
  --text-xl: clamp(1.25rem, 3vw, 2rem);
  --text-2xl: clamp(1.5rem, 4vw, 3rem);

  /* Responsive Spacing */
  --space-xs: clamp(0.25rem, 1vw, 0.5rem);
  --space-sm: clamp(0.5rem, 2vw, 1rem);
  --space-md: clamp(1rem, 3vw, 2rem);
  --space-lg: clamp(2rem, 5vw, 4rem);
  --space-xl: clamp(3rem, 8vw, 6rem);

  /* Component-Specific */
  --card-padding: clamp(1rem, 3vw, 2rem);
  --section-gap: clamp(2rem, 5vw, 4rem);
  --inline-gap: clamp(0.25rem, 1vw, 0.5rem);
}
```

**Component Patterns from MODERN_CSS_GUIDE.md:**

```heex
<!-- Blog Post Card (with container queries) -->
<div class="post-card card bg-base-100 shadow-xl w-[min(90vw,800px)]">
  <div class="card-body p-[clamp(1rem,3vw,2rem)]">
    <h2 class="card-title text-[clamp(1.25rem,3vw,2rem)]">
      <%= @post.title %>
    </h2>
    <p class="text-[clamp(0.875rem,1.5vw,1rem)] text-base-content/70">
      <%= @post.excerpt %>
    </p>
    <div class="card-actions gap-[clamp(0.25rem,1vw,0.5rem)]">
      <%= for tag <- @post.tags do %>
        <span class="badge badge-primary"><%= tag.name %></span>
      <% end %>
    </div>
  </div>
</div>

<!-- Responsive Grid Layout (no media queries needed) -->
<div class="grid gap-[clamp(1rem,3vw,2rem)] w-[min(95vw,1400px)] mx-auto"
     style="grid-template-columns: repeat(auto-fit, minmax(min(100%, 300px), 1fr));">
  <%= for post <- @posts do %>
    <article class="card bg-base-200">
      <!-- post content -->
    </article>
  <% end %>
</div>

<!-- Responsive Navbar -->
<div class="navbar bg-base-100 px-[clamp(1rem,5vw,4rem)] min-h-[max(4rem,10vh)]">
  <div class="navbar-start">
    <.link navigate={~p"/"} class="btn btn-ghost text-[clamp(1rem,2.5vw,1.5rem)]">
      Homesite
    </.link>
  </div>
  <div class="navbar-end gap-[clamp(0.5rem,2vw,1rem)]">
    <!-- nav links -->
  </div>
</div>
```

**Container Queries for Component-Level Responsiveness:**

```css
/* assets/css/app.css */
.post-card {
  container-type: inline-size;
}

@container (max-width: 500px) {
  .post-card .card-body {
    padding: 1rem;
  }
  .post-card .card-actions {
    flex-direction: column;
    align-items: start;
  }
  .post-card .card-title {
    font-size: 1.25rem;
  }
}

@container (min-width: 501px) {
  .post-card .card-body {
    padding: 2rem;
  }
}
```

**Why This Matters:**
- **No media queries needed** - Modern CSS functions handle most responsiveness
- **Component-scoped** - Container queries respond to parent size, not viewport
- **Fluid by default** - clamp/min/max create smooth scaling
- **DaisyUI compatible** - Works alongside DaisyUI utilities

**Reference:** MODERN_CSS_GUIDE.md (lines 1-404)

---

### Step 4: Skill Packaging (5 minutes)

**Objective:** Package documentation into reusable Claude Skill

**Action:** Use Claude's `skill-creator` tool

**Prompt:**
```
Create a Claude Skill from this design system documentation.

Skill name: homesite-design
Category: design
Description: Finnish blog platform design system with Tailwind CSS v4 + DaisyUI

Files to include:
- SKILL.md (implementation guidance)
- references/design-tokens.md (CSS variables)
- assets/template.html (component library)
```

**Skill Structure:**
```
.claude/skills/homesite-design/
├── skill.json
├── SKILL.md
├── references/
│   ├── design-tokens.md
│   ├── components.md
│   └── accessibility.md
└── assets/
    ├── template.html
    └── screenshots/
```

**Output:** Downloadable skill package

---

### Step 5: Installation (2 minutes)

**Action:**
1. Download skill package
2. Move to `.claude/skills/homesite-design/`
3. Verify structure

**Location:**
```bash
.claude/
├── insights/           # Insights Logger
└── skills/            # Claude Skills
    └── homesite-design/  # Design system skill
```

**No configuration needed** - Claude automatically detects skills

---

### Step 6: Application (10 minutes)

**Objective:** Apply design system to existing pages

**Usage:**
```
User: "Apply homesite-design skill to the post form"
Claude: Analyzes lib/homesite_web/live/post_live/form.ex
        Maps design patterns to components
        Applies consistent styling
        Maintains semantic HTML
```

**Application Order:**
1. Core layouts (root, app)
2. Navigation (navbar, mobile menu)
3. Forms (posts, tags, settings)
4. Cards (listings, profiles)
5. Dashboards (user, admin)
6. Public pages (homepage, posts)

**Verification:**
- Visual consistency across all pages
- Responsive behavior maintained
- Accessibility preserved
- No regressions in functionality

---

## Testing Strategy

### Visual Testing

**Responsive Breakpoints Validation:**
Test at these critical widths (from MODERN_CSS_GUIDE.md):
- **Mobile:** 375px (iPhone SE)
- **Tablet:** 768px (iPad)
- **Desktop:** 1440px (standard monitor)
- **Wide:** 1920px+ (large displays)

**Typography Scaling Verification:**
- Ensure clamp() values scale smoothly
- Test all heading levels (h1-h6)
- Verify body text readability at all breakpoints
- Check line-height maintains readability

**Color Contrast Ratios (WCAG AA minimum):**
- Normal text: 4.5:1 minimum
- Large text (18pt+): 3:1 minimum
- Test with browser DevTools contrast checker
- Verify in both light and dark themes

**Container Query Behavior:**
- Test components in different parent widths
- Verify breakpoints work independently of viewport
- Check nested container query performance

### Component Testing

**Unit Tests for Design Token Utilities:**
```elixir
# test/homesite_web/design_system/tokens_test.exs
defmodule HomesiteWeb.DesignSystem.TokensTest do
  use ExUnit.Case

  test "CSS custom properties are defined" do
    # Test that CSS variables are accessible
  end

  test "clamp() values have valid min/preferred/max" do
    # Validate clamp() syntax
  end

  test "color tokens reference DaisyUI theme" do
    # Ensure semantic color tokens exist
  end
end
```

**Integration Tests for Composed Components:**
```elixir
# test/homesite_web/live/design_system_test.exs
defmodule HomesiteWeb.DesignSystemTest do
  use HomesiteWeb.ConnCase
  import Phoenix.LiveViewTest

  test "post card renders with responsive classes", %{conn: conn} do
    post = post_fixture()
    {:ok, view, _html} = live(conn, ~p"/posts/#{post}")

    assert has_element?(view, ".post-card")
    assert has_element?(view, ".card-body[class*='clamp']")
  end

  test "navigation uses fluid spacing", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/")

    assert html =~ "navbar"
    assert html =~ "clamp"
  end
end
```

**Accessibility Audit Automation:**
- Use Lighthouse CI for automated accessibility scoring
- Target: 90+ accessibility score
- Test keyboard navigation
- Verify ARIA attributes
- Check focus indicators visibility

**Cross-Browser Compatibility Matrix:**
| Browser | Version | Status |
|---------|---------|--------|
| Chrome | Latest | ✅ Primary |
| Firefox | Latest | ✅ Primary |
| Safari | Latest | ✅ iOS/macOS |
| Edge | Latest | ✅ Windows |

### Regression Testing

**Screenshot Comparison (before/after):**
```bash
# Using Playwright or Percy
playwright test --project=chromium --grep @visual-regression
```

**Layout Shift Metrics:**
- Target CLS (Cumulative Layout Shift): < 0.1
- Monitor with Chrome DevTools Performance panel
- Test during page load and interactions

**Performance Budget Validation:**
| Metric | Budget | Current |
|--------|--------|---------|
| CSS bundle size | < 50KB | TBD |
| First Contentful Paint | < 1.5s | TBD |
| Time to Interactive | < 3.0s | TBD |

**CSS Bundle Size Tracking:**
```bash
# Check compiled CSS size
mix assets.build
ls -lh priv/static/assets/app.css
```

### Automated Testing Scripts

**Visual Regression Test Script:**

```bash
#!/bin/bash
# test/design_system/visual_test.sh

echo "Running visual regression tests..."

# Test key pages at multiple breakpoints
pages=("/posts" "/posts/1" "/tags" "/users/settings" "/admin")
viewports=("375,667" "768,1024" "1440,900" "1920,1080")

for page in "${pages[@]}"; do
  for viewport in "${viewports[@]}"; do
    width=$(echo $viewport | cut -d',' -f1)
    height=$(echo $viewport | cut -d',' -f2)
    echo "Testing $page at ${width}x${height}"

    # Add screenshot logic here (Playwright)
    # playwright screenshot --viewport-size=${viewport} http://localhost:4000${page}
  done
done

echo "Visual regression tests complete!"
```

**Contrast Ratio Test:**

```elixir
# test/homesite_web/design_system/contrast_test.exs
defmodule HomesiteWeb.DesignSystem.ContrastTest do
  use ExUnit.Case

  # Define color pairs that must meet contrast requirements
  @color_pairs [
    %{name: "primary text", foreground: "#000000", background: "#FFFFFF", min_ratio: 4.5},
    %{name: "secondary text", foreground: "#666666", background: "#FFFFFF", min_ratio: 4.5},
    %{name: "primary button", foreground: "#FFFFFF", background: "#570DF8", min_ratio: 4.5},
    # Add more pairs from DaisyUI theme
  ]

  test "text colors meet WCAG AA standards" do
    Enum.each(@color_pairs, fn pair ->
      ratio = calculate_contrast_ratio(pair.foreground, pair.background)

      assert ratio >= pair.min_ratio,
        "#{pair.name} has contrast ratio #{ratio}, expected >= #{pair.min_ratio}"
    end)
  end

  # Implement WCAG contrast ratio calculation
  defp calculate_contrast_ratio(fg, bg) do
    # Convert hex to RGB, calculate luminance, compute ratio
    # Reference: https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html
    21.0 # Placeholder
  end
end
```

### Testing Best Practices

**DO ✅:**
- Test at 4+ breakpoints before committing changes
- Run visual regression tests after design updates
- Verify accessibility with automated tools
- Test with keyboard navigation
- Check color contrast programmatically
- Monitor CSS bundle size

**DON'T ❌:**
- Skip testing on mobile viewports
- Assume design works without verification
- Deploy without accessibility audit
- Ignore performance budgets
- Test only in one browser

**Testing Workflow:**
1. Make design changes
2. Run unit tests: `mix test test/homesite_web/design_system/`
3. Run visual regression: `./test/design_system/visual_test.sh`
4. Run accessibility audit: Lighthouse in Chrome DevTools
5. Check CSS bundle size: `ls -lh priv/static/assets/app.css`
6. Commit if all tests pass

---

## Integration with Existing Workflow

### Use with Insights Logger
When applying design changes, log insights:
```
"Gotcha: DaisyUI toggle component requires specific class order"
"Important pattern: Container max-width maintains readability"
```

### Use with EOD Workflow
Design system updates automatically committed:
- MEMO.md notes design changes
- Commits reference component updates
- GitHub issues track design iterations

---

## Homesite-Specific Considerations

### Current Challenges

**Tailwind v4 Specifics:**
- No `tailwind.config.js` file
- Uses `@import "tailwindcss"` in CSS
- Source paths defined in CSS with `@source`
- Must document this unique setup
- **NEW:** Uses `@theme` directive for design tokens (see Best Practices section)

**Example @theme usage:**
```css
/* assets/css/app.css */
@import "tailwindcss" source(none);
@source "../css";
@source "../js";
@source "../../lib/homesite_web";

@theme {
  --font-size-base: clamp(1rem, 2vw, 1.25rem);
  --spacing-md: clamp(1rem, 3vw, 2rem);
  --content-max-width: min(95vw, 1400px);
}
```

See **Best Practices → Tailwind v4 @theme Directive Usage** for complete implementation.

**DaisyUI Integration:**
- DaisyUI classes mixed with custom Tailwind
- Theme switching mechanism
- Component overrides
- Need clear separation in documentation

**Phoenix LiveView:**
- Server-rendered components
- HEEx template syntax
- LiveView-specific patterns (phx-* attributes)
- Component slot patterns

**Internationalization:**
- Finnish + English UI
- RTL considerations for future
- Language-specific typography

### Design System Scope

**In Scope:**
- ✅ Layout patterns (containers, grids)
- ✅ Typography system
- ✅ Color palette
- ✅ Component styling
- ✅ Responsive breakpoints
- ✅ Animation timing
- ✅ Accessibility patterns

**Out of Scope:**
- ❌ Backend logic
- ❌ Database schemas
- ❌ LiveView event handling
- ❌ Business logic

---

## Benefits for Homesite

### Immediate Benefits

**Consistency:**
- All forms follow same pattern
- Buttons styled uniformly
- Cards have consistent spacing
- Typography hierarchy clear

**Documentation:**
- New developers reference style guide
- No guessing on spacing/colors
- Component examples always available
- Design decisions documented

**Rapid Iteration:**
- Change color palette instantly
- Update spacing scale globally
- Refine typography across app
- Test alternative themes

### Long-Term Benefits

**Portability:**
- Reuse design in future projects
- Package as open-source template
- Share with community

**Maintainability:**
- Single source of truth
- Version controlled design
- Easy rollback if needed
- Clear change history

**Scalability:**
- New pages inherit design automatically
- Components compose predictably
- Team members apply design consistently

---

## Testable Implementation Checklist

### Phase 0: Pre-Implementation (Preparation - 15 minutes)

- [ ] Read DESIGN_SYSTEM_PLAN.md completely
- [ ] Review MODERN_CSS_GUIDE.md patterns (lines 1-404)
- [ ] Set up visual testing tool (Playwright screenshots recommended)
- [ ] Create test branch: `git checkout -b design-system-implementation`
- [ ] Backup current CSS: `cp assets/css/app.css assets/css/app.css.backup`

**Success Criteria:**
- Test branch created
- Development environment ready
- Backup files created

---

### Phase 1: Design Token Definition (30 minutes)

- [ ] Extract current colors from DaisyUI theme
- [ ] Add CSS custom properties to `assets/css/app.css` (see Step 3.5)
- [ ] Create semantic token names (`--color-primary`, `--text-base`, etc.)
- [ ] Test tokens in browser DevTools (inspect element, check computed values)
- [ ] Verify clamp() values scale correctly at 375px, 768px, 1440px
- [ ] Run `mix assets.build` to compile CSS
- [ ] Commit: `git commit -m "feat: Define design system tokens"`

**Success Criteria:**
- [ ] CSS custom properties defined in `:root`
- [ ] Tokens accessible in DevTools
- [ ] Fluid scaling works at all breakpoints
- [ ] CSS compiles without errors

**Test Command:**
```bash
mix assets.build
ls -lh priv/static/assets/app.css
```

---

### Phase 2: Component Documentation (1 hour)

- [ ] Create `HOMESITE_DESIGN_GUIDELINES.md` in project root
- [ ] Document typography system with clamp() examples
- [ ] Document spacing scale with visual examples
- [ ] Document color palette with hex codes
- [ ] Add component examples from MODERN_CSS_GUIDE.md
- [ ] Add container query patterns
- [ ] Include DO/DON'T best practices
- [ ] Commit: `git commit -m "docs: Add design system guidelines"`

**Success Criteria:**
- [ ] Guidelines document exists and is readable
- [ ] All code examples are syntax-valid
- [ ] Typography scale documented
- [ ] Component patterns included

**Validation:**
```bash
# Check markdown renders correctly
cat HOMESITE_DESIGN_GUIDELINES.md | grep -E "^##|^###"
```

---

### Phase 3: Component Implementation (2-3 hours)

**3a. Layouts (30 min)**
- [ ] Apply tokens to `lib/homesite_web/components/layouts/root.html.heex`
- [ ] Apply tokens to `lib/homesite_web/components/layouts/app.html.heex`
- [ ] Test at 375px, 768px, 1440px, 1920px
- [ ] Commit: `git commit -m "feat: Apply design tokens to layouts"`

**3b. Navigation (30 min)**
- [ ] Update navbar component with fluid spacing
- [ ] Apply `clamp()` to padding and font sizes
- [ ] Test mobile menu behavior
- [ ] Commit: `git commit -m "feat: Apply design tokens to navigation"`

**3c. Forms (1 hour)**
- [ ] Update `lib/homesite_web/live/post_live/form.ex`
- [ ] Update `lib/homesite_web/live/tag_live/form.ex`
- [ ] Update `lib/homesite_web/live/user_live/settings.ex`
- [ ] Test form inputs at all breakpoints
- [ ] Verify validation states
- [ ] Commit: `git commit -m "feat: Apply design tokens to forms"`

**3d. Cards and Lists (30 min)**
- [ ] Update post cards with container queries
- [ ] Update tag badges
- [ ] Update table layouts
- [ ] Test card responsiveness
- [ ] Commit: `git commit -m "feat: Apply design tokens to cards and lists"`

**Success Criteria:**
- [ ] All components use design tokens
- [ ] No hardcoded spacing values
- [ ] Responsive at all breakpoints
- [ ] Visual consistency maintained

**Test Commands:**
```bash
# Start dev server
mix phx.server

# Visit pages and test:
# - /posts (grid layout)
# - /posts/1 (single article)
# - /tags (tags management)
# - /users/settings (forms)

# Test at different viewports using browser DevTools
```

---

### Phase 4: Testing & Validation (1 hour)

- [ ] Run visual regression tests: `./test/design_system/visual_test.sh`
- [ ] Test keyboard navigation (Tab, Shift+Tab, Enter, Escape)
- [ ] Run Lighthouse accessibility audit (target: 90+)
- [ ] Test with screen reader (VoiceOver on macOS, NVDA on Windows)
- [ ] Verify color contrast ratios with DevTools
- [ ] Test reduced motion preference (`prefers-reduced-motion`)
- [ ] Run all ExUnit tests: `mix test`
- [ ] Check CSS bundle size: `ls -lh priv/static/assets/app.css`
- [ ] Commit: `git commit -m "test: Validate design system implementation"`

**Success Criteria:**
- [ ] Lighthouse accessibility score ≥ 90
- [ ] All keyboard navigation works
- [ ] Color contrast meets WCAG AA
- [ ] CSS bundle size < 50KB
- [ ] All tests pass

**Test Commands:**
```bash
mix test
mix test test/homesite_web/design_system/

# Visual regression (if script exists)
chmod +x test/design_system/visual_test.sh
./test/design_system/visual_test.sh

# Lighthouse audit
# Open Chrome DevTools → Lighthouse → Run audit
```

---

### Phase 5: Documentation & Finalization (30 minutes)

- [ ] Update MODERN_CSS_GUIDE.md with any new patterns discovered
- [ ] Create interactive style guide HTML (optional)
- [ ] Package as Claude Skill (optional, see Step 4)
- [ ] Document usage examples in README or CLAUDE.md
- [ ] Update this checklist with actual times taken
- [ ] Commit: `git commit -m "docs: Complete design system documentation"`

**Success Criteria:**
- [ ] All documentation up to date
- [ ] Examples are tested and working
- [ ] Usage instructions clear

---

### Phase 6: Merge & Deploy

- [ ] Run full test suite: `mix test.all`
- [ ] Review all changes: `git diff main...design-system-implementation`
- [ ] Merge to main: `git checkout main && git merge design-system-implementation`
- [ ] Update MEMO.md with design system summary
- [ ] Create GitHub issue summarizing changes
- [ ] Run EOD workflow

**Success Criteria:**
- [ ] All tests pass
- [ ] MEMO.md updated
- [ ] GitHub issues updated
- [ ] Changes pushed to remote

**Final Commands:**
```bash
mix test.all
git checkout main
git merge design-system-implementation
git push origin main
```

---

## Implementation Timeline

### Phase 1: Setup (30 minutes)
- Generate design variants
- Select preferred direction
- Create documentation
- Package as skill
- Install skill

### Phase 2: Application (2-3 hours)
- Apply to layouts (30 min)
- Apply to navigation (30 min)
- Apply to forms (1 hour)
- Apply to cards/lists (30 min)
- Apply to dashboards (30 min)

### Phase 3: Refinement (1-2 hours)
- Fix edge cases
- Adjust spacing
- Optimize mobile
- Ensure accessibility
- Update documentation

### Phase 4: Validation (30 minutes)
- Visual regression testing
- Responsive testing
- Accessibility audit
- Cross-browser check

**Total Estimate: 4-6 hours**

---

## Success Metrics

### Quantitative

**Consistency Score:**
- 100% of buttons use design system classes
- 100% of forms follow same pattern
- 0 hardcoded colors (all use CSS variables)
- 0 inline styles

**Performance:**
- No increase in CSS bundle size
- Faster design iteration (30 min vs. days)

### Qualitative

**Developer Experience:**
- "I can build new pages without design decisions"
- "Style guide has example for every component I need"
- "Design changes take minutes, not hours"

**User Experience:**
- Consistent visual language
- Predictable interactions
- Accessible by default

---

## Best Practices for Using the Design System

### Code Quality Standards

**DO ✅:**

**Design Tokens:**
- Use semantic tokens (`--text-primary` not `--color-gray-900`)
- Reference CSS custom properties for all repeated values
- Define tokens in `:root` in `assets/css/app.css`
- Use `var(--token-name)` syntax in CSS

**Responsive Design:**
- Apply fluid sizing with `clamp()` for responsive elements
- Use `min()` for max-width constraints
- Use `max()` for min-width constraints
- Test at 4+ breakpoints before committing (375px, 768px, 1440px, 1920px)

**Components:**
- Document all component variants in style guide
- Follow SOLID principles (Single Responsibility for components)
- Use container queries for component-level responsiveness
- Keep components modular and reusable

**Testing:**
- Write tests for all new components
- Run visual regression tests after design changes
- Verify accessibility with automated tools
- Test keyboard navigation thoroughly

**Documentation:**
- Update HOMESITE_DESIGN_GUIDELINES.md when adding patterns
- Include code examples for every component
- Document WHY not just WHAT
- Add comments for non-obvious design decisions

---

**DON'T ❌:**

**CSS Anti-Patterns:**
- Don't mix media queries with modern CSS functions unnecessarily
- Don't use hardcoded colors (always reference tokens)
- Don't duplicate design token definitions
- Don't use generic fonts (Inter, Arial) without intention
- Don't nest CSS custom properties more than 3 levels deep

**Testing:**
- Don't skip accessibility testing
- Don't assume design works without verification
- Don't deploy without running Lighthouse audit
- Don't test only in one browser
- Don't skip mobile viewport testing

**Components:**
- Don't create components without examples
- Don't over-engineer simple components
- Don't use inline styles (use utility classes or tokens)
- Don't ignore DaisyUI conventions when they work

**Performance:**
- Don't ignore CSS bundle size
- Don't add excessive animations
- Don't use too many container query breakpoints
- Don't create overly complex `clamp()` values (max 3 parameters)

---

### Performance Guidelines

**CSS Optimization:**
```css
/* ✅ GOOD: Simple, readable clamp() */
font-size: clamp(1rem, 2vw, 1.5rem);

/* ❌ BAD: Overly complex, hard to debug */
font-size: clamp(calc(1rem + 0.5vw), calc(2vw + 0.25rem), calc(1.5rem + 1vw));
```

**Custom Properties Nesting:**
```css
/* ✅ GOOD: Shallow nesting (2 levels) */
:root {
  --space-base: 1rem;
  --space-lg: calc(var(--space-base) * 2);
}

/* ❌ BAD: Deep nesting (4+ levels) */
:root {
  --space-base: 1rem;
  --space-md: calc(var(--space-base) * 1.5);
  --space-lg: calc(var(--space-md) * 1.5);
  --space-xl: calc(var(--space-lg) * 1.5);
}
```

**Container Queries:**
```css
/* ✅ GOOD: Test with many elements */
.post-card {
  container-type: inline-size;
}

@container (max-width: 500px) {
  .post-card .card-body { padding: 1rem; }
}

/* ⚠️ WARNING: Monitor performance with 100+ cards */
```

**Performance Budgets:**
- CSS bundle size: < 50KB gzipped
- Custom properties: < 100 total
- Container query containers: < 50 per page
- Clamp() usage: Unlimited (performant)

**Monitoring:**
```bash
# Check CSS bundle size
mix assets.build
ls -lh priv/static/assets/app.css

# Monitor with gzip
gzip -c priv/static/assets/app.css | wc -c
```

---

### Accessibility Requirements

**Color Contrast (WCAG AA):**
- Normal text (< 18pt): 4.5:1 minimum
- Large text (≥ 18pt or bold ≥ 14pt): 3:1 minimum
- UI components: 3:1 minimum
- Test with browser DevTools contrast checker

**Example Contrast Validation:**
```elixir
# test/homesite_web/design_system/contrast_test.exs
@color_pairs [
  %{name: "primary text", fg: "#000000", bg: "#FFFFFF", min: 4.5},
  %{name: "link text", fg: "#570DF8", bg: "#FFFFFF", min: 4.5},
  %{name: "button", fg: "#FFFFFF", bg: "#570DF8", min: 4.5},
]

test "all color pairs meet WCAG AA standards" do
  Enum.each(@color_pairs, fn pair ->
    ratio = calculate_contrast_ratio(pair.fg, pair.bg)
    assert ratio >= pair.min, "#{pair.name} fails: #{ratio} < #{pair.min}"
  end)
end
```

**Keyboard Navigation:**
- All interactive elements must be keyboard accessible
- Tab order should be logical
- Focus indicators must be visible
- Skip links for main content
- Test with Tab, Shift+Tab, Enter, Escape, Arrow keys

**Screen Reader Support:**
- Use semantic HTML (`<nav>`, `<main>`, `<article>`)
- Add ARIA labels when needed
- Test with VoiceOver (macOS) or NVDA (Windows)
- Ensure dynamic content changes are announced

**Reduced Motion:**
```css
/* Respect user preference for reduced motion */
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

**Accessibility Testing Workflow:**
1. Run Lighthouse audit (target: 90+ score)
2. Test keyboard navigation manually
3. Test with screen reader
4. Verify color contrast programmatically
5. Test with `prefers-reduced-motion: reduce`
6. Run automated accessibility tests (e.g., axe-core)

---

### Component Design Patterns

**Typography Hierarchy:**
```heex
<!-- ✅ GOOD: Semantic markup with fluid sizing -->
<article>
  <h1 class="text-[clamp(1.5rem,4vw,3rem)]"><%= @post.title %></h1>
  <p class="text-[clamp(1rem,2vw,1.25rem)]"><%= @post.body %></p>
</article>

<!-- ❌ BAD: Hardcoded sizes, non-semantic -->
<div>
  <div style="font-size: 32px"><%= @post.title %></div>
  <div style="font-size: 16px"><%= @post.body %></div>
</div>
```

**Responsive Spacing:**
```heex
<!-- ✅ GOOD: Fluid gaps with clamp() -->
<div class="grid gap-[clamp(1rem,3vw,2rem)]">
  <%= for post <- @posts do %>
    <article><%= post.title %></article>
  <% end %>
</div>

<!-- ❌ BAD: Fixed spacing -->
<div class="grid gap-4">
  <%= for post <- @posts do %>
    <article><%= post.title %></article>
  <% end %>
</div>
```

**Layout Constraints:**
```heex
<!-- ✅ GOOD: Constrained width, centered -->
<main class="w-[min(95vw,1400px)] mx-auto">
  <%= @inner_content %>
</main>

<!-- ❌ BAD: No max-width, can be too wide -->
<main class="w-full px-4">
  <%= @inner_content %>
</main>
```

---

### Tailwind v4 @theme Directive Usage

**Modern Approach (Tailwind v4):**

```css
/* assets/css/app.css */
@import "tailwindcss" source(none);
@source "../css";
@source "../js";
@source "../../lib/homesite_web";

@theme {
  /* Typography Scale (uses CSS custom properties) */
  --font-size-xs: clamp(0.75rem, 1vw, 0.875rem);
  --font-size-sm: clamp(0.875rem, 1.5vw, 1rem);
  --font-size-base: clamp(1rem, 2vw, 1.25rem);
  --font-size-lg: clamp(1.125rem, 2.5vw, 1.5rem);
  --font-size-xl: clamp(1.25rem, 3vw, 2rem);
  --font-size-2xl: clamp(1.5rem, 4vw, 3rem);

  /* Spacing Scale */
  --spacing-xs: clamp(0.25rem, 1vw, 0.5rem);
  --spacing-sm: clamp(0.5rem, 2vw, 1rem);
  --spacing-md: clamp(1rem, 3vw, 2rem);
  --spacing-lg: clamp(2rem, 5vw, 4rem);
  --spacing-xl: clamp(3rem, 8vw, 6rem);

  /* Layout Constraints */
  --content-max-width: min(95vw, 1400px);
  --article-max-width: min(90vw, 800px);
  --card-max-width: min(90vw, 600px);
  --sidebar-width: max(250px, 20vw);

  /* Semantic Colors (reference DaisyUI) */
  --color-primary: theme('colors.primary');
  --color-secondary: theme('colors.secondary');
  --color-accent: theme('colors.accent');
  --color-neutral: theme('colors.neutral');
  --color-base-100: theme('colors.base-100');
  --color-base-200: theme('colors.base-200');
  --color-base-300: theme('colors.base-300');
}
```

**Why @theme?**
- CSS-first source of truth
- Tailwind turns tokens into utilities automatically
- Browser exposes them as CSS variables
- No `tailwind.config.js` needed
- Integrates with DaisyUI seamlessly

**Reference:** [Tailwind CSS 4 @theme Guide](https://medium.com/@sureshdotariya/tailwind-css-4-theme-the-future-of-design-tokens-at-2025-guide-48305a26af06)

---

### Integration with MODERN_CSS_GUIDE.md

The MODERN_CSS_GUIDE.md contains practical implementation patterns. When using the design system:

1. **Reference the guide** for specific component patterns (cards, forms, tables)
2. **Use the values** documented in MODERN_CSS_GUIDE.md (lines 296-317)
3. **Follow the principles** (fluid typography, container queries, no media queries)
4. **Test with the breakpoints** specified in the guide (375px, 768px, 1440px)

**Relationship:**
- **MODERN_CSS_GUIDE.md**: HOW to write modern CSS (techniques, patterns)
- **DESIGN_SYSTEM_PLAN.md**: WHAT to implement (system, process, testing)
- **HOMESITE_DESIGN_GUIDELINES.md**: REFERENCE for developers (tokens, components)

---

### Sources and References

**Research Sources:**
- [Claude Blog - Improving Frontend Design Through Skills](https://www.claude.com/blog/improving-frontend-design-through-skills)
- [Nathan Onn - Claude Skill Design System Guide](https://www.nathanonn.com/claude-skill-design-system-reusable-frontend/)
- [Microsoft Learn - Design For Testability](https://learn.microsoft.com/en-us/archive/msdn-magazine/2008/december/patterns-in-practice-design-for-testability)
- [Tailwind CSS 4 @theme: The Future of Design Tokens](https://medium.com/@sureshdotariya/tailwind-css-4-theme-the-future-of-design-tokens-at-2025-guide-48305a26af06)
- [DEV Community - Testability in System Design](https://dev.to/sardarmudassaralikhan/testability-in-system-design-and-architecture-1hlg)
- [Tailwind CSS Official Documentation - Theme Variables](https://tailwindcss.com/docs/theme)

**Internal Documentation:**
- MODERN_CSS_GUIDE.md (this repository)
- CLAUDE.md (project guidelines)
- AGENTS.md (Phoenix/LiveView patterns)

---

## Future Enhancements

### Phase 2 Features

**Component Variants:**
- Dark mode optimization
- High contrast theme
- Reduced motion mode
- Print stylesheet

**Advanced Patterns:**
- Data visualization styles
- Chart/graph components
- Complex table layouts
- Multi-step forms

**Tooling:**
- Figma integration (export designs)
- Storybook for component preview
- Visual regression testing
- Automated accessibility checks

### Phase 3 Features

**Design Tokens:**
- Export to Figma
- Generate iOS/Android themes
- Create email templates
- Print stylesheets

**Documentation:**
- Video tutorials
- Interactive playground
- Component API docs
- Migration guides

---

## Related Files

- `MODERN_CSS_GUIDE.md` - Current CSS patterns
- `assets/css/app.css` - Tailwind CSS imports
- `lib/homesite_web/components/` - Phoenix components
- `lib/homesite_web/components/layouts.ex` - Layout components

---

## Notes

**Different from MODERN_CSS_GUIDE.md:**
- MODERN_CSS_GUIDE: How to write CSS (patterns, techniques)
- DESIGN_SYSTEM_PLAN: What to style (components, tokens, guidelines)

**Relationship to DaisyUI:**
- DaisyUI provides base components
- Design system documents our specific usage
- Custom overrides clearly documented
- Easy to swap DaisyUI for custom components later

**Phoenix/LiveView Considerations:**
- Design system focuses on presentation layer
- LiveView logic remains in .ex files
- HEEx templates get styled classes
- Component slots follow design patterns

---

## Decision Points

**Before Implementation:**

1. **Design Direction:**
   - Keep current DaisyUI aesthetic?
   - Shift to custom Tailwind-only?
   - Hybrid approach?

2. **Scope:**
   - Full redesign or document current?
   - Include admin dashboard?
   - Style error pages?

3. **Tooling:**
   - Use Claude `frontend-design` skill?
   - Manual documentation?
   - Existing design tools?

4. **Priority:**
   - Essential components first?
   - Complete coverage?
   - Iterative rollout?

---

**Document created:** 2025-11-27
**Status:** Planning complete - ready for Phase 1
**Next step:** Generate design variants and select preferred direction
**Estimated ROI:** 4-6 hours investment, 10x faster future design changes
