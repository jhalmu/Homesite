# Component Library Reference

**Version:** 1.0.0
**Framework:** Phoenix LiveView
**Component System:** Core Components + DaisyUI

---

## Core Components

These components are defined in `lib/homesite_web/components/core_components.ex` and are available globally in all templates.

### Layout Components

#### `<.header>`

Page or section header with optional subtitle and actions.

```heex
<!-- Basic header -->
<.header>
  Page Title
</.header>

<!-- With subtitle -->
<.header>
  Posts
  <:subtitle>Manage your blog posts</:subtitle>
</.header>

<!-- With actions -->
<.header>
  Posts
  <:subtitle>All your published posts</:subtitle>
  <:actions>
    <.link navigate={~p"/posts/new"}>
      <.button>New Post</.button>
    </.link>
  </:actions>
</.header>
```

**Slots:**
- Default slot: Main title text
- `:subtitle` - Optional descriptive text
- `:actions` - Optional action buttons/links

---

### Navigation Components

#### `<.link>`

Styled link component with LiveView navigation support.

```heex
<!-- LiveView navigation (no page reload) -->
<.link navigate={~p"/posts"}>View Posts</.link>

<!-- External link -->
<.link href="https://example.com">External Site</.link>

<!-- Patch (updates URL without remount) -->
<.link patch={~p"/posts?page=2"}>Next Page</.link>

<!-- With styling -->
<.link navigate={~p"/posts"} class="text-primary font-bold">
  Featured Posts
</.link>
```

**Props:**
- `navigate` - LiveView navigation path (uses pushState)
- `patch` - LiveView patch path (updates params)
- `href` - Regular link (causes page reload)
- `class` - Additional CSS classes

---

### Form Components

#### `<.form>`

Form wrapper with Phoenix LiveView integration.

```heex
<.form for={@form} phx-submit="save" phx-change="validate">
  <!-- Form inputs here -->
  <.button type="submit">Save</.button>
</.form>
```

**Props:**
- `for` - Form data structure (from `to_form/2`)
- `phx-submit` - LiveView event on submit
- `phx-change` - LiveView event on change (validation)
- `id` - Form DOM ID (required for testing)

**Important:** Always use `to_form/2` in mount/handle_event:
```elixir
assign(socket, form: to_form(changeset))
```

#### `<.input>`

Universal input component with automatic styling and error handling.

```heex
<!-- Text input -->
<.input field={@form[:title]} label="Title" required />

<!-- Email input -->
<.input field={@form[:email]} type="email" label="Email" />

<!-- Textarea -->
<.input field={@form[:body]} type="textarea" label="Content" rows={10} />

<!-- Select -->
<.input
  field={@form[:category]}
  type="select"
  label="Category"
  options={["Tech", "Life", "Other"]}
/>

<!-- Checkbox -->
<.input field={@form[:is_public]} type="checkbox" label="Public" />

<!-- Hidden input -->
<.input field={@form[:user_id]} type="hidden" />
```

**Props:**
- `field` - Form field (e.g., `@form[:title]`)
- `type` - Input type (text, email, password, textarea, select, checkbox, hidden)
- `label` - Field label
- `required` - Boolean for required fields
- `rows` - Rows for textarea
- `options` - Options for select (list or keyword list)

**Features:**
- Automatic error display from changeset
- ARIA labels for accessibility
- Consistent styling across all input types
- Required field indicators

#### `<.button>`

Styled button component.

```heex
<!-- Primary button -->
<.button type="submit">Save</.button>

<!-- Secondary button -->
<.button phx-click="cancel" class="btn-secondary">
  Cancel
</.button>

<!-- Disabled button -->
<.button disabled>Processing...</.button>

<!-- With loading state -->
<.button phx-disable-with="Saving...">
  Save Post
</.button>
```

**Props:**
- `type` - Button type (button, submit, reset)
- `phx-click` - LiveView click event
- `phx-disable-with` - Text to show during submit
- `disabled` - Boolean to disable button
- `class` - Additional CSS classes

---

### Feedback Components

#### `<.flash_group>`

