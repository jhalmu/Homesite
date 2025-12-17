---
title: "Portfolio & Projects"
order: 7
category: "features"
---

# Portfolio & Projects

## Overview

The Portfolio/Projects system allows you to organize and showcase your work with media galleries, collaborators, and customizable metadata.

## Creating a Project

### Stepped Form Workflow

Projects are created through a 5-step wizard:

1. **Basics** - Name, description, and project type (photography, coding, writing, etc.)
2. **Metadata** - Category, date, and tags (shared with blog posts)
3. **Team & Links** - Collaborators and affiliation links
4. **Settings** - Visibility (public/private, portfolio inclusion)
5. **Content** - Cover image and gallery media

### Quick Navigation

- When editing an existing project, "Skip to Content" button appears on all steps
- Use this to quickly jump to adding/managing photos

## Managing Photos

### Adding Photos to a Project

1. Navigate to your project's edit page
2. Go to Step 5 (Content) or click "Skip to Content"
3. Use the media picker to select images from your library
4. First image automatically becomes the cover if none is set

### Reordering Photos

On the project view page (`/projects/:id`):

1. Hover over any image to reveal control buttons
2. Click **↑** (up arrow) to move the image earlier in the sequence
3. Click **↓** (down arrow) to move the image later in the sequence

**Note:** With the masonry layout, visual position may not match the sequence exactly since images flow into columns. The order affects the rendering sequence (left-to-right, top-to-bottom).

### Removing Photos

1. Hover over the image you want to remove
2. Click the **X** button (red)
3. Confirm the removal in the dialog

**Important:** Removing a photo from a project only removes the association. The image remains in your media library and can be added to other projects.

## Gallery Display

### Masonry Layout

Both the private project view (`/projects/:id`) and public portfolio (`/portfolio/:slug`) use a masonry layout:

- **Responsive columns**: 1 column on mobile, 2 on tablet, 3 on desktop
- **Natural aspect ratios**: Images maintain their original proportions
- **Tight spacing**: Minimal gaps for a clean, professional look
- **High quality**: Uses large image data for sharp display

### Lightbox

On the public portfolio page, clicking any image opens a fullscreen lightbox with:

- Navigation arrows (previous/next)
- Keyboard support (arrow keys, Escape to close)
- Image counter

## Public Portfolio

### Making a Project Public

1. Edit your project
2. Go to Step 4 (Settings)
3. Enable "Public" to make it visible to everyone
4. Enable "Portfolio" to include it in your portfolio gallery

### Portfolio Index

The portfolio index page (`/portfolio`) displays all public portfolio projects as a gallery grid with:

- Large cover images (4:3 aspect ratio)
- Project title and description
- Category badge overlay
- Author and year

## Tags System

Projects share the same tag system as blog posts:

- **Shared tags**: Tags created for posts can be used in projects and vice versa
- **Tag search**: Search existing tags when adding to a project
- **Create inline**: Create new tags directly in the project form
- **Public/private tags**: Control tag visibility

## Collaborators

Add team members and credits to your projects:

- **Name**: Collaborator's display name
- **Contact type**: URL, email, or none
- **Display order**: Control the order collaborators appear

On the public portfolio, collaborators appear as: "With Name1, Name2, Name3" with clickable links.

## Affiliation Links

Add related links such as:

- Client websites
- Press coverage
- Related projects
- Source code repositories

## Keyboard Shortcuts

On the portfolio lightbox:

| Key | Action |
|-----|--------|
| `←` | Previous image |
| `→` | Next image |
| `Escape` | Close lightbox |

## Accessibility

All interactive elements include:

- Proper `aria-label` attributes
- Keyboard navigation support
- Focus indicators
- Screen reader compatible markup

## Routes

| Route | Description |
|-------|-------------|
| `/projects` | Your projects list (authenticated) |
| `/projects/new` | Create new project |
| `/projects/:id` | View project details |
| `/projects/:id/edit` | Edit project |
| `/portfolio` | Public portfolio index |
| `/portfolio/:slug` | Public project view |

## Technical Details

### Database Structure

- `projects` - Main project table
- `project_media_items` - Join table with `display_order` for photo ordering
- `project_tags` - Join table linking to shared tags
- `collaborators` - Project team members
- `affiliation_links` - Related URLs

### Image Storage

Images are stored as binary data in PostgreSQL with three sizes:

- `thumb_data` - Thumbnail (list views)
- `medium_data` - Medium (portfolio grid)
- `large_data` - Full size (gallery view, lightbox)
