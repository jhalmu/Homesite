# 🖼️ Image Gallery & Media Library - System Documentation

> **Status**: 📋 Planning Complete | **Estimated Effort**: 200-240 hours (5-6 weeks)

## 📖 Table of Contents

- [Overview](#-overview)
- [Research Findings](#-research-findings)
- [Architecture Overview](#architecture-overview)
- [Context API](#context-api-homesitemedia)
- [Features](#features)
  - [Portfolio System](#1-portfolio-system)
  - [Media Library](#2-media-library-for-blog-posts)
  - [Watermarking System](#3-watermarking-system)
  - [EXIF Metadata](#4-exif-metadata--copyright)
  - [Privacy Controls](#5-privacy-controls)
  - [Video Support](#6-video-support)
  - [Image Reels](#7-image-reels--carousels)
  - [Responsive Images](#8-responsive-images--performance)
- [Router Integration](#router-integration)
- [LiveView UI Components](#liveview-ui-components)
- [Storage Backend](#storage-backend)
- [Image Processing](#image-processing)
- [Security & Performance](#security--performance)
- [Testing Strategy](#testing-strategy)
- [Implementation Phases](#implementation-phases)
- [Configuration](#configuration)
- [Research Sources](#research-sources)

---

## 🎯 Overview

A comprehensive media management system for Homesite that combines professional portfolio capabilities with a practical media library for blog posts, supporting images and videos with advanced organization, watermarking, and privacy controls.

**✅ Purpose**:
- 📸 Professional portfolio showcasing (photography, art, design)
- 📝 Media library for blog post assets
- 🔒 Private/public media sharing
- ©️ Copyright protection via watermarking and metadata

**❌ Not intended for**:
- 📱 Social media-style infinite scrolling feeds
- 📦 General file storage (documents, archives)

---

## Research Findings

### Modern Portfolio Best Practices (2025)

Based on research from [Gallery Layout Best Practices](https://onewebcare.com/blog/gallery-layout-best-practices/), [Photography Portfolios](https://www.sitebuilderreport.com/inspiration/photography-portfolios), and [Artist Portfolio Tips](https://www.magazine.artconnect.com/resources/make-portfolio-stand-out):

**Design Principles**:
- Clean, uncluttered layouts with whitespace to showcase each piece
- Masonry layouts for mixed aspect ratios
- Mobile-first responsive design (significant mobile traffic)
- 15-25 curated pieces per collection (quality over quantity)
- Intuitive navigation with clear categorization

**Essential Features**:
- High-quality image display with zoom capability
- Descriptive alt text for accessibility and SEO
- Compelling artist statement per collection
- Strategic organization by category/project
- Regular updates to showcase current work

### Watermarking & Copyright Protection

Research from [Watermarking Best Practices](https://www.rswebsols.com/watermarking-best-practices/), [Photo Security with Metadata](https://www.linkedin.com/advice/0/how-do-you-use-metadata-watermarks-enhance-your-photo), and [EXIF Metadata Guide](https://www.wallpics.com/blogs/news/understanding-exif-metadata-what-every-photographer-should-know):

**Multi-Layered Protection**:
1. **Visible Watermarks**: 20-30% opacity, multiple sizes/positions
2. **EXIF Metadata**: Copyright info embedded in file
3. **Lower Resolutions**: For web display (preserve originals)
4. **Hidden Layers**: Steganographic watermarks

**EXIF Data Best Practices**:
- Photographer name, email, website
- Title, description, keywords
- Date, location (optional)
- License/copyright notice
- Auto-embed on camera or via Lightroom

**Watermark Strategies**:
- Combine 2-3 protection types for maximum security
- Multiple watermarks at various angles/opacities
- Metadata persists even if visible watermark removed
- Periodic reverse image search for unauthorized use

### Media Library Organization

Insights from [MediaCMS](https://mediacms.io/), [Video CMS Guide](https://www.dacast.com/blog/what-is-a-video-cms/), and [Digital Asset Management](https://www.mediavalet.com/blog/video-cms):

**Organization Features**:
- Categories and tags for classification
- Collections/albums/projects
- Search by filename, title, tags, EXIF data
- Filters by media type, date, size, dimensions
- Bulk operations (tagging, watermarking, moving)

**Media Types Support**:
- Images: JPG, PNG, WebP, AVIF
- Videos: MP4, WebM, MOV
- Documents (future): PDF for portfolios

---

## Architecture Overview

### Design Principles

1. **Scope-First Security**: All operations require `%Scope{}`, enforce ownership
2. **Flexible Privacy**: Public, unlisted, private galleries and individual items
3. **Portfolio Collections**: Nested structure (galleries → collections → items)
4. **Media Library Mode**: Searchable asset library for blog posts
5. **Watermark Pipeline**: Automatic on upload, configurable per gallery
6. **Video Support**: First-class support with thumbnails and streaming
7. **Responsive Images**: Multiple sizes generated automatically

### Database Schema

#### Tables

**1. galleries**
```elixir
id              - Primary key
user_id         - FK to users (owner)
title           - String (required, max 255)
description     - Text (optional)
slug            - String (unique per user, URL-friendly)
visibility      - Enum: "public", "unlisted", "private"
is_portfolio    - Boolean (portfolio vs media library)
cover_image_id  - FK to media_items (optional)
display_order   - Integer (for sorting)
settings        - JSONB (watermark config, layout preferences)
inserted_at     - Creation timestamp
updated_at      - Last update timestamp

# Indexes
INDEX(user_id, slug)
INDEX(user_id, is_portfolio)
INDEX(visibility) WHERE visibility = 'public'
```

**2. collections**
```elixir
id              - Primary key
gallery_id      - FK to galleries
title           - String (required, max 255)
description     - Text (optional)
slug            - String (unique per gallery)
display_order   - Integer (for sorting)
cover_image_id  - FK to media_items (optional)
inserted_at     - Creation timestamp
updated_at      - Last update timestamp

# Indexes
INDEX(gallery_id, slug)
INDEX(gallery_id, display_order)
```

**3. media_items**
```elixir
id                  - Primary key
user_id             - FK to users (owner)
collection_id       - FK to collections (nullable, can be in gallery root)
gallery_id          - FK to galleries (nullable, can be standalone)
media_type          - Enum: "image", "video"
filename            - String (original filename)
storage_path        - String (S3/local path)
thumbnail_path      - String (generated thumbnail)
file_size           - Bigint (bytes)
mime_type           - String
width               - Integer (pixels)
height              - Integer (pixels)
duration            - Integer (seconds, for videos)
title               - String (optional, max 255)
description         - Text (optional)
alt_text            - String (SEO/accessibility)
tags                - Array of strings
exif_data           - JSONB (camera, lens, settings, location)
watermarked_path    - String (watermarked version path)
watermark_applied   - Boolean
visibility          - Enum: "public", "unlisted", "private"
display_order       - Integer (within collection)
uploaded_at         - Upload timestamp
inserted_at         - Creation timestamp
updated_at          - Last update timestamp

# Indexes
INDEX(user_id, media_type)
INDEX(collection_id, display_order)
INDEX(gallery_id) WHERE collection_id IS NULL
INDEX(tags) USING GIN  # Full-text search on tags
INDEX(visibility) WHERE visibility = 'public'
PARTIAL INDEX(user_id) WHERE watermark_applied = false
```

**4. media_usage** (track where media is used)
```elixir
id              - Primary key
media_item_id   - FK to media_items
usable_type     - String (polymorphic: "Post", "Page")
usable_id       - Integer (polymorphic ID)
inserted_at     - Creation timestamp

# Indexes
INDEX(media_item_id)
INDEX(usable_type, usable_id)
```

**5. watermark_templates**
```elixir
id              - Primary key
user_id         - FK to users
name            - String (template name)
type            - Enum: "text", "image", "both"
text_content    - String (copyright text, e.g., "© 2025 John Doe")
text_font       - String (font family)
text_size       - Integer (font size)
text_color      - String (hex color)
text_opacity    - Integer (0-100)
text_position   - Enum: "top_left", "top_right", "bottom_left", "bottom_right", "center"
image_path      - String (logo/signature image path)
image_opacity   - Integer (0-100)
image_position  - Enum (same as text)
image_scale     - Float (scale factor)
is_default      - Boolean (default template for user)
inserted_at     - Creation timestamp
updated_at      - Last update timestamp

# Indexes
INDEX(user_id, is_default)
```

### Hierarchy & Relationships

```
User
└── Galleries (portfolio or media library)
    ├── Collections (optional grouping)
    │   └── Media Items (images/videos)
    └── Media Items (can exist at gallery root)
```

**Examples**:
1. **Portfolio**: User → "My Photography" Gallery → "Landscapes" Collection → 20 Photos
2. **Media Library**: User → "Blog Assets" Gallery → Media Items (no collections)
3. **Mixed**: User → "Wedding Photography" Gallery → "Ceremony", "Reception" Collections

---

## Context API: `Homesite.Media`

### Gallery Functions

```elixir
# List user's galleries
list_galleries(%Scope{}, opts \\ []) :: [%Gallery{}]
# Options: is_portfolio (filter), visibility

# Get single gallery (verifies ownership)
get_gallery!(%Scope{}, id) :: %Gallery{}

# Get gallery by slug (public access)
get_gallery_by_slug!(slug, user_id) :: %Gallery{}
# Raises if not public/unlisted

# Create gallery
create_gallery(%Scope{}, attrs) :: {:ok, %Gallery{}} | {:error, %Changeset{}}
# Generates slug from title

# Update gallery
update_gallery(%Scope{}, %Gallery{}, attrs) :: {:ok, %Gallery{}} | {:error, %Changeset{}}
# Verifies ownership

# Delete gallery (with media handling)
delete_gallery(%Scope{}, %Gallery{}, opts \\ []) :: {:ok, %Gallery{}} | {:error, %Changeset{}}
# Options: delete_media (bool), move_to_gallery_id
```

### Collection Functions

```elixir
# List collections in gallery
list_collections(%Scope{}, gallery_id) :: [%Collection{}]

# Create collection
create_collection(%Scope{}, gallery_id, attrs) :: {:ok, %Collection{}} | {:error, %Changeset{}}

# Update collection order
reorder_collections(%Scope{}, gallery_id, collection_ids) :: :ok

# Delete collection (with media handling)
delete_collection(%Scope{}, %Collection{}, opts \\ []) :: {:ok, %Collection{}} | {:error, %Changeset{}}
# Options: delete_media (bool), move_to_collection_id
```

### Media Item Functions

```elixir
# Upload media (processes and stores)
upload_media(%Scope{}, upload, attrs) :: {:ok, %MediaItem{}} | {:error, %Changeset{}}
# - Validates file type and size
# - Generates thumbnail
# - Extracts EXIF data
# - Applies watermark if configured
# - Stores in configured backend (S3/local)

# List media items
list_media_items(%Scope{}, opts \\ []) :: [%MediaItem{}]
# Options: gallery_id, collection_id, media_type, tags, limit, offset

# Search media library
search_media(%Scope{}, query, opts \\ []) :: [%MediaItem{}]
# Full-text search: title, description, tags, filename

# Get single media item
get_media_item!(%Scope{}, id) :: %MediaItem{}

# Update media metadata
update_media_item(%Scope{}, %MediaItem{}, attrs) :: {:ok, %MediaItem{}} | {:error, %Changeset{}}

# Bulk operations
bulk_tag(%Scope{}, media_item_ids, tags) :: {:ok, count}
bulk_move(%Scope{}, media_item_ids, collection_id) :: {:ok, count}
bulk_watermark(%Scope{}, media_item_ids, template_id) :: {:ok, count}

# Delete media
delete_media_item(%Scope{}, %MediaItem{}) :: {:ok, %MediaItem{}} | {:error, %Changeset{}}
# Removes from storage, updates usage tracking
```

### Watermark Functions

```elixir
# Create watermark template
create_watermark_template(%Scope{}, attrs) :: {:ok, %WatermarkTemplate{}} | {:error, %Changeset{}}

# Apply watermark to media
apply_watermark(%Scope{}, media_item_id, template_id) :: {:ok, %MediaItem{}} | {:error, term()}
# Generates watermarked version, stores separately

# Batch apply watermark
apply_watermark_batch(%Scope{}, media_item_ids, template_id) :: {:ok, %Job{}}
# Background job for large batches via Oban

# Preview watermark
preview_watermark(%Scope{}, media_item_id, template_attrs) :: {:ok, binary()}
# Returns watermarked image for preview without saving
```

### EXIF & Metadata Functions

```elixir
# Extract EXIF data from upload
extract_exif(file_path) :: {:ok, map()} | {:error, term()}
# Uses exiftool or Elixir library

# Embed copyright metadata
embed_metadata(file_path, metadata) :: {:ok, binary()} | {:error, term()}
# Writes EXIF/IPTC data to file

# Strip EXIF (for public sharing)
strip_exif(file_path, keep_copyright: true) :: {:ok, binary()} | {:error, term()}
```

### Image Processing Functions

```elixir
# Generate responsive sizes
generate_variants(%MediaItem{}) :: {:ok, %{thumb: path, medium: path, large: path}}
# Creates multiple sizes for responsive display

# Generate video thumbnail
generate_video_thumbnail(video_path, timestamp \\ 0) :: {:ok, path}

# Optimize image
optimize_image(file_path, quality: 85) :: {:ok, binary()}
# Compression without visible quality loss
```

---

## Features

### 1. Portfolio System

**User Story**: "As a photographer, I want to showcase my work in organized collections"

**Implementation**:
- Create galleries with `is_portfolio: true`
- Nested collections (e.g., "Wedding Photography" → "Ceremony", "Reception")
- Public portfolio URLs: `/users/@username/portfolio/:gallery-slug`
- Cover images for galleries and collections
- Custom ordering (drag-and-drop in UI)

**UI Components**:
- Gallery grid view (masonry layout)
- Lightbox for full-screen viewing with arrow navigation
- Collection navigation sidebar
- Artist statement per gallery

### 2. Media Library for Blog Posts

**User Story**: "As a blogger, I want a searchable library of images I can insert into posts"

**Implementation**:
- Create gallery with `is_portfolio: false` (media library mode)
- Upload images/videos with tags
- Search by filename, title, tags, EXIF data
- Media picker component for post editor
- Track usage with `media_usage` table

**Integration with Posts**:
```elixir
# In post form LiveView
def handle_event("insert_media", %{"media_id" => id}, socket) do
  media = Media.get_media_item!(socket.assigns.current_scope, id)

  # Track usage
  Media.track_usage(media, "Post", socket.assigns.post.id)

  # Insert markdown
  markdown = "![#{media.alt_text}](#{media.storage_path})"
  {:noreply, insert_into_editor(socket, markdown)}
end
```

### 3. Watermarking System

**User Story**: "As a photographer, I want to protect my work with customizable watermarks"

**Implementation Approaches**:

**A. Text Watermark**
- Copyright text: "© 2025 John Doe"
- Configurable font, size, color, opacity (20-30% recommended)
- Multiple positions (corners, center, tiled)
- Rotation and warping options

**B. Image Watermark**
- Upload logo/signature
- Configurable scale and opacity
- Position control
- Blend modes

**C. Combined**
- Logo + copyright text
- Multiple watermarks at different positions
- Makes removal labor-intensive

**Processing Pipeline**:
```elixir
# On upload
def upload_media(%Scope{} = scope, upload, attrs) do
  with {:ok, stored_path} <- store_file(upload),
       {:ok, exif} <- extract_exif(stored_path),
       {:ok, thumb_path} <- generate_thumbnail(stored_path),
       {:ok, media} <- create_media_record(scope, attrs, stored_path, exif),
       {:ok, watermarked_path} <- apply_default_watermark(scope, media) do
    {:ok, media}
  end
end
```

**Watermark Templates**:
- Reusable templates per user
- Default template auto-applied on upload
- Per-gallery override settings
- Preview before applying

### 4. EXIF Metadata & Copyright

**Auto-Embed on Upload**:
```elixir
metadata = %{
  "Artist" => scope.user.display_name,
  "Copyright" => "© #{Date.utc_today().year} #{scope.user.display_name}",
  "Creator" => scope.user.display_name,
  "Rights" => "All rights reserved",
  "Source" => Routes.url(HomesiteWeb.Endpoint, :root),
  "Credit" => scope.user.display_name
}

embed_metadata(file_path, metadata)
```

**Selective Stripping**:
- Strip GPS location for privacy
- Preserve copyright tags
- Remove camera serial numbers
- Keep creation date

### 5. Privacy Controls

**Visibility Levels**:

1. **Public**: Listed in public gallery, search engines can index
2. **Unlisted**: Direct URL access only, not in public listings
3. **Private**: Only owner can view (requires authentication)

**Inheritance**:
- Gallery visibility → Collection visibility → Media item visibility
- Can override at each level (e.g., private item in public gallery)

**URL Patterns**:
```
Public:   /galleries/:slug
Unlisted: /galleries/:slug (same URL, but not discoverable)
Private:  /users/@me/galleries/:id (authenticated route)
```

### 6. Video Support

**Supported Formats**: MP4, WebM, MOV

**Features**:
- Automatic thumbnail generation (frame at 0 seconds or specified timestamp)
- Video duration extraction
- Streaming-optimized encoding (future: HLS/DASH)
- Responsive video player (HTML5)

**Processing Pipeline**:
```elixir
def process_video(video_path) do
  with {:ok, duration} <- extract_duration(video_path),
       {:ok, thumbnail} <- generate_video_thumbnail(video_path),
       {:ok, optimized} <- optimize_video(video_path, format: "mp4") do
    {:ok, %{duration: duration, thumbnail: thumbnail, video: optimized}}
  end
end
```

**Video Player Component**:
```heex
<video
  controls
  poster={@media_item.thumbnail_path}
  preload="metadata"
  class="w-full rounded-lg"
>
  <source src={@media_item.storage_path} type={@media_item.mime_type} />
  Your browser doesn't support video playback.
</video>
```

### 7. Image Reels / Carousels

**User Story**: "Display a slideshow of my best work on homepage"

**Implementation**:
- Select 5-10 images for featured reel
- Auto-advancing carousel (5 seconds per image)
- Swipe navigation on mobile
- Fade/slide transitions

**UI Component**:
```heex
<div class="carousel w-full" phx-hook="ImageReel">
  <%= for {media, index} <- Enum.with_index(@reel_items) do %>
    <div id={"reel-#{index}"} class="carousel-item relative w-full">
      <img src={media.storage_path} alt={media.alt_text} class="w-full" />
    </div>
  <% end %>
</div>
```

**JavaScript Hook**:
```javascript
Hooks.ImageReel = {
  mounted() {
    this.index = 0
    this.interval = setInterval(() => this.advance(), 5000)
  },
  advance() {
    this.index = (this.index + 1) % this.itemCount
    this.scrollToItem(this.index)
  }
}
```

### 8. Responsive Images & Performance

**Image Variants**:
- `thumb`: 300px max width (for grids)
- `medium`: 800px max width (for lightbox previews)
- `large`: 1600px max width (for full-screen)
- `original`: Unchanged (stored separately, not served publicly)

**HTML Output**:
```html
<img
  src="/media/medium/photo.jpg"
  srcset="
    /media/thumb/photo.jpg 300w,
    /media/medium/photo.jpg 800w,
    /media/large/photo.jpg 1600w
  "
  sizes="(max-width: 768px) 100vw, 50vw"
  alt="Sunset over mountains"
  loading="lazy"
/>
```

**Performance Optimizations**:
- WebP/AVIF format conversion (with JPG fallback)
- Lazy loading for off-screen images
- CDN integration (Cloudflare, CloudFront)
- Progressive JPG encoding
- Image compression (85% quality default)

---

## Router Integration

**Update**: `lib/homesite_web/router.ex`

```elixir
# Public gallery viewing
scope "/", HomesiteWeb do
  pipe_through :browser

  live_session :public,
    on_mount: [
      {HomesiteWeb.UserAuth, :mount_current_scope},
      {HomesiteWeb.SetLocaleHook, :default}
    ] do
    live "/galleries/:slug", GalleryLive.Public, :show
    live "/users/@:username/portfolio/:slug", GalleryLive.Portfolio, :show
  end
end

# Authenticated gallery management
scope "/", HomesiteWeb do
  pipe_through [:browser, :require_authenticated_user]

  live_session :require_authenticated_user,
    on_mount: [
      {HomesiteWeb.UserAuth, :require_authenticated},
      {HomesiteWeb.SetLocaleHook, :default}
    ] do
    live "/my/galleries", GalleryLive.Index, :index
    live "/my/galleries/new", GalleryLive.Form, :new
    live "/my/galleries/:id/edit", GalleryLive.Form, :edit
    live "/my/galleries/:id", GalleryLive.Show, :show

    # Media library
    live "/my/media", MediaLive.Library, :index
    live "/my/media/:id", MediaLive.Show, :show

    # Watermark templates
    live "/my/watermarks", WatermarkLive.Index, :index
    live "/my/watermarks/new", WatermarkLive.Form, :new
  end
end
```

---

## LiveView UI Components

### 1. Gallery Grid (`lib/homesite_web/live/gallery_live/index.ex`)

**Features**:
- Masonry layout for mixed aspect ratios
- Filter by portfolio/media library
- Search galleries
- Create new gallery button
- Visibility badges (public/unlisted/private)

**Layout**:
```
┌─────────────────────────────────────────────┐
│  My Galleries           [+ New Gallery]     │
├─────────────────────────────────────────────┤
│  [Search...] [Portfolio ▼] [All ▼]         │
├─────────────────────────────────────────────┤
│  ┌───────────┐  ┌───────────┐  ┌─────────┐ │
│  │ Wedding   │  │ Portraits │  │ Blog    │ │
│  │ Photos    │  │           │  │ Assets  │ │
│  │ [Public]  │  │ [Private] │  │ [Priv]  │ │
│  │ 45 items  │  │ 23 items  │  │ 156     │ │
│  └───────────┘  └───────────┘  └─────────┘ │
└─────────────────────────────────────────────┘
```

### 2. Gallery Detail (`lib/homesite_web/live/gallery_live/show.ex`)

**Features**:
- Collection tabs/sidebar
- Masonry image grid
- Lightbox on click
- Bulk selection mode
- Upload zone (drag & drop)

**Lightbox Component**:
```heex
<%= if @lightbox_open do %>
  <div class="modal modal-open" phx-click="close_lightbox">
    <div class="modal-box max-w-7xl">
      <button class="btn btn-ghost absolute right-4 top-4" phx-click="close_lightbox">
        <.icon name="hero-x-mark" />
      </button>

      <img src={@current_media.storage_path} alt={@current_media.alt_text} class="w-full" />

      <div class="modal-action justify-between">
        <button phx-click="prev_media" class="btn">
          <.icon name="hero-arrow-left" /> Previous
        </button>
        <div>
          <h3>{@current_media.title}</h3>
          <p class="text-sm opacity-70">{@current_media.description}</p>
        </div>
        <button phx-click="next_media" class="btn">
          Next <.icon name="hero-arrow-right" />
        </button>
      </div>
    </div>
  </div>
<% end %>
```

### 3. Media Library (`lib/homesite_web/live/media_live/library.ex`)

**Features**:
- Search by filename, title, tags
- Filter by media type (image/video)
- Tag filtering (multi-select)
- Grid/list view toggle
- Bulk operations toolbar

**Search Interface**:
```heex
<.form for={@search_form} phx-change="search" phx-submit="search">
  <.input field={@search_form[:query]} placeholder="Search media..." />

  <div class="flex gap-2 mt-2">
    <.input type="select" field={@search_form[:media_type]} options={[
      {"All", "all"}, {"Images", "image"}, {"Videos", "video"}
    ]} />

    <.input type="select" field={@search_form[:gallery_id]} options={@gallery_options} />
  </div>

  <!-- Tag cloud -->
  <div class="flex flex-wrap gap-1 mt-2">
    <%= for tag <- @available_tags do %>
      <button
        type="button"
        phx-click="toggle_tag"
        phx-value-tag={tag}
        class={["badge", if(tag in @selected_tags, do: "badge-primary", else: "badge-outline")]}
      >
        {tag}
      </button>
    <% end %>
  </div>
</.form>
```

### 4. Upload Interface (`lib/homesite_web/live/components/media_upload.ex`)

**Features**:
- Drag & drop zone
- Multi-file upload
- Progress bars
- EXIF preview
- Watermark toggle

**Component**:
```heex
<div
  class="border-2 border-dashed rounded-lg p-8 text-center"
  phx-drop-target={@uploads.media.ref}
>
  <.icon name="hero-cloud-arrow-up" class="h-12 w-12 mx-auto opacity-50" />
  <p class="mt-2">Drag files here or click to browse</p>

  <.live_file_input upload={@uploads.media} class="hidden" />

  <!-- Upload progress -->
  <%= for entry <- @uploads.media.entries do %>
    <div class="mt-4">
      <div class="flex justify-between text-sm">
        <span>{entry.client_name}</span>
        <span>{entry.progress}%</span>
      </div>
      <progress class="progress progress-primary w-full" value={entry.progress} max="100" />
    </div>
  <% end %>
</div>
```

### 5. Watermark Editor (`lib/homesite_web/live/watermark_live/form.ex`)

**Features**:
- Live preview
- Position selector (9-grid)
- Opacity slider
- Text/image upload
- Save as template

**Preview Panel**:
```heex
<div class="grid grid-cols-2 gap-4">
  <!-- Settings -->
  <div>
    <.input field={@form[:text_content]} label="Copyright Text" />
    <.input field={@form[:text_opacity]} type="range" min="0" max="100" label="Opacity" />

    <div class="grid grid-cols-3 gap-1 mt-4">
      <%= for position <- ~w(top_left top_center top_right center_left center center_right bottom_left bottom_center bottom_right) do %>
        <button
          type="button"
          phx-click="set_position"
          phx-value-position={position}
          class={["btn btn-sm", if(@form[:text_position].value == position, do: "btn-primary")]}
        >
          {position_icon(position)}
        </button>
      <% end %>
    </div>
  </div>

  <!-- Live Preview -->
  <div>
    <h3 class="font-semibold mb-2">Preview</h3>
    <div class="relative">
      <img src={@preview_image} alt="Preview" class="w-full" />
      <div
        class="absolute text-white"
        style={"
          #{position_style(@form[:text_position].value)};
          opacity: #{@form[:text_opacity].value / 100};
          font-size: #{@form[:text_size].value}px;
        "}
      >
        {@form[:text_content].value}
      </div>
    </div>
  </div>
</div>
```

### 6. Public Portfolio View (`lib/homesite_web/live/gallery_live/portfolio.ex`)

**Features**:
- Clean, professional layout
- Artist statement
- Collection navigation
- Contact/social links
- SEO optimized

**Layout**:
```
┌─────────────────────────────────────────────┐
│  John Doe Photography                       │
│  "Capturing moments, creating memories"     │
│                                             │
│  [Weddings] [Portraits] [Landscapes]       │
├─────────────────────────────────────────────┤
│  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐       │
│  │  ▮  │  │  ▮  │  │  ▮  │  │  ▮  │       │
│  └─────┘  └─────┘  └─────┘  └─────┘       │
│  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐       │
│  │  ▮  │  │  ▮  │  │  ▮  │  │  ▮  │       │
│  └─────┘  └─────┘  └─────┘  └─────┘       │
│                                             │
│  [← Previous]              [Next →]        │
└─────────────────────────────────────────────┘
```

---

## Storage Backend

### File Storage Options

**1. Local Storage (Development)**
```elixir
# config/dev.exs
config :homesite, Homesite.Media.Storage,
  adapter: Homesite.Media.Storage.Local,
  base_path: "priv/static/uploads",
  base_url: "http://localhost:4000/uploads"
```

**2. S3 (Production)**
```elixir
# config/runtime.exs
config :homesite, Homesite.Media.Storage,
  adapter: Homesite.Media.Storage.S3,
  bucket: System.get_env("AWS_S3_BUCKET"),
  region: System.get_env("AWS_REGION"),
  access_key_id: System.get_env("AWS_ACCESS_KEY_ID"),
  secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY")
```

**3. Cloudinary (Alternative)**
```elixir
config :homesite, Homesite.Media.Storage,
  adapter: Homesite.Media.Storage.Cloudinary,
  cloud_name: System.get_env("CLOUDINARY_CLOUD_NAME"),
  api_key: System.get_env("CLOUDINARY_API_KEY"),
  api_secret: System.get_env("CLOUDINARY_API_SECRET")
```

### Storage Adapter Interface

```elixir
defmodule Homesite.Media.Storage do
  @callback store(file_path :: String.t(), opts :: Keyword.t()) ::
    {:ok, storage_path :: String.t()} | {:error, term()}

  @callback delete(storage_path :: String.t()) :: :ok | {:error, term()}

  @callback url(storage_path :: String.t(), opts :: Keyword.t()) :: String.t()
end
```

---

## Image Processing

### Dependencies

```elixir
# mix.exs
defp deps do
  [
    {:mogrify, "~> 0.9"},          # ImageMagick wrapper
    {:exexif, "~> 0.0.1"},         # EXIF extraction
    {:ffmpex, "~> 0.10"},          # Video processing (FFmpeg wrapper)
    {:ex_aws, "~> 2.5"},           # S3 integration
    {:ex_aws_s3, "~> 2.4"},
    {:sweet_xml, "~> 0.7"}         # XML parsing for EXIF
  ]
end
```

### Processing Pipeline

```elixir
defmodule Homesite.Media.Processor do
  alias Mogrify.Image

  def process_image(file_path, opts \\ []) do
    with {:ok, exif} <- extract_exif(file_path),
         {:ok, variants} <- generate_variants(file_path),
         {:ok, optimized} <- optimize(file_path) do
      {:ok, %{exif: exif, variants: variants, optimized: optimized}}
    end
  end

  defp generate_variants(file_path) do
    variants = %{
      thumb: resize(file_path, 300),
      medium: resize(file_path, 800),
      large: resize(file_path, 1600)
    }
    {:ok, variants}
  end

  defp resize(file_path, max_width) do
    file_path
    |> Image.open()
    |> Image.resize_to_limit("#{max_width}x#{max_width}")
    |> Image.save()
  end

  defp optimize(file_path) do
    file_path
    |> Image.open()
    |> Image.quality("85")
    |> Image.strip()  # Remove metadata except copyright
    |> Image.save()
  end
end
```

---

## Security & Performance

### Security Considerations

1. **File Upload Validation**
   - Whitelist MIME types
   - Check magic bytes (not just extension)
   - Limit file size (10MB for images, 100MB for videos)
   - Scan for malware (ClamAV integration)

2. **Storage Security**
   - S3 bucket with private ACL
   - Signed URLs for private media (expire after 1 hour)
   - CDN with access control

3. **Scope Isolation**
   - All media operations verify ownership
   - Public galleries check visibility before serving
   - Private media requires authentication

### Performance Optimizations

1. **Image Serving**
   - CDN caching (CloudFront, Cloudflare)
   - Responsive images (srcset)
   - WebP/AVIF with JPG fallback
   - Lazy loading

2. **Database**
   - Indexes on common queries
   - Partial indexes for public galleries
   - GIN index on tags for full-text search

3. **Background Jobs**
   - Oban for async processing
   - Watermark application in background
   - Variant generation queued
   - Video transcoding in worker

---

## Testing Strategy

### Unit Tests (`test/homesite/media_test.exs`)

**Gallery Functions**:
- Create gallery with valid/invalid attrs
- Slug generation and uniqueness
- Visibility enforcement
- Ownership verification

**Media Upload**:
- Valid image upload
- Invalid file type rejection
- File size validation
- EXIF extraction
- Variant generation

**Watermarking**:
- Template creation
- Watermark application
- Preview generation

### Integration Tests (`test/homesite_web/live/gallery_live_test.exs`)

**Gallery Management**:
- Create/edit gallery
- Upload media
- Organize collections
- Bulk operations

**Public Access**:
- View public gallery
- Private gallery requires auth
- Unlisted gallery accessible by URL

### Security Tests (`test/homesite_web/media_security_test.exs`)

**Scope Isolation**:
- User A cannot view User B's private gallery
- User A cannot delete User B's media
- Public gallery viewable by all

---

## Implementation Phases

### Phase 1: Core Gallery System (Week 1-2)

**Database & Schemas**:
- [ ] Create migrations (galleries, collections, media_items)
- [ ] Schema files with validations
- [ ] Slug generation

**Context Layer**:
- [ ] Gallery CRUD functions
- [ ] Collection CRUD functions
- [ ] Media upload (basic)
- [ ] Scope isolation

**LiveView UI**:
- [ ] Gallery list/grid
- [ ] Gallery detail with collections
- [ ] Basic upload interface
- [ ] Public gallery view

**Tests**:
- [ ] Unit tests for context
- [ ] Security tests
- [ ] Integration tests for LiveViews

### Phase 2: Media Library & Organization (Week 2-3)

**Features**:
- [ ] Search functionality
- [ ] Tag system (JSONB array)
- [ ] Media library mode
- [ ] Bulk operations
- [ ] Media picker for posts

**UI**:
- [ ] Search interface with filters
- [ ] Bulk selection mode
- [ ] Tag cloud
- [ ] Media picker modal

### Phase 3: Watermarking (Week 3-4)

**Features**:
- [ ] Watermark templates
- [ ] Text watermark overlay
- [ ] Image watermark overlay
- [ ] Preview functionality
- [ ] Background processing (Oban)

**UI**:
- [ ] Watermark editor with live preview
- [ ] Template management
- [ ] Batch apply interface

### Phase 4: Video Support (Week 4-5)

**Features**:
- [ ] Video upload
- [ ] Thumbnail generation (FFmpeg)
- [ ] Duration extraction
- [ ] Video player component

**Processing**:
- [ ] FFmpeg integration
- [ ] Video optimization
- [ ] Streaming preparation

### Phase 5: Advanced Features (Week 5-6)

**Features**:
- [ ] EXIF metadata extraction/embedding
- [ ] Responsive image variants
- [ ] Image carousel/reel
- [ ] S3 storage integration
- [ ] CDN configuration

**Polish**:
- [ ] SEO optimization
- [ ] Performance tuning
- [ ] Documentation

---

## Configuration

### Environment Variables

```bash
# Storage
AWS_S3_BUCKET=homesite-media
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=xxx
AWS_SECRET_ACCESS_KEY=xxx

# CDN
CDN_URL=https://cdn.homesite.com

# Processing
MAX_IMAGE_SIZE_MB=10
MAX_VIDEO_SIZE_MB=100
WATERMARK_DEFAULT_OPACITY=25

# Features
MEDIA_LIBRARY_ENABLED=true
VIDEO_SUPPORT_ENABLED=true
WATERMARKING_ENABLED=true
```

---

## Research Sources

This plan incorporates best practices from:
- [Gallery Layout Best Practices](https://onewebcare.com/blog/gallery-layout-best-practices/)
- [Photography Portfolios 2025](https://www.sitebuilderreport.com/inspiration/photography-portfolios)
- [Artist Portfolio Tips](https://www.magazine.artconnect.com/resources/make-portfolio-stand-out)
- [Watermarking Best Practices](https://www.rswebsols.com/watermarking-best-practices/)
- [Photo Security with Metadata](https://www.linkedin.com/advice/0/how-do-you-use-metadata-watermarks-enhance-your-photo)
- [EXIF Metadata Guide](https://www.wallpics.com/blogs/news/understanding-exif-metadata-what-every-photographer-should-know)
- [MediaCMS](https://mediacms.io/)
- [Video CMS Guide](https://www.dacast.com/blog/what-is-a-video-cms/)

---

**Last Updated**: 2025-12-04
**Version**: 1.0 (Planning Phase)
**Estimated Effort**: 5-6 weeks (200-240 hours)
