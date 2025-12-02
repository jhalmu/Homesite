# Homesite Design System

**Version:** 1.0.0
**Framework:** Phoenix LiveView with HEEx templates
**CSS:** Tailwind CSS v4
**Components:** DaisyUI
**Theme:** Design-E-Technical (GitHub-inspired minimalist)
**Accessibility:** WCAG 2.1 Level AA compliant
**i18n:** English + Finnish

---

## Design Philosophy

**Technical Minimalism:**
- Clean, GitHub-inspired aesthetic
- Monospace fonts for metadata and code
- Subtle borders and spacing
- Focus on content readability
- Dark mode as first-class citizen

**Core Principles:**
1. **Accessibility First** - WCAG AA contrast ratios, semantic HTML
2. **Content Focus** - Typography and white space prioritized
3. **Consistent Spacing** - Fluid design tokens for all screen sizes
4. **Progressive Enhancement** - Works without JavaScript
5. **Performance** - Minimal CSS, optimized assets

---

## Color Palette

### Light Theme (Default)
```css
Background:     oklch(100% 0 0)         /* Pure white */
Surface:        oklch(96% 0.004 264)    /* Very light gray */
Border:         oklch(92% 0.004 264)    /* Light gray - WCAG AA */
Text:           oklch(15% 0.008 264)    /* Very dark - WCAG AA */
Text Secondary: oklch(25% 0.010 264)    /* Dark neutral */
Primary:        oklch(58% 0.14 32)      /* Warm orange */
Accent:         #FD4F00                 /* Bright orange */
```

### Dark Theme
```css
Background:     oklch(6.5% 0.012 264)   /* Very dark blue */
Surface:        oklch(18% 0.012 264)    /* Dark gray */
Border:         oklch(20% 0.010 264)    /* Darker gray */
Text:           oklch(85% 0.008 264)    /* Light gray */
Text Secondary: oklch(20% 0.010 264)    /* Medium gray */
Primary:        oklch(58% 0.12 35)      /* Orange */
Accent:         #FF6B35                 /* Bright orange */
```

### Usage
```heex
<!-- Use DaisyUI classes -->
<div class="bg-base-100 text-base-content">
  <p class="text-primary">Primary text</p>
  <span class="opacity-70">Muted text</span>
</div>

<!-- Use CSS custom properties -->
<div style="background: var(--surface); color: var(--text);">
  <span style="color: var(--accent);">Accent text</span>
</div>
```

---

## Typography

### Font Stacks
```css
Body:      -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Noto Sans'
Monospace: 'SF Mono', 'Consolas', 'Liberation Mono', 'Menlo'
Display:   'Space Grotesk', ui-sans-serif, system-ui
```

### Type Scale (Fluid)
```css
--text-xs:   clamp(0.75rem, 1vw, 0.875rem)    /* 12-14px */
--text-sm:   clamp(0.875rem, 1.5vw, 1rem)     /* 14-16px */
--text-base: clamp(1rem, 2vw, 1.25rem)        /* 16-20px */
--text-lg:   clamp(1.125rem, 2.5vw, 1.5rem)   /* 18-24px */
--text-xl:   clamp(1.25rem, 3vw, 2rem)        /* 20-32px */
--text-2xl:  clamp(1.5rem, 4vw, 3rem)         /* 24-48px */
```

### Headings
```heex
<h1 class="text-[var(--font-size-fluid-2xl)] font-bold">Page Title</h1>
<h2 class="text-[var(--font-size-fluid-xl)] font-semibold">Section</h2>
<h3 class="text-[var(--font-size-fluid-lg)] font-medium">Subsection</h3>
```

**Letter Spacing:** All headings use `letter-spacing: -0.01em`

---

## Spacing System

### Fluid Spacing Tokens
```css
--space-xs:  clamp(0.25rem, 1vw, 0.5rem)     /* 4-8px */
--space-sm:  clamp(0.5rem, 2vw, 1rem)        /* 8-16px */
--space-md:  clamp(1rem, 3vw, 2rem)          /* 16-32px */
--space-lg:  clamp(2rem, 5vw, 4rem)          /* 32-64px */
--space-xl:  clamp(3rem, 8vw, 6rem)          /* 48-96px */
```

### Component Spacing
```css
--spacing-card:    clamp(1rem, 3vw, 2rem)    /* Card padding */
--spacing-section: clamp(2rem, 5vw, 4rem)    /* Section gaps */
--spacing-inline:  clamp(0.25rem, 1vw, 0.5rem) /* Inline gaps */
```

