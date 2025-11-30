# Design Tokens Reference

**Version:** 1.0.0
**Format:** CSS Custom Properties
**Naming:** BEM-inspired with double-dash prefix

---

## Color Tokens

### Light Theme (Default)

#### Base Colors
```css
--bg: oklch(100% 0 0);                    /* Pure white background */
--surface: oklch(96% 0.004 264);          /* Very light gray surface */
--border: oklch(92% 0.004 264);           /* Light gray border - WCAG AA */
--text: oklch(15% 0.008 264);             /* Very dark text - WCAG AA */
--text-secondary: oklch(25% 0.010 264);   /* Dark neutral secondary text */
```

#### Brand Colors
```css
--primary: oklch(58% 0.14 32);            /* Warm orange primary */
--accent: #FD4F00;                        /* Bright orange accent */
```

#### Semantic Colors
```css
--success: oklch(60% 0.15 145);           /* Green for success states */
--error: oklch(55% 0.20 25);              /* Red for error states */
--warning: oklch(75% 0.15 85);            /* Yellow for warnings */
--info: oklch(60% 0.15 250);              /* Blue for info */
```

#### Code Colors
```css
--code-bg: oklch(98% 0.002 264);          /* Very light code background */
--code-text: oklch(20% 0.008 264);        /* Dark code text */
```

### Dark Theme

#### Base Colors
```css
--bg: oklch(6.5% 0.012 264);              /* Very dark blue background */
--surface: oklch(18% 0.012 264);          /* Dark gray surface */
--border: oklch(20% 0.010 264);           /* Darker gray border */
--text: oklch(85% 0.008 264);             /* Light gray text */
--text-secondary: oklch(20% 0.010 264);   /* Medium gray secondary text */
```

#### Brand Colors
```css
--primary: oklch(58% 0.12 35);            /* Orange primary (adjusted) */
--accent: #FF6B35;                        /* Bright orange accent */
```

#### Code Colors
```css
--code-bg: oklch(12% 0.008 264);          /* Dark code background */
--code-text: oklch(80% 0.008 264);        /* Light code text */
```

### Usage

```css
/* In CSS */
.my-component {
  background: var(--surface);
  color: var(--text);
  border: 1px solid var(--border);
}

/* In inline styles */
<div style="background: var(--bg); color: var(--text);">
  Content
</div>
```

**Note:** Prefer DaisyUI classes when possible:
```heex
<div class="bg-base-100 text-base-content border-base-300">
  Content
</div>
```

---

## Typography Tokens

### Font Families

```css
--font-body: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Noto Sans', 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';

--font-mono: 'SF Mono', 'Consolas', 'Liberation Mono', 'Menlo', 'Courier New', monospace;

--font-display: 'Space Grotesk', ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
```

### Font Sizes (Fluid)

```css
/* Base sizes with fluid scaling */
--text-xs: clamp(0.75rem, 1vw, 0.875rem);      /* 12-14px */
--text-sm: clamp(0.875rem, 1.5vw, 1rem);       /* 14-16px */
--text-base: clamp(1rem, 2vw, 1.25rem);        /* 16-20px */
--text-lg: clamp(1.125rem, 2.5vw, 1.5rem);     /* 18-24px */
--text-xl: clamp(1.25rem, 3vw, 2rem);          /* 20-32px */
--text-2xl: clamp(1.5rem, 4vw, 3rem);          /* 24-48px */

/* Aliases for convenience */
--font-size-fluid-xs: var(--text-xs);
--font-size-fluid-sm: var(--text-sm);
--font-size-fluid-base: var(--text-base);
--font-size-fluid-lg: var(--text-lg);
--font-size-fluid-xl: var(--text-xl);
--font-size-fluid-2xl: var(--text-2xl);
```

### Font Weights

```css
--font-normal: 400;
--font-medium: 500;
--font-semibold: 600;
--font-bold: 700;
```

### Line Heights

```css
--leading-tight: 1.25;       /* For headings */
--leading-normal: 1.5;       /* For body text */
--leading-relaxed: 1.75;     /* For long-form content */
```

### Letter Spacing

```css
--tracking-tight: -0.01em;   /* For headings */
--tracking-normal: 0;        /* For body text */
--tracking-wide: 0.025em;    /* For uppercase text */
```

### Usage

```heex
<!-- Using fluid tokens -->
<h1 class="text-[var(--font-size-fluid-2xl)] font-bold">
  Page Title
</h1>

<!-- Using Tailwind classes (alternative) -->
<h1 class="text-2xl md:text-4xl lg:text-5xl font-bold">
  Page Title
</h1>
```

---

## Spacing Tokens

### Base Spacing (Fluid)

