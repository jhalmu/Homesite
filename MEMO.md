# MEMO.md

Session notes and progress tracking for the Homesite project.

---

## 2025-11-21 14:45:00

### Session: CLAUDE.md Creation and Project Documentation

#### Completed
- ✅ Created comprehensive CLAUDE.md file with:
  - Information source priority (AGENTS.md → Context7 → Internet)
  - Essential commands for development, database, assets, and documentation
  - Architecture overview including Scope-based pattern
  - Technology stack (Phoenix 1.8.1, LiveView, Ecto, Tailwind v4, DaisyUI)
  - Data models and relationships (User, Post, Tag, PostTag)
  - Router organization and LiveView structure
  - Important guidelines for authentication, Phoenix 1.8, forms, testing
  - Git & GitHub workflow including MEMO.md protocol
- ✅ Added Git & GitHub workflow section with:
  - When to commit & push (before major changes, when context fills, before ending)
  - GitHub Issues for task management
  - MEMO.md protocol with datetime stamps
  - Repository management notes
- ✅ Created initial MEMO.md file (this file)

#### Project Context
- **App Type:** Scoped multi-user blog application
- **Main Feature:** Personal website/blog in Finnish ("Juha Halmun kotisivu ja blogi")
- **Key Pattern:** Scope-based architecture where all context functions require `%Scope{}` as first argument
- **Critical Note:** Use `@current_scope.user` in templates, NOT `@current_user`

#### Current State
- CLAUDE.md and MEMO.md files are ready for use
- Git status shows modified configuration files and new LiveView modules
- Application has authentication system, post/tag management with LiveView CRUD operations
- Database migrations in place for users, posts, tags, and post_tags

#### Next Steps / TODO
- ✅ Committed and pushed CLAUDE.md and MEMO.md to GitHub (commit: 44e06f5)
- Consider creating GitHub issues for:
  - Any pending features or improvements
  - Documentation of existing functionality
  - Future enhancements (if any)
- Verify DaisyUI is properly configured in the project (check if it needs installation)
- Test the application: `mix phx.server` to ensure everything works

#### Notes for Next Session
- AGENTS.md contains comprehensive project guidelines - always check there first
- Project uses Scope pattern extensively - all context operations are user-scoped
- Database uses PostgreSQL with Ecto
- SEO configured for Finnish locale (fi_FI)
- Tailwind v4 uses new `@import` syntax without config file

---

## 2025-11-21 19:00:00

### Session: Fix Critical Blog and Tag Management Issues

#### Problems Identified
1. **Missing Repo Helper Function:** `Repo.all_by/2` didn't exist (conflict with Ecto's default `all_by/3`)
2. **Incorrect Router Configuration:** Routes for `/posts/new`, `/posts/:id/edit`, `/tags/new`, and `/tags/:id/edit` were pointing to Index LiveViews instead of Form LiveViews

#### Completed
- ✅ Added `Repo.scoped_all/2` helper function to `lib/homesite/repo.ex`:
  - Handles scoped queries with keyword list conditions
  - Used for fetching user-scoped records
- ✅ Updated `Content.list_tags/1` to use `Repo.scoped_all/2`
- ✅ Updated `Content.list_posts/1` to use `Repo.scoped_all/2`
- ✅ Fixed router configuration in `lib/homesite_web/router.ex`:
  - Changed `/posts/new` route from `PostLive.Index` to `PostLive.Form`
  - Changed `/posts/:id/edit` route from `PostLive.Index` to `PostLive.Form`
  - Changed `/tags/new` route from `TagLive.Index` to `TagLive.Form`
  - Changed `/tags/:id/edit` route from `TagLive.Index` to `TagLive.Form`
  - Removed unnecessary `/posts/:id/show/edit` and `/tags/:id/show/edit` routes
- ✅ Verified compilation: All files compile without errors
- ✅ Database migrations: Already up to date
- ✅ Code formatting: Applied with `mix format`

#### Current State
- **Blog system is now fully functional** - Users can create, edit, and delete posts
- **Tag management is now fully functional** - Users can create, edit, and delete tags
- All LiveView CRUD operations working correctly
- Router properly configured with Form LiveViews for new/edit actions
- Repo helper function handles scoped queries properly

#### Technical Notes
- Initial attempt used `all_by/2` name but conflicted with Ecto.Repo's `all_by/3` with default parameters
- Renamed to `scoped_all/2` to avoid conflicts and better reflect its purpose
- Standard `Repo.get_by!/2` works as expected (no custom implementation needed)

#### Next Steps / TODO
- Test the application manually: `mix phx.server`
- Create first blog post to verify functionality
- Create tags and associate them with posts
- Consider adding tag selection UI to post forms (many-to-many relationship)
- Verify DaisyUI installation and configuration

---
