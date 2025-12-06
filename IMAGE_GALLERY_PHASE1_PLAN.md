# Image Gallery & Media Library - Phase 1 Implementation Plan

**Goal:** Core gallery system with upload, organization, and public portfolio viewing

**Estimated Effort:** 80 hours (2 weeks)

**Status:** Planning

---

## Table of Contents

1. [Database Schema](#database-schema)
2. [Context Layer](#context-layer)
3. [LiveView UI](#liveview-ui)
4. [Testing Strategy](#testing-strategy)
5. [Implementation Steps](#implementation-steps)
6. [Success Criteria](#success-criteria)

---

## Database Schema

### Tables Overview

```
galleries (portfolio collections or media libraries)
  ├─ collections (nested organization)
  │    └─ media_items (images/videos)
  └─ media_usage (track where media is used)
```

### Migration 1: Galleries Table

```elixir
defmodule Homesite.Repo.Migrations.CreateGalleries do
  use Ecto.Migration

  def change do
    create table(:galleries) do
      add :title, :string, null: false
      add :description, :text
      add :slug, :string, null: false
      add :gallery_type, :string, null: false, default: "portfolio"
      # Types: "portfolio" (public showcasing), "library" (media assets)

      add :is_public, :boolean, default: false, null: false
      add :settings, :map, default: %{}, null: false
      # Settings: display_mode, sort_order, theme, etc.

      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:galleries, [:user_id, :slug])
    create index(:galleries, [:user_id])
    create index(:galleries, [:gallery_type])
    create index(:galleries, [:is_public])
  end
end
```

### Migration 2: Collections Table

```elixir
defmodule Homesite.Repo.Migrations.CreateCollections do
  use Ecto.Migration

  def change do
    create table(:collections) do
      add :title, :string, null: false
      add :description, :text
      add :slug, :string, null: false
      add :display_order, :integer, default: 0, null: false

      add :gallery_id, references(:galleries, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:collections, [:gallery_id, :slug])
    create index(:collections, [:gallery_id])
    create index(:collections, [:user_id])
    create index(:collections, [:display_order])
  end
end
```

### Migration 3: Media Items Table

```elixir
defmodule Homesite.Repo.Migrations.CreateMediaItems do
  use Ecto.Migration

  def change do
    create table(:media_items) do
      add :title, :string
      add :description, :text
      add :alt_text, :string

      # File metadata
      add :file_path, :string, null: false
      add :file_name, :string, null: false
      add :file_size, :integer, null: false
      add :mime_type, :string, null: false
      add :media_type, :string, null: false
      # Types: "image", "video"

      # Image-specific
      add :width, :integer
      add :height, :integer
      add :exif_data, :map, default: %{}

      # Video-specific
      add :duration, :integer
      # Duration in seconds

      # Organization
      add :tags, {:array, :string}, default: [], null: false
      add :display_order, :integer, default: 0, null: false

      # Relationships
      add :collection_id, references(:collections, on_delete: :delete_all)
      add :gallery_id, references(:galleries, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:media_items, [:gallery_id])
    create index(:media_items, [:collection_id])
    create index(:media_items, [:user_id])
    create index(:media_items, [:media_type])
    create index(:media_items, [:display_order])

    # Full-text search on tags using GIN index
    execute "CREATE INDEX media_items_tags_gin ON media_items USING GIN (tags)",
            "DROP INDEX media_items_tags_gin"
  end
end
```

### Migration 4: Media Usage Tracking

```elixir
defmodule Homesite.Repo.Migrations.CreateMediaUsage do
  use Ecto.Migration

  def change do
    create table(:media_usage) do
      add :context_type, :string, null: false
      # Types: "post", "page", "comment", etc.

      add :context_id, :integer, null: false
      # ID of the post/page/etc. using this media

      add :media_item_id, references(:media_items, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:media_usage, [:media_item_id])
    create index(:media_usage, [:context_type, :context_id])
    create index(:media_usage, [:user_id])

    # Prevent duplicate usage entries
    create unique_index(:media_usage, [:media_item_id, :context_type, :context_id])
  end
end
```

---

## Context Layer

### Homesite.Media Context

**Location:** `lib/homesite/media.ex`

**Core Functions:**

```elixir
defmodule Homesite.Media do
  @moduledoc """
  The Media context for managing galleries, collections, and media items.
  """

  import Ecto.Query
  alias Homesite.Repo
  alias Homesite.Accounts.Scope
  alias Homesite.Media.{Gallery, Collection, MediaItem, MediaUsage}

  ## Galleries

  def list_galleries(%Scope{} = scope, opts \\ []) do
    # List all galleries for current user
    # Options: filter by type (portfolio/library), public/private
  end

  def get_gallery!(%Scope{} = scope, id) do
    # Get gallery with scope check
    # Raises if not found or user doesn't own it
  end

  def create_gallery(%Scope{} = scope, attrs) do
    # Create gallery with auto-generated slug
    # Slug format: "title-slug" (unique per user)
  end

  def update_gallery(%Scope{} = scope, %Gallery{} = gallery, attrs) do
    # Update gallery with scope check
  end

  def delete_gallery(%Scope{} = scope, %Gallery{} = gallery) do
    # Delete gallery and cascade to collections/media
  end

  ## Collections

  def list_collections(%Scope{} = scope, gallery_id) do
    # List all collections in a gallery
    # Ordered by display_order
  end

  def create_collection(%Scope{} = scope, gallery_id, attrs) do
    # Create collection with auto-generated slug
  end

  def update_collection(%Scope{} = scope, %Collection{} = collection, attrs) do
    # Update collection with scope check
  end

  def delete_collection(%Scope{} = scope, %Collection{} = collection) do
    # Delete collection and move media to gallery root
  end

  ## Media Items

  def list_media_items(%Scope{} = scope, gallery_id, opts \\ []) do
    # List media in gallery (optionally filtered by collection)
    # Options: collection_id, tags, media_type
  end

  def upload_media(%Scope{} = scope, gallery_id, upload, attrs) do
    # Upload media file, process image, save to storage
    # Returns {:ok, media_item} or {:error, changeset}
  end

  def update_media_item(%Scope{} = scope, %MediaItem{} = item, attrs) do
    # Update media metadata (title, description, tags, etc.)
  end

  def delete_media_item(%Scope{} = scope, %MediaItem{} = item) do
    # Delete media and remove file from storage
  end

  ## Search

  def search_media(%Scope{} = scope, query, opts \\ []) do
    # Full-text search on title, description, tags
    # Uses PostgreSQL GIN index on tags array
  end

  ## Public Access (no scope required)

  def get_public_gallery_by_slug!(username, slug) do
    # Get public gallery for portfolio viewing
    # Route: /users/@username/portfolio/:slug
  end

  def list_public_galleries(username) do
    # List all public galleries for a user
  end
end
```

### Schema Modules

**Location:** `lib/homesite/media/`

- `gallery.ex` - Gallery schema with validations
- `collection.ex` - Collection schema
- `media_item.ex` - Media item schema with file upload handling
- `media_usage.ex` - Usage tracking schema

**Key Validations:**

- **Gallery:** title (required, 1-200 chars), slug (unique per user), type (portfolio/library)
- **Collection:** title (required), slug (unique per gallery)
- **MediaItem:** file_path (required), mime_type (validated), tags (array of strings)

---

## LiveView UI

### Routes

**Authenticated Routes** (in `:require_authenticated_user` live_session):

```elixir
# Gallery management
live "/galleries", GalleryLive.Index, :index
live "/galleries/new", GalleryLive.Index, :new
live "/galleries/:id/edit", GalleryLive.Index, :edit
live "/galleries/:id", GalleryLive.Show, :show

# Media upload and management
live "/galleries/:gallery_id/upload", MediaLive.Upload, :new
live "/galleries/:gallery_id/media/:id/edit", MediaLive.Upload, :edit
```

**Public Routes** (no auth required):

```elixir
# Public portfolio viewing
live "/users/@:username/portfolio", PortfolioLive.Index, :index
live "/users/@:username/portfolio/:slug", PortfolioLive.Show, :show
```

### LiveView Components

#### 1. GalleryLive.Index

**Path:** `lib/homesite_web/live/gallery_live/index.ex`

**Features:**
- List all galleries (grid or list view)
- Filter by type (portfolio/library)
- Create new gallery (modal)
- Edit gallery (modal)
- Delete gallery (with confirmation)
- Toggle public/private visibility

**Template:** `lib/homesite_web/live/gallery_live/index.html.heex`

#### 2. GalleryLive.Show

**Path:** `lib/homesite_web/live/gallery_live/show.ex`

**Features:**
- View gallery details
- List all collections in gallery
- List all media items (masonry layout)
- Create new collection
- Upload new media
- Organize media (drag & drop reordering)

**Template:** `lib/homesite_web/live/gallery_live/show.html.heex`

#### 3. MediaLive.Upload

**Path:** `lib/homesite_web/live/media_live/upload.ex`

**Features:**
- Drag & drop file upload
- Multiple file upload support
- Progress indicators
- Image preview
- Metadata form (title, description, alt text, tags)
- Bulk tagging
- Upload to specific collection

**Uses:** `Phoenix.LiveView.UploadConfig` for file handling

**Template:** `lib/homesite_web/live/media_live/upload.html.heex`

#### 4. PortfolioLive.Show (Public)

**Path:** `lib/homesite_web/live/portfolio_live/show.ex`

**Features:**
- Public portfolio viewing
- Masonry layout with lightbox
- Collection navigation
- Artist statement display
- No edit controls (read-only)

**Template:** `lib/homesite_web/live/portfolio_live/show.html.heex`

### Shared Components

**Path:** `lib/homesite_web/components/media_components.ex`

- `<.media_card>` - Media item display card
- `<.gallery_card>` - Gallery preview card
- `<.collection_nav>` - Collection navigation
- `<.media_grid>` - Masonry grid layout
- `<.lightbox>` - Full-screen media viewer
- `<.upload_zone>` - Drag & drop upload area

---

## Testing Strategy

### Unit Tests

**Path:** `test/homesite/media_test.exs`

**Coverage:**
- Gallery CRUD operations
- Collection CRUD operations
- Media upload and deletion
- Slug generation (uniqueness, formatting)
- Search functionality
- Public gallery access

**Edge Cases:**
- Empty galleries
- Collections without media
- Duplicate slugs (should auto-increment)
- Invalid file types
- Missing required fields

### Security Tests

**Path:** `test/homesite_web/security_test.exs` (add to existing file)

**Critical Tests:**
- **Scope Isolation:**
  - User A cannot view User B's galleries
  - User A cannot edit User B's media
  - User A cannot delete User B's collections
- **Public Access:**
  - Public galleries are accessible without auth
  - Private galleries return 404 for non-owners
- **File Upload:**
  - Reject dangerous file types (.exe, .sh, .php)
  - Validate file size limits
  - Prevent path traversal attacks

### Integration Tests

**Path:** `test/homesite_web/live/gallery_live_test.exs`

**Coverage:**
- Gallery creation flow
- Media upload flow
- Public portfolio viewing
- Search and filtering
- Masonry layout rendering

---

## Implementation Steps

### Step 1: Database Migrations (2 hours)

1. Create all 4 migrations
2. Run migrations: `mix ecto.migrate`
3. Verify tables in PostgreSQL

### Step 2: Schema Modules (4 hours)

1. Create `Gallery` schema with changesets
2. Create `Collection` schema
3. Create `MediaItem` schema
4. Create `MediaUsage` schema
5. Add validations and associations
6. Test in `iex -S mix`

### Step 3: Media Context (8 hours)

1. Implement gallery CRUD functions
2. Implement collection CRUD functions
3. Implement media upload (basic - local file system)
4. Implement search functionality
5. Add PubSub for real-time updates
6. Write unit tests (95%+ coverage)

### Step 4: LiveView UI - Galleries (12 hours)

1. Create `GalleryLive.Index` with list view
2. Add gallery creation modal
3. Add edit/delete actions
4. Style with DaisyUI + design tokens
5. Write LiveView tests

### Step 5: LiveView UI - Media Upload (16 hours)

1. Create `MediaLive.Upload` with drag & drop
2. Implement `Phoenix.LiveView.allow_upload/3`
3. Handle file uploads and processing
4. Add progress indicators
5. Create metadata form
6. Write upload tests

### Step 6: LiveView UI - Gallery Show (12 hours)

1. Create `GalleryLive.Show` with masonry layout
2. Add collection navigation
3. Implement media grid with lazy loading
4. Add lightbox component
5. Test responsive behavior

### Step 7: Public Portfolio (8 hours)

1. Create `PortfolioLive.Show`
2. Add public gallery routing
3. Style portfolio view
4. Test public access (no auth required)

### Step 8: Security Testing (8 hours)

1. Write scope isolation tests
2. Test file upload security
3. Test public/private access controls
4. Run Sobelow security scan
5. Fix any vulnerabilities

### Step 9: Polish & Documentation (10 hours)

1. Add loading states
2. Add error handling
3. Improve accessibility (keyboard navigation, ARIA labels)
4. Write user documentation
5. Update MEMO.md

**Total:** 80 hours

---

## Success Criteria

Phase 1 is complete when:

- [ ] All 4 database tables created and migrated
- [ ] All schema modules created with validations
- [ ] Media context fully implemented with tests
- [ ] Gallery CRUD UI working (create, read, update, delete)
- [ ] Media upload working with drag & drop
- [ ] Public portfolio viewing working
- [ ] **Security tests passing** (scope isolation verified)
- [ ] **All unit tests passing** (0 failures)
- [ ] **95%+ test coverage** on Media context
- [ ] File uploads stored correctly (local file system)
- [ ] Masonry layout rendering correctly on all viewports
- [ ] No security vulnerabilities (Sobelow clean)

---

## Dependencies to Add

Add to `mix.exs`:

```elixir
{:mogrify, "~> 0.9.3"},      # ImageMagick wrapper for image processing
{:exexif, "~> 0.4.0"},       # EXIF extraction (Phase 5)
{:oban, "~> 2.17"},          # Background job processing (Phase 3)
```

Update dependencies:
```bash
mix deps.get
```

---

## File Storage Strategy

**Phase 1:** Local file system (simple, no external dependencies)

**Location:** `priv/static/uploads/media/`

**Structure:**
```
priv/static/uploads/media/
  ├── {user_id}/
  │   ├── {gallery_id}/
  │   │   ├── {media_item_id}.jpg
  │   │   └── {media_item_id}.mp4
```

**Phase 5:** Migrate to S3/CDN for production scalability

---

## Next Phases Preview

- **Phase 2:** Media library & search (40 hours)
- **Phase 3:** Watermarking system (40 hours)
- **Phase 4:** Video support with FFmpeg (40 hours)
- **Phase 5:** Advanced features (S3, CDN, responsive images) (40 hours)

---

## Questions Before Starting

1. **File storage:** Start with local file system or S3 immediately?
2. **Image processing:** Use Mogrify (ImageMagick) or Vix (libvips)?
3. **Masonry layout:** CSS Grid or JavaScript library (Masonry.js)?
4. **Lightbox:** Build custom or use library (PhotoSwipe)?
5. **Priority:** Portfolio showcasing or media library for posts?

---

**Ready to implement?** Start with Step 1 (Database Migrations).