### Usage
```heex
<!-- Use design tokens -->
<div class="px-[var(--spacing-card)] py-[var(--spacing-lg)]">
  <section class="mb-[var(--spacing-section)]">
    <h2>Section Title</h2>
  </section>
</div>

<!-- Or use Tailwind utilities -->
<div class="p-4 md:p-8">
  <section class="mb-8 md:mb-16">
    <h2>Section Title</h2>
  </section>
</div>
```

---

## Layout Constraints

### Max Widths
```css
--content-max-width:  min(95vw, 1400px)   /* Main content */
--article-max-width:  min(90vw, 800px)    /* Blog posts */
--card-max-width:     min(90vw, 600px)    /* Cards */
--sidebar-width:      max(250px, 20vw)    /* Sidebars */
```

### Usage
```heex
<!-- Main content container -->
<div class="mx-auto max-w-[1400px] px-4">
  <article class="prose prose-slate max-w-none">
    <!-- Content -->
  </article>
</div>

<!-- Technical main (from design-e-technical) -->
<main class="technical-main">
  <!-- max-width: 1200px, padding: 4rem 2rem -->
</main>
```

---

## Component Classes

### Cards
```heex
<!-- Post card (technical style) -->
<article class="post-card">
  <div class="post-meta">
    <time>2025-11-30</time>
    <span>•</span>
    <span class="tag-technical">elixir</span>
  </div>

  <h2 class="post-title">
    <.link navigate={~p"/posts/#{post}"}>Title</.link>
  </h2>

  <p class="post-excerpt">
    Preview text...
  </p>

  <div class="post-footer">
    <span>5 min read</span>
    <span>•</span>
    <span>Author Name</span>
  </div>
</article>

<!-- Generic listing card -->
<div class="listing-card">
  <h3 class="listing-title">Title</h3>
  <div class="listing-meta">
    <time>2025-11-30</time>
  </div>
  <p class="listing-content">Content...</p>
  <div class="listing-footer">Footer</div>
</div>

<!-- DaisyUI card -->
<div class="card bg-base-200 shadow-lg">
  <div class="card-body">
    <h2 class="card-title">Title</h2>
    <p>Content</p>
    <div class="card-actions justify-end">
      <button class="btn btn-primary">Action</button>
    </div>
  </div>
</div>
```

### Buttons
```heex
<!-- DaisyUI buttons -->
<button class="btn btn-primary">Primary</button>
<button class="btn btn-secondary">Secondary</button>
<button class="btn btn-ghost">Ghost</button>
<button class="btn btn-outline">Outline</button>

<!-- Sizes -->
<button class="btn btn-lg">Large</button>
<button class="btn btn-sm">Small</button>
<button class="btn btn-xs">Extra Small</button>

<!-- With icons -->
<button class="btn btn-primary gap-2">
  <.icon name="hero-plus" class="h-5 w-5" />
  New Post
</button>
```

### Forms
```heex
<!-- Using core_components.ex -->
<.form for={@form} phx-submit="save">
  <.input field={@form[:title]} label="Title" required />
  <.input field={@form[:body]} type="textarea" label="Content" />
  <.input field={@form[:is_public]} type="checkbox" label="Public" />

  <div>
    <.button type="submit">Save</.button>
    <.link navigate={~p"/posts"}>Cancel</.link>
  </div>
</.form>

<!-- Raw DaisyUI forms -->
<form>
  <label class="label">
    <span class="label-text">Email</span>
  </label>
  <input type="email" class="input input-bordered w-full" />

  <label class="label">
    <span class="label-text">Message</span>
  </label>
  <textarea class="textarea textarea-bordered"></textarea>

  <button type="submit" class="btn btn-primary">Submit</button>
</form>
```

### Badges
```heex
<!-- Technical tag -->
<span class="tag-technical">elixir</span>
<span class="tag-technical">phoenix</span>

<!-- DaisyUI badges -->
<div class="badge badge-primary">Primary</div>
<div class="badge badge-secondary">Secondary</div>
<div class="badge badge-ghost">Ghost</div>

<!-- Sizes -->
<div class="badge badge-lg">Large</div>
<div class="badge badge-sm">Small</div>
```

### Tables
```heex
<div class="overflow-x-auto">
  <table class="table table-zebra">
    <thead>
      <tr>
        <th>Name</th>
        <th>Email</th>
        <th>Actions</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td>John Doe</td>
        <td>john@example.com</td>
        <td>
          <button class="btn btn-xs">Edit</button>
        </td>
      </tr>
    </tbody>
  </table>
</div>
```

---

## Prose/Markdown Styling

```heex
<!-- Markdown content -->
<div class="prose prose-slate max-w-none dark:prose-invert">
  {raw(markdown_html)}
</div>

<!-- With custom styling -->
<div class="prose prose-slate max-w-none
            prose-pre:bg-gray-900 prose-pre:text-gray-100
            dark:prose-invert">
  {raw(markdown_html)}
</div>
```

