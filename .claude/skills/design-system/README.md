# Homesite Design System - Claude Skill

A comprehensive design system documentation package for the Homesite Phoenix LiveView application.

## What This Is

This Claude Skill provides instant access to the complete design system for the Homesite project, including:

- **Color palette** (light/dark themes with OKLCH values)
- **Typography** (fluid type scale, font stacks)
- **Spacing system** (fluid tokens with responsive clamp())
- **Component library** (Phoenix core components + DaisyUI)
- **Design tokens** (CSS custom properties)
- **Accessibility guidelines** (WCAG 2.1 Level AA)
- **Best practices** (patterns, anti-patterns, quick reference)

## Files

- **design-system.md** (561 lines) - Main design system overview with philosophy, patterns, and usage
- **components.md** (863 lines) - Complete component library reference with examples
- **tokens.md** (613 lines) - All design tokens with values and usage guidelines

**Total:** 2,037 lines of documentation, 5,067 words

## How to Use

When working on the Homesite codebase, reference this skill to:

1. **Look up color values** - Get exact OKLCH values for consistent theming
2. **Find component patterns** - Copy-paste proven component examples
3. **Check spacing tokens** - Use fluid spacing for responsive design
4. **Verify accessibility** - Ensure WCAG AA compliance
5. **Maintain consistency** - Follow established patterns

## Quick Examples

### Getting Color Values
```css
--bg: oklch(100% 0 0);         /* Light theme background */
--primary: oklch(58% 0.14 32);  /* Brand orange */
```

### Using Components
```heex
<.header>
  Posts
  <:subtitle>Manage your blog posts</:subtitle>
  <:actions>
    <.button>New Post</.button>
  </:actions>
</.header>
```

### Applying Spacing Tokens
```heex
<div class="px-[var(--spacing-card)] py-[var(--spacing-lg)]">
  Content with fluid spacing
</div>
```

## Technology Stack

- **Framework:** Phoenix LiveView 1.1.0
- **CSS:** Tailwind CSS v4 (no config file)
- **Components:** DaisyUI
- **Theme:** Design-E-Technical (GitHub-inspired minimalist)
- **Accessibility:** WCAG 2.1 Level AA

## Maintenance

This skill is automatically maintained alongside the main Homesite codebase. When design patterns change:

1. Update the relevant .md file(s)
2. Increment version in skill.json
3. Document changes in this README

## Version History

- **1.0.0** (2025-11-30) - Initial release
  - Extracted design patterns from assets/css/app.css
  - Documented all components from core_components.ex
  - Catalogued all design tokens
  - Created comprehensive examples and guidelines

---

**Created:** 2025-11-30
**Maintained by:** Homesite Development Team