```css
--space-xs: clamp(0.25rem, 1vw, 0.5rem);      /* 4-8px */
--space-sm: clamp(0.5rem, 2vw, 1rem);         /* 8-16px */
--space-md: clamp(1rem, 3vw, 2rem);           /* 16-32px */
--space-lg: clamp(2rem, 5vw, 4rem);           /* 32-64px */
--space-xl: clamp(3rem, 8vw, 6rem);           /* 48-96px */
```

### Component Spacing

```css
--spacing-card: clamp(1rem, 3vw, 2rem);       /* Card padding */
--spacing-section: clamp(2rem, 5vw, 4rem);    /* Section gaps */
--spacing-inline: clamp(0.25rem, 1vw, 0.5rem); /* Inline gaps */
--spacing-stack: clamp(0.5rem, 2vw, 1rem);    /* Vertical stacking */
```

### Usage

```heex
<!-- Using spacing tokens -->
<div class="px-[var(--spacing-card)] py-[var(--spacing-lg)]">
  <section class="mb-[var(--spacing-section)]">
    Content
  </section>
</div>

<!-- Using Tailwind utilities (alternative) -->
<div class="px-4 md:px-8 py-8 md:py-16">
  <section class="mb-8 md:mb-16">
    Content
  </section>
</div>
```

---

## Layout Tokens

### Max Widths

```css
--content-max-width: min(95vw, 1400px);       /* Main content container */
--article-max-width: min(90vw, 800px);        /* Blog posts, articles */
--card-max-width: min(90vw, 600px);           /* Cards, modals */
--sidebar-width: max(250px, 20vw);            /* Sidebar navigation */
```

### Breakpoints

Tailwind CSS default breakpoints:
```css
/* Reference only - use Tailwind classes */
sm: 640px;    /* Small tablets */
md: 768px;    /* Tablets */
lg: 1024px;   /* Small desktops */
xl: 1280px;   /* Desktops */
2xl: 1536px;  /* Large screens */
```

### Container Padding

```css
--container-padding-mobile: 1rem;             /* 16px */
--container-padding-tablet: 2rem;             /* 32px */
--container-padding-desktop: 4rem;            /* 64px */
```

### Usage

```heex
<!-- Content container -->
<div class="mx-auto max-w-[var(--content-max-width)] px-4">
  <article class="max-w-[var(--article-max-width)]">
    Content
  </article>
</div>

<!-- Using Tailwind classes (alternative) -->
<div class="mx-auto max-w-7xl px-4 md:px-8">
  <article class="max-w-3xl">
    Content
  </article>
</div>
```

---

## Border Tokens

### Border Widths

```css
--border-thin: 1px;
--border-medium: 2px;
--border-thick: 4px;
```

### Border Radius

```css
--radius-sm: 0.25rem;      /* 4px */
--radius-md: 0.5rem;       /* 8px */
--radius-lg: 1rem;         /* 16px */
--radius-full: 9999px;     /* Fully rounded */
```

### Usage

```css
.card {
  border: var(--border-thin) solid var(--border);
  border-radius: var(--radius-md);
}
```

**Note:** DaisyUI provides utility classes:
```heex
<div class="border border-base-300 rounded-lg">
  Card content
</div>
```

---

## Shadow Tokens

### Elevation Shadows

```css
--shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);
--shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1);
--shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1);
--shadow-xl: 0 20px 25px -5px rgb(0 0 0 / 0.1);
--shadow-2xl: 0 25px 50px -12px rgb(0 0 0 / 0.25);
```

### Usage

```heex
<div class="shadow-lg">Card with shadow</div>
```

---

## Transition Tokens

### Duration

```css
--duration-fast: 150ms;
--duration-normal: 300ms;
--duration-slow: 500ms;
```

### Easing

```css
--ease-in: cubic-bezier(0.4, 0, 1, 1);
--ease-out: cubic-bezier(0, 0, 0.2, 1);
--ease-in-out: cubic-bezier(0.4, 0, 0.2, 1);
```

### Usage

```css
.button {
  transition: background-color var(--duration-normal) var(--ease-in-out);
}
```

**Note:** Tailwind provides transition utilities:
```heex
<button class="transition-colors duration-300 ease-in-out">
  Hover me
</button>
```

---

## Z-Index Scale

### Layer Order

```css
--z-base: 0;              /* Base content */
--z-dropdown: 10;         /* Dropdowns */
--z-sticky: 100;          /* Sticky headers */
--z-modal-backdrop: 900;  /* Modal backdrops */
--z-modal: 1000;          /* Modals */
--z-popover: 1100;        /* Popovers, tooltips */
--z-toast: 1200;          /* Toast notifications */
```

### Usage

```css
.modal {
  z-index: var(--z-modal);
}
```

---

## Icon Sizes

### Standard Sizes

```css
--icon-xs: 1rem;       /* 16px */
--icon-sm: 1.25rem;    /* 20px */
--icon-md: 1.5rem;     /* 24px */
--icon-lg: 2rem;       /* 32px */
--icon-xl: 3rem;       /* 48px */
```

### Usage