**Prose Features:**
- Responsive typography
- Syntax-highlighted code blocks
- Styled tables, blockquotes, lists
- Dark mode support
- Links with primary color
- Proper heading hierarchy

---

## Accessibility Patterns

### Semantic HTML
```heex
<!-- Page structure -->
<main>
  <article>
    <header>
      <h1>Page Title</h1>
    </header>

    <section>
      <h2>Section Title</h2>
      <!-- Content -->
    </section>
  </article>
</main>
```

### ARIA Labels
```heex
<!-- Skip link -->
<a href="#main-content" class="sr-only focus:not-sr-only">
  Skip to main content
</a>

<!-- Icon buttons -->
<button aria-label="Delete post">
  <.icon name="hero-trash" class="h-5 w-5" />
</button>

<!-- Loading states -->
<button phx-click="save" phx-disable-with="Saving...">
  Save
</button>
```

### Focus Indicators
All interactive elements have visible focus indicators:
```css
.input:focus {
  outline: 2px solid var(--accent);
  outline-offset: 2px;
}
```

---

## Table of Contents Component

### Overview

Reusable sidebar component for automatic heading extraction and navigation.

**Features:**
- Extracts h2 and h3 headings from HTML content
- Builds nested structure (h3s as children of h2s)
- Sticky sidebar with active section tracking
- Smooth scroll navigation
- DaisyUI menu styling
- Responsive (hidden on mobile, visible lg+)

### Usage

```elixir
# In your LiveView mount
def mount(_params, _session, socket) do
  # Render markdown
  html_content = render_markdown(post.body)

  # Extract headings for TOC
  headings = TableOfContents.extract_headings(html_content)

  {:ok, assign(socket, headings: headings, html_content: html_content)}
end
```

```heex
<!-- In your template -->
<div class="flex gap-8">
  <!-- Main content -->
  <div class="flex-1 prose">
    {raw(@html_content)}
  </div>

  <!-- Sidebar with TOC -->
  <aside class="hidden lg:block lg:w-64">
    <TableOfContents.table_of_contents
      headings={@headings}
      title="On This Page"
      sticky={true}
      show_mobile={false}
    />
  </aside>
</div>
```

### Component Attributes

```elixir
attr :headings, :list, required: true    # From extract_headings/1
attr :title, :string, default: "Table of Contents"
attr :class, :string, default: ""
attr :sticky, :boolean, default: true    # Sticky sidebar
attr :show_mobile, :boolean, default: false  # Show on mobile
```

### Helper Functions

```elixir
# Extract headings from HTML
headings = TableOfContents.extract_headings(html_content)
# Returns: [%{level: 2, text: "Introduction", id: "introduction", children: [...]}]

# Add IDs to headings if markdown processor doesn't
html_with_ids = TableOfContents.add_heading_ids(html_content)
```

### MDEx Configuration

Ensure MDEx adds header IDs automatically:

```elixir
MDEx.to_html!(markdown,
  extension: [
    header_ids: "",  # Auto-generate IDs from heading text
    # ... other extensions
  ]
)
```

### JavaScript Hook

Active section tracking uses Intersection Observer:

```javascript
// Automatic tracking - included in app.js
TableOfContents: {
  mounted() {
    // Tracks visible sections
    // Highlights active TOC link
    // Smooth scroll on click
  }
}
```

### Styling

TOC uses DaisyUI menu component:

```css
/* Active link styles */
.toc-link {
  @apply rounded-md px-3 py-1.5 text-sm opacity-70;
  @apply hover:opacity-100 hover:bg-base-300;
}

.toc-link.active {
  @apply bg-primary text-primary-content opacity-100;
}
```

### Display Conditions

Only show TOC when:
- Content has h2 or h3 headings
- Post is >3 minutes read time (optional)
- Viewport is lg+ (1024px+)

```heex
<%= if @post.read_time_minutes >= 3 && @headings != [] do %>
  <TableOfContents.table_of_contents headings={@headings} />
<% end %>
```

### Examples

**Blog Post with TOC:**
```heex
<article>
  <div class="flex gap-8">
    <div class="flex-1 prose">
      {raw(@rendered_html)}
    </div>

    <%= if length(@headings) > 0 do %>
      <aside class="hidden lg:block lg:w-64">
        <TableOfContents.table_of_contents
          headings={@headings}
          title="On This Page"
        />
      </aside>
    <% end %>
  </div>
</article>
```

**FAQ Page with Combined Headings:**
```elixir
# Extract headings from multiple articles
headings =
  articles
  |> Enum.flat_map(fn article ->
    TableOfContents.extract_headings(article.body)
  end)
```