Flash message container (success, error, info).

```heex
<!-- In layout or LiveView -->
<.flash_group flash={@flash} />
```

**Usage in LiveView:**
```elixir
socket
|> put_flash(:info, "Post created successfully!")
|> put_flash(:error, "Failed to save post")
```

**Flash Types:**
- `:info` - Blue info messages
- `:error` - Red error messages
- `:success` - Green success messages (custom)

#### `<.modal>`

Modal dialog component.

```heex
<.modal id="confirm-delete" on_cancel={JS.navigate(~p"/posts")}>
  <h2 class="text-xl font-bold mb-4">Confirm Deletion</h2>
  <p class="mb-6">Are you sure you want to delete this post?</p>

  <div class="flex gap-2 justify-end">
    <button
      phx-click={JS.exec("data-cancel", to: "#confirm-delete")}
      class="btn btn-ghost">
      Cancel
    </button>
    <button
      phx-click="delete"
      phx-value-id={@post.id}
      class="btn btn-error">
      Delete
    </button>
  </div>
</.modal>

<!-- Show modal with JS command -->
<.button phx-click={JS.show(to: "#confirm-delete")}>
  Delete
</.button>
```

**Props:**
- `id` - Unique modal ID
- `on_cancel` - JS command when modal is dismissed
- `show` - Boolean to show modal on mount

**Features:**
- Backdrop click to close
- Escape key to close
- Focus trap for accessibility
- Smooth show/hide transitions

#### `<.icon>`

Heroicon component for SVG icons.

```heex
<!-- Outline icons -->
<.icon name="hero-plus" class="h-5 w-5" />
<.icon name="hero-trash" class="h-4 w-4 text-error" />

<!-- Solid icons -->
<.icon name="hero-heart-solid" class="h-6 w-6 text-primary" />

<!-- In buttons -->
<.button>
  <.icon name="hero-pencil" class="h-4 w-4 mr-2" />
  Edit
</.button>
```

**Props:**
- `name` - Icon name (hero-* from heroicons.com)
- `class` - Size and color classes

**Available Icons:** All Heroicons v2 icons with prefix `hero-`
- Navigation: hero-home, hero-menu, hero-x-mark
- Actions: hero-plus, hero-pencil, hero-trash, hero-check
- UI: hero-heart, hero-star, hero-tag, hero-bookmark

---

### List Components

#### `<.table>`

Data table component with sortable columns.

```heex
<.table id="posts-table" rows={@posts}>
  <:col :let={post} label="Title">
    <.link navigate={~p"/posts/#{post}"}>
      {post.title}
    </.link>
  </:col>

  <:col :let={post} label="Published">
    {format_date(post.published_at)}
  </:col>

  <:col :let={post} label="Status">
    <span class={["badge", post.is_public && "badge-success" || "badge-ghost"]}>
      {post.is_public && "Public" || "Draft"}
    </span>
  </:col>

  <:action :let={post}>
    <.link navigate={~p"/posts/#{post}/edit"}>Edit</.link>
  </:action>

  <:action :let={post}>
    <.button phx-click="delete" phx-value-id={post.id}>
      Delete
    </.button>
  </:action>
</.table>
```

**Slots:**
- `:col` - Table column with label
- `:action` - Action column (e.g., Edit, Delete buttons)

**Props:**
- `id` - Table DOM ID
- `rows` - List of items to display

---

### Error Components

#### `<.error>`

Error message component (used internally by `<.input>`).

```heex
<!-- Manual error display -->
<.error>This field is required</.error>

<!-- Multiple errors -->
<div>
  <.error :for={msg <- @errors}>
    {msg}
  </.error>
</div>
```

---

## DaisyUI Components

Pre-styled components from DaisyUI framework. Use these for rapid UI development.

### Buttons