```heex
<.icon name="hero-plus" class="h-5 w-5" />  <!-- 20px -->
<.icon name="hero-plus" class="h-6 w-6" />  <!-- 24px -->
```

---

## DaisyUI Theme Variables

DaisyUI automatically generates CSS variables based on theme configuration.

### DaisyUI Color Variables

```css
/* Base colors */
--p: /* primary */
--pf: /* primary-focus */
--pc: /* primary-content */

--s: /* secondary */
--sf: /* secondary-focus */
--sc: /* secondary-content */

--a: /* accent */
--af: /* accent-focus */
--ac: /* accent-content */

--n: /* neutral */
--nf: /* neutral-focus */
--nc: /* neutral-content */

--b1: /* base-100 (background) */
--b2: /* base-200 (surface) */
--b3: /* base-300 (border) */
--bc: /* base-content (text) */

--in: /* info */
--inc: /* info-content */

--su: /* success */
--suc: /* success-content */

--wa: /* warning */
--wac: /* warning-content */

--er: /* error */
--erc: /* error-content */
```

### Usage

```heex
<!-- Use DaisyUI classes, not variables directly -->
<div class="bg-base-100 text-base-content">
  <button class="btn btn-primary">Primary Button</button>
  <div class="badge badge-success">Success</div>
</div>
```

---

## Opacity Scale

### Standard Opacities

```css
--opacity-0: 0;
--opacity-10: 0.1;
--opacity-20: 0.2;
--opacity-30: 0.3;
--opacity-40: 0.4;
--opacity-50: 0.5;
--opacity-60: 0.6;
--opacity-70: 0.7;
--opacity-80: 0.8;
--opacity-90: 0.9;
--opacity-100: 1;
```

### Usage

```heex
<div class="opacity-70">Muted content</div>
<div class="hover:opacity-100 transition-opacity">
  Hover to reveal
</div>
```

---

## Animation Tokens

### Keyframes

```css
@keyframes fade-in {
  from { opacity: 0; }
  to { opacity: 1; }
}

@keyframes slide-up {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}
```

### Usage

```css
.fade-in {
  animation: fade-in var(--duration-normal) var(--ease-out);
}

.slide-up {
  animation: slide-up var(--duration-normal) var(--ease-out);
}
```

---

## Token Naming Conventions

### Prefix System

- **Color tokens:** `--[name]` (e.g., `--bg`, `--text`, `--primary`)
- **Spacing tokens:** `--space-[size]` (e.g., `--space-md`)
- **Typography tokens:** `--text-[size]` or `--font-[property]`
- **Layout tokens:** `--[component]-[property]` (e.g., `--content-max-width`)

### Size Scale

- `xs` - Extra small
- `sm` - Small
- `md` - Medium (default)
- `lg` - Large
- `xl` - Extra large
- `2xl` - 2x Extra large

---

## Token Categories Summary

| Category | Count | Format |
|----------|-------|--------|
| Colors | 15+ | OKLCH, Hex |
| Typography | 20+ | clamp(), rem, unitless |
| Spacing | 10+ | clamp(), rem |
| Layout | 8 | min(), max(), px |
| Borders | 7 | px, rem |
| Shadows | 5 | box-shadow |
| Transitions | 6 | ms, cubic-bezier |
| Z-index | 7 | integers |
| Icons | 5 | rem |
| Opacity | 11 | decimal |

---

## Quick Reference

### Most Common Tokens

```css
/* Colors */
var(--bg)           /* Background */
var(--surface)      /* Card backgrounds */
var(--border)       /* Border color */
var(--text)         /* Primary text */
var(--primary)      /* Brand color */
var(--accent)       /* Accent color */

/* Typography */
var(--font-size-fluid-base)  /* Body text */
var(--font-size-fluid-xl)    /* Headings */
var(--font-mono)             /* Code */

/* Spacing */
var(--spacing-card)          /* Card padding */
var(--spacing-section)       /* Section gaps */
var(--space-md)              /* General spacing */

/* Layout */
var(--content-max-width)     /* Container width */
```

---

## Best Practices

### DO ✅

- Use fluid tokens for responsive sizing
- Prefer DaisyUI classes over raw CSS variables
- Use semantic color names (primary, success, error)
- Maintain consistent spacing scale
- Document custom tokens

### DON'T ❌

- Hard-code color values
- Mix px and rem units inconsistently
- Create tokens for one-off values
- Override DaisyUI variables directly
- Use non-fluid sizes for typography

---

## Resources

- **Tailwind CSS Customization:** https://tailwindcss.com/docs/customizing-colors
- **DaisyUI Themes:** https://daisyui.com/docs/themes/
- **OKLCH Color Picker:** https://oklch.com/
- **Fluid Type Scale Calculator:** https://www.fluid-type-scale.com/

---

**Created:** 2025-11-30
**Last Updated:** 2025-11-30
**Maintained by:** Homesite Development Team