### Accessibility

- Proper semantic HTML (`<nav>`, `<ul>`, `<li>`)
- ARIA label on nav element
- Keyboard navigable links
- Focus indicators
- Screen reader friendly

---

## LiveView Patterns

### Loading States
```heex
<!-- Form loading -->
<form phx-submit="save" phx-change="validate">
  <button
    type="submit"
    class="btn btn-primary"
    phx-disable-with="Saving...">
    Save
  </button>
</form>

<!-- Custom loading states -->
<div class="phx-submit-loading:opacity-50">
  <!-- Content -->
</div>
```

### Modals
```heex
<.modal id="confirm-delete" on_cancel={JS.navigate(~p"/posts")}>
  <h2>Confirm Deletion</h2>
  <p>Are you sure you want to delete this post?</p>

  <div class="flex gap-2 justify-end">
    <button
      phx-click={JS.exec("data-cancel", to: "#confirm-delete")}
      class="btn btn-ghost">
      Cancel
    </button>
    <button
      phx-click="delete"
      class="btn btn-error">
      Delete
    </button>
  </div>
</.modal>
```

### Flash Messages
```heex
<.flash_group flash={@flash} />

<!-- Custom flash -->
<div class="alert alert-success">
  <.icon name="hero-check-circle" class="h-6 w-6" />
  <span>Success message</span>
</div>
```

---

## Theming

### Theme Toggle
```heex
<!-- Theme toggle component -->
<button
  phx-click={JS.dispatch("toggle-theme")}
  class="btn btn-ghost btn-circle">
  <.icon name="hero-moon" class="h-5 w-5 dark:hidden" />
  <.icon name="hero-sun" class="h-5 w-5 hidden dark:block" />
</button>
```

### CSS Custom Properties
Use these for dynamic theming:
```css
var(--bg)                  /* Background */
var(--surface)             /* Card backgrounds */
var(--border)              /* Border color */
var(--text)                /* Primary text */
var(--text-secondary)      /* Secondary text */
var(--accent)              /* Accent color */
var(--code-bg)             /* Code background */
```

---

## Responsive Design

### Breakpoints
```css
sm:   640px   /* Small tablets */
md:   768px   /* Tablets */
lg:   1024px  /* Small desktops */
xl:   1280px  /* Desktops */
2xl:  1536px  /* Large screens */
```

### Patterns
```heex
<!-- Mobile-first responsive -->
<div class="grid grid-cols-1 md:grid-cols-3 gap-4">
  <!-- Cards -->
</div>

<!-- Responsive typography -->
<h1 class="text-2xl md:text-4xl lg:text-5xl">
  Responsive Heading
</h1>

<!-- Show/hide by screen size -->
<div class="hidden md:block">Desktop only</div>
<div class="md:hidden">Mobile only</div>
```

---

## Best Practices

### DO ✅
- Use design tokens for spacing and typography
- Follow semantic HTML structure
- Test in both light and dark modes
- Ensure WCAG AA contrast ratios
- Use DaisyUI components when available
- Apply consistent card/listing patterns
- Use fluid design tokens for responsiveness

### DON'T ❌
- Hard-code color values
- Skip semantic landmarks
- Use `<div>` for buttons/links
- Create custom components without checking DaisyUI first
- Use fixed widths without `max-width`
- Ignore dark mode styles
- Use opacity for text colors (use CSS variables)

---

## Quick Reference

### Common Patterns
```heex
<!-- Page header -->
<.header>
  Page Title
  <:subtitle>Optional subtitle</:subtitle>
  <:actions>
    <.button>Action</.button>
  </:actions>
</.header>

<!-- Section header -->
<h2 class="text-[var(--font-size-fluid-xl)] font-semibold mb-[var(--spacing-md)]">
  Section Title
</h2>

<!-- Card grid -->
<div class="grid grid-cols-1 md:grid-cols-3 gap-6">
  <div class="card bg-base-200 shadow-lg">
    <!-- Card content -->
  </div>
</div>

<!-- Form layout -->
<.form for={@form} phx-submit="save">
  <.input field={@form[:field]} label="Label" />
  <div>
    <.button type="submit">Save</.button>
  </div>
</.form>
```

---

## Resources

- **Tailwind CSS v4**: https://tailwindcss.com/docs
- **DaisyUI**: https://daisyui.com/
- **Phoenix LiveView**: https://hexdocs.pm/phoenix_live_view/
- **WCAG Guidelines**: https://www.w3.org/WAI/WCAG21/quickref/
- **Heroicons**: https://heroicons.com/

---

**Created:** 2025-11-30
**Last Updated:** 2025-11-30
**Maintained by:** Homesite Development Team
