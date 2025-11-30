# Accessibility Guidelines

This document outlines the accessibility standards and practices implemented in this Phoenix LiveView application.

## WCAG Compliance

This application targets **WCAG 2.1 Level AA compliance** with the following key areas:

### Color Contrast (1.4.3)

All text and interactive elements meet WCAG AA contrast ratios:
- **Normal text**: Minimum 4.5:1 contrast ratio
- **Large text** (18pt+ or 14pt+ bold): Minimum 3:1 contrast ratio
- **UI components**: Minimum 3:1 contrast ratio

**Implementation**:
- DaisyUI theme system with tested color combinations
- CSS custom properties for consistent theming
- Dark mode support with appropriate contrast adjustments

**Testing**: All 461 color contrast combinations tested and passing (as of 2025-11-30)

### Semantic HTML Structure

All pages use proper HTML5 semantic elements for better screen reader navigation:

#### Landmarks

Every page includes the following ARIA landmarks:

- `<main>` - Primary content area (exactly one per page)
- `<header>` - Page or section headers
- `<section>` - Thematic content groupings
- `<article>` - Self-contained content (blog posts)
- `<nav>` - Navigation areas (provided by Layouts.app)

**Pages updated**:
- ✅ Search page (`lib/homesite_web/live/search_live/index.html.heex`)
- ✅ Home page (`lib/homesite_web/live/page_live/home.html.heex`)
- ✅ Dashboard (`lib/homesite_web/live/dashboard_live/index.html.heex`)
- ✅ Post show page (`lib/homesite_web/live/post_live/show.ex`)
- ✅ Post index page (`lib/homesite_web/live/post_live/index.ex`)
- ✅ Tag index page (`lib/homesite_web/live/tag_live/index.ex`)
- ✅ Tag show page (`lib/homesite_web/live/tag_live/show.ex`)
- ✅ FAQ page (`lib/homesite_web/live/faq_live/index.ex`)

#### Heading Hierarchy

All pages follow proper heading hierarchy:

**Rules**:
1. Exactly **one H1 per page** (page title)
2. **No skipped levels** (H1 → H2 → H3, never H1 → H3)
3. **Logical nesting** (sections under H2, subsections under H3)

**Example structure**:
```html
<main>
  <h1>Page Title</h1>
  <section>
    <h2>Section Title</h2>
    <article>
      <h3>Article Title</h3>
    </article>
  </section>
</main>
```

**Fixed pages**:
- Search: Changed empty state heading from H3 → H2
- Home: Fixed inconsistent H2/H3 usage
- Posts index: Changed post titles from H3 → H2
- Tags index: Changed tag names from H3 → H2

### Forms and Interactive Elements

#### Form Labels

All form inputs have associated labels:
- Using `<.input>` component from `core_components.ex`
- Automatically generates proper `<label>` with `for` attribute
- Visual label text always present (no placeholder-only fields)

#### Keyboard Navigation

All interactive elements are keyboard accessible:
- Native HTML buttons and links (focusable by default)
- Tab order follows visual order
- Focus indicators visible on all interactive elements
- No keyboard traps

#### Focus Management

LiveView handles focus appropriately:
- Focus restored after navigation
- Modal dialogs trap focus
- Skip links available for main content

### Images and Media

#### Alt Text

All images require alt text:
- Decorative images: `alt=""`
- Informative images: Descriptive alt text
- Icon components include screen reader text where needed

### Dynamic Content (LiveView)

#### Live Regions

LiveView automatically manages ARIA live regions for:
- Flash messages (alerts, errors, info)
- Form validation errors
- Real-time updates

#### Loading States

Loading states communicated to screen readers:
- `phx-loading` states include ARIA labels
- Skeleton screens use semantic markup

## Components

### Core Components

The following accessible components are available in `core_components.ex`:

#### `.header`
Page-level header with H1:
```elixir
<.header>
  Page Title
  <:subtitle>Optional subtitle</:subtitle>
  <:actions>Optional action buttons</:actions>
</.header>
```

#### `.page_header`
Alternative page header (H1):
```elixir
<.page_header>
  <.icon name="hero-home" />
  <span>Page Title</span>
</.page_header>
```