```heex
<!-- Button variants -->
<button class="btn btn-primary">Primary</button>
<button class="btn btn-secondary">Secondary</button>
<button class="btn btn-accent">Accent</button>
<button class="btn btn-ghost">Ghost</button>
<button class="btn btn-link">Link</button>

<!-- Button sizes -->
<button class="btn btn-lg">Large</button>
<button class="btn">Normal</button>
<button class="btn btn-sm">Small</button>
<button class="btn btn-xs">Tiny</button>

<!-- Button states -->
<button class="btn btn-primary btn-outline">Outline</button>
<button class="btn btn-disabled" disabled>Disabled</button>
<button class="btn loading">Loading</button>

<!-- Button shapes -->
<button class="btn btn-circle">
  <.icon name="hero-plus" class="h-5 w-5" />
</button>
<button class="btn btn-square">
  <.icon name="hero-x-mark" class="h-5 w-5" />
</button>
```

### Cards

```heex
<!-- Basic card -->
<div class="card bg-base-200 shadow-lg">
  <div class="card-body">
    <h2 class="card-title">Card Title</h2>
    <p>Card content goes here.</p>
    <div class="card-actions justify-end">
      <button class="btn btn-primary">Action</button>
    </div>
  </div>
</div>

<!-- Card with image -->
<div class="card bg-base-200 shadow-xl">
  <figure>
    <img src="/images/photo.jpg" alt="Description" />
  </figure>
  <div class="card-body">
    <h2 class="card-title">Photo Title</h2>
    <p>Description text</p>
  </div>
</div>

<!-- Compact card -->
<div class="card card-compact bg-base-200">
  <div class="card-body">
    <h2 class="card-title">Compact Card</h2>
    <p>Less padding</p>
  </div>
</div>
```

### Badges

```heex
<!-- Badge variants -->
<div class="badge badge-primary">Primary</div>
<div class="badge badge-secondary">Secondary</div>
<div class="badge badge-accent">Accent</div>
<div class="badge badge-ghost">Ghost</div>

<!-- Badge sizes -->
<div class="badge badge-lg">Large</div>
<div class="badge">Normal</div>
<div class="badge badge-sm">Small</div>

<!-- Outline badges -->
<div class="badge badge-outline">Outline</div>

<!-- Status badges -->
<div class="badge badge-success">Success</div>
<div class="badge badge-error">Error</div>
<div class="badge badge-warning">Warning</div>
<div class="badge badge-info">Info</div>
```

### Alerts

```heex
<!-- Alert variants -->
<div class="alert alert-info">
  <.icon name="hero-information-circle" class="h-6 w-6" />
  <span>New updates available!</span>
</div>

<div class="alert alert-success">
  <.icon name="hero-check-circle" class="h-6 w-6" />
  <span>Your purchase has been confirmed!</span>
</div>

<div class="alert alert-warning">
  <.icon name="hero-exclamation-triangle" class="h-6 w-6" />
  <span>Warning: Invalid email address!</span>
</div>

<div class="alert alert-error">
  <.icon name="hero-x-circle" class="h-6 w-6" />
  <span>Error! Task failed successfully.</span>
</div>
```

### Forms

```heex
<!-- Input with label -->
<div class="form-control w-full max-w-xs">
  <label class="label">
    <span class="label-text">Email</span>
  </label>
  <input type="email" class="input input-bordered w-full" />
  <label class="label">
    <span class="label-text-alt">We'll never share your email</span>
  </label>
</div>

<!-- Textarea -->
<div class="form-control">
  <label class="label">
    <span class="label-text">Message</span>
  </label>
  <textarea class="textarea textarea-bordered h-24"></textarea>
</div>

<!-- Checkbox -->
<div class="form-control">
  <label class="label cursor-pointer">
    <span class="label-text">Remember me</span>
    <input type="checkbox" class="checkbox" />
  </label>
</div>

<!-- Radio buttons -->
<div class="form-control">
  <label class="label cursor-pointer">
    <span class="label-text">Option 1</span>
    <input type="radio" name="radio" class="radio" checked />
  </label>
</div>

<!-- Select -->
<select class="select select-bordered w-full max-w-xs">
  <option disabled selected>Pick one</option>
  <option>Option 1</option>
  <option>Option 2</option>
</select>

<!-- Toggle -->
<input type="checkbox" class="toggle toggle-primary" checked />
```

### Loading

