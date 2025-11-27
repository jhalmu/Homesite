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