#### `.section_header`
Section headers (H2):
```elixir
<.section_header>
  <.icon name="hero-document" />
  <span>Section Title</span>
</.section_header>
```

#### `.badge_section_header`
Section header with badge count (H2):
```elixir
<.badge_section_header
  icon="hero-document"
  title="Posts"
  count={@post_count}
  badge_class="badge-primary"
/>
```

#### `.button`
Accessible button component:
```elixir
<.button variant="primary">Click me</.button>
```

#### `.link`
Accessible link component:
```elixir
<.link navigate={~p"/posts"}>View Posts</.link>
```

#### `.input`
Accessible form input:
```elixir
<.input
  field={@form[:email]}
  type="email"
  label="Email Address"
  required
/>
```

### Icon Components

Icons use `hero-` prefix for Heroicons:
```elixir
<.icon name="hero-check-circle" class="h-5 w-5" />
```

**Accessibility note**: Icons are decorative when alongside text. For icon-only buttons, add screen reader text:
```elixir
<.button>
  <.icon name="hero-trash" />
  <span class="sr-only">Delete</span>
</.button>
```

## Testing

### Manual Testing

Recommended tools:
- **Keyboard navigation**: Tab through all interactive elements
- **Screen reader**: Test with VoiceOver (macOS) or NVDA (Windows)
- **Color contrast**: Use browser DevTools or [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)
- **Axe DevTools**: Browser extension for automated accessibility testing

### Automated Testing

**Current coverage**:
- 461 color contrast tests passing
- 97 LiveView tests verify semantic structure
- 32 security tests ensure scope isolation

**Recommended additions**:
- axe-core integration for ARIA validation
- Pa11y for automated accessibility testing
- Lighthouse CI for continuous accessibility monitoring

## Common Patterns

### Adding New Pages

When creating new pages, follow this template:

```elixir
def render(assigns) do
  ~H"""
  <Layouts.app flash={@flash} current_scope={@current_scope}>
    <main>
      <.header>
        Page Title
        <:subtitle>Optional subtitle</:subtitle>
        <:actions>
          <.button>Action</.button>
        </:actions>
      </.header>

      <section>
        <h2>Section Title</h2>
        <!-- Section content -->
      </section>
    </main>
  </Layouts.app>
  """
end
```

### Form Accessibility

```elixir
<.form for={@form} phx-submit="save">
  <.input field={@form[:title]} label="Title" required />
  <.input field={@form[:body]} type="textarea" label="Content" />

  <div>
    <.button type="submit">Save</.button>
    <.link navigate={~p"/posts"}>Cancel</.link>
  </div>
</.form>
```

### Modal Dialogs

```elixir
<.modal id="confirm-delete" on_cancel={JS.navigate(~p"/posts")}>
  <h2>Confirm Deletion</h2>
  <p>Are you sure you want to delete this post?</p>
  <div>
    <.button phx-click="delete">Confirm</.button>
    <.button phx-click={JS.exec("data-cancel", to: "#confirm-delete")}>
      Cancel
    </.button>
  </div>
</.modal>
```

## Resources

- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [WebAIM: Web Accessibility In Mind](https://webaim.org/)
- [MDN: Accessibility](https://developer.mozilla.org/en-US/docs/Web/Accessibility)
- [Phoenix Accessibility Guide](https://hexdocs.pm/phoenix_live_view/accessibility.html)
- [ARIA Authoring Practices](https://www.w3.org/WAI/ARIA/apg/)

## Changelog

### 2025-11-30
- **Semantic HTML**: Added `<main>`, `<article>`, `<section>`, `<header>` landmarks to all pages
- **Heading Hierarchy**: Fixed H1→H2→H3 hierarchy across search, home, dashboard, posts, tags, and FAQ pages
- **Components**: Added `.page_header` and `.section_header` components to core_components
- **Testing**: All 97 LiveView tests passing after semantic structure updates
- **Color Contrast**: All 461 color contrast tests passing (WCAG AA compliant)

### Previous
- Username routing implementation (accessible URLs with @username)
- WCAG AA color contrast compliance (461 tests)
- DaisyUI component library integration
- Dark mode support with proper contrast