```heex
<!-- Spinner -->
<span class="loading loading-spinner"></span>
<span class="loading loading-spinner loading-lg"></span>

<!-- Dots -->
<span class="loading loading-dots"></span>

<!-- Ring -->
<span class="loading loading-ring loading-lg"></span>

<!-- Bars -->
<span class="loading loading-bars"></span>
```

### Tables

```heex
<div class="overflow-x-auto">
  <table class="table">
    <thead>
      <tr>
        <th>Name</th>
        <th>Email</th>
        <th>Role</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td>John Doe</td>
        <td>john@example.com</td>
        <td>Admin</td>
      </tr>
      <tr class="hover">
        <td>Jane Smith</td>
        <td>jane@example.com</td>
        <td>User</td>
      </tr>
    </tbody>
  </table>
</div>

<!-- Table variants -->
<table class="table table-zebra"><!-- Striped --></table>
<table class="table table-compact"><!-- Less padding --></table>
```

### Breadcrumbs

```heex
<div class="breadcrumbs text-sm">
  <ul>
    <li><.link navigate={~p"/"}>Home</.link></li>
    <li><.link navigate={~p"/posts"}>Posts</.link></li>
    <li>Current Post</li>
  </ul>
</div>
```

### Tabs

```heex
<div class="tabs tabs-boxed">
  <a class="tab">Tab 1</a>
  <a class="tab tab-active">Tab 2</a>
  <a class="tab">Tab 3</a>
</div>

<!-- Bordered tabs -->
<div class="tabs tabs-bordered">
  <a class="tab">Tab 1</a>
  <a class="tab tab-active">Tab 2</a>
  <a class="tab">Tab 3</a>
</div>
```

### Collapse

```heex
<div class="collapse collapse-arrow bg-base-200">
  <input type="checkbox" />
  <div class="collapse-title text-xl font-medium">
    Click to expand
  </div>
  <div class="collapse-content">
    <p>Hidden content</p>
  </div>
</div>
```

---

## Custom Components

Application-specific component patterns.

### Post Card

```heex
<article class="post-card">
  <div class="post-meta">
    <time datetime={@post.published_at}>
      {format_date(@post.published_at)}
    </time>
    <span>•</span>
    <span class="tag-technical">elixir</span>
  </div>

  <h2 class="post-title">
    <.link navigate={~p"/posts/#{@post}"}>
      {@post.title}
    </.link>
  </h2>

  <p class="post-excerpt">
    {truncate(@post.body, 200)}
  </p>

  <div class="post-footer">
    <span>{@post.read_time} min read</span>
    <span>•</span>
    <span>{@post.user.username}</span>
  </div>
</article>
```

**CSS Classes:**
- `.post-card` - Container with border and padding
- `.post-meta` - Monospace metadata row
- `.post-title` - Large title with link
- `.post-excerpt` - Preview text
- `.post-footer` - Bottom metadata

### Listing Card

```heex
<div class="listing-card">
  <h3 class="listing-title">{@item.title}</h3>
  <div class="listing-meta">
    <time>{format_date(@item.inserted_at)}</time>
  </div>
  <p class="listing-content">{@item.description}</p>
  <div class="listing-footer">
    <.link navigate={~p"/items/#{@item}"}>View Details</.link>
  </div>
</div>
```

### Technical Tag

```heex
<span class="tag-technical">elixir</span>
<span class="tag-technical">phoenix</span>
<span class="tag-technical">liveview</span>
```

**Styling:** Monospace font, subtle background, rounded corners

### Theme Toggle

```heex
<button
  phx-click={JS.dispatch("toggle-theme")}
  class="btn btn-ghost btn-circle"
  aria-label="Toggle theme">
  <.icon name="hero-moon" class="h-5 w-5 dark:hidden" />
  <.icon name="hero-sun" class="h-5 w-5 hidden dark:block" />
</button>
```

### Language Toggle

```heex
<div class="flex gap-1">
  <button
    phx-click="set-locale"
    phx-value-locale="en"
    class={["btn btn-ghost btn-sm", @locale == "en" && "btn-active"]}>
    EN
  </button>
  <button
    phx-click="set-locale"
    phx-value-locale="fi"
    class={["btn btn-ghost btn-sm", @locale == "fi" && "btn-active"]}>
    FI
  </button>
</div>
```

---

## Component Patterns

### Conditional Rendering

```heex
<!-- If/else -->
<div>
  <%= if @user do %>
    <p>Welcome, {@user.username}!</p>
  <% else %>
    <p>Please log in.</p>
  <% end %>
</div>

<!-- Conditional classes -->
<div class={[
  "badge",
  @post.is_public && "badge-success" || "badge-ghost"
]}>
  {@post.is_public && "Public" || "Draft"}
</div>

<!-- Show/hide with CSS -->
<div class={@show_menu && "block" || "hidden"}>
  <!-- Menu content -->
</div>
```

### Iteration

```heex
<!-- List rendering -->
<div :for={post <- @posts} class="mb-4">
  <h3>{post.title}</h3>
  <p>{post.body}</p>
</div>

<!-- With index -->
<div :for={{post, index} <- Enum.with_index(@posts)}>
  <span>#{index + 1}</span>
  <h3>{post.title}</h3>
</div>

<!-- Empty state -->
<div :if={@posts == []} class="alert alert-info">
  No posts yet. Create your first post!
</div>
```

### Loading States

```heex
<!-- Form loading -->
<.button
  type="submit"
  phx-disable-with="Saving...">
  Save Post
</.button>

<!-- Content loading -->
<div class={@loading && "opacity-50 pointer-events-none"}>
  <!-- Content -->
</div>

<!-- Spinner -->
<div :if={@loading} class="flex justify-center p-8">
  <span class="loading loading-spinner loading-lg"></span>
</div>
```

### Error States

```heex
<!-- Form errors -->
<.form for={@form} phx-submit="save">
  <.input field={@form[:title]} label="Title" required />
  <!-- Errors show automatically -->

  <.button type="submit">Save</.button>
</.form>

<!-- Custom error display -->
<div :if={@error} class="alert alert-error">
  <.icon name="hero-x-circle" class="h-6 w-6" />
  <span>{@error}</span>
</div>
```

---

## Accessibility Guidelines

### Semantic HTML

Use proper HTML elements:
```heex
<!-- Good -->
<button phx-click="delete">Delete</button>
<a href="/posts">View Posts</a>

<!-- Bad -->
<div phx-click="delete">Delete</div>
<span onclick="...">View Posts</span>
```

### ARIA Labels

Add labels for icon-only buttons:
```heex
<button
  phx-click="delete"
  aria-label="Delete post"
  class="btn btn-ghost btn-sm">
  <.icon name="hero-trash" class="h-4 w-4" />
</button>
```

### Focus Management

Ensure keyboard navigation works:
```heex
<!-- Skip link -->
<a href="#main-content" class="sr-only focus:not-sr-only">
  Skip to main content
</a>

<!-- Focus visible -->
<button class="btn focus:outline-accent">
  Action
</button>
```

---

## Best Practices

### Component Organization

1. **Use Core Components** - Prefer `<.input>`, `<.button>`, `<.link>` over raw HTML
2. **DaisyUI First** - Check DaisyUI components before creating custom ones
3. **Custom Sparingly** - Only create custom components for unique patterns

### Naming Conventions

- **Component names:** PascalCase (e.g., `PostCard`, `UserAvatar`)
- **CSS classes:** kebab-case (e.g., `post-card`, `listing-title`)
- **Slots:** snake_case (e.g., `:actions`, `:subtitle`)

### Props vs Slots

- **Use props** for simple values (strings, booleans, numbers)
- **Use slots** for complex content (HTML, nested components)

---

## Resources

- **Phoenix Components:** https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html
- **DaisyUI:** https://daisyui.com/components/
- **Heroicons:** https://heroicons.com/
- **Tailwind CSS:** https://tailwindcss.com/docs

---

**Created:** 2025-11-30
**Last Updated:** 2025-11-30
**Maintained by:** Homesite Development Team
