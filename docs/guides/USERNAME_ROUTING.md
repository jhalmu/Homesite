# Username Routing System - Usage Guide

## Table of Contents

1. [Introduction](#introduction)
2. [Setting Up Your Username](#setting-up-your-username)
3. [Form Validation](#form-validation)
4. [Accessing Profile URLs](#accessing-profile-urls)
5. [Profile Page Content](#profile-page-content)
6. [Feed URLs with Username](#feed-urls-with-username)
7. [Changing Your Username](#changing-your-username)
8. [Reserved Usernames](#reserved-usernames)
9. [Username Discovery](#username-discovery)
10. [User Interface Features](#user-interface-features)
11. [Technical Details (For Developers)](#technical-details-for-developers)

---

## Introduction

The username routing system allows you to claim a custom username for personalized profile URLs, making your profile more memorable and professional than numeric IDs.

### What is Username Routing?

Instead of sharing a profile URL like `/users/123`, you can claim a username and share `/users/@johndoe`.

### URL Patterns

**Without Username:**
```
https://yoursite.com/users/123
```

**With Username:**
```
https://yoursite.com/users/@johndoe
```

### Benefits

✅ **Memorable URLs** - Easier to remember and share
✅ **Professional Appearance** - Looks cleaner in links and bios
✅ **Personal Branding** - Establish your online identity
✅ **Feed Integration** - Works with RSS/Atom/JSON feeds
✅ **Backward Compatible** - Numeric ID URLs still work

---

## Setting Up Your Username

### Access Settings

**Location:** `/users/settings` (Profile tab)

**Requirements:**
- Must be logged in
- Navigate to Settings page
- Find "Username" field in profile form

### Step-by-Step Setup

1. **Log In**: Sign in to your account
2. **Navigate**: Go to Settings → Profile (`/users/settings`)
3. **Find Field**: Locate the "Username" field
4. **Enter Username**: Type your desired username
5. **Save**: Click "Save Changes" button

### Username Requirements

#### Length
- **Minimum:** 3 characters
- **Maximum:** 30 characters

#### Format Rules
- ✅ Must start with a lowercase letter (`a-z`)
- ✅ Contains only: lowercase letters, numbers, underscores
- ❌ No uppercase letters
- ❌ No hyphens or special characters
- ❌ No spaces

#### Uniqueness
- Must be unique across all users
- Case-insensitive (johndoe = JohnDoe)
- Cannot use reserved system words

### Valid Examples

✅ `johndoe` - Simple and clean
✅ `alice_smith` - Underscore separator
✅ `dev123` - Letter + numbers
✅ `elixir_fan` - Descriptive with underscore
✅ `web_developer_jane` - Multiple underscores

### Invalid Examples

❌ `JohnDoe` - Contains uppercase letters
❌ `123user` - Doesn't start with letter
❌ `jo` - Too short (minimum 3 characters)
❌ `john-doe` - Contains hyphen (not allowed)
❌ `admin` - Reserved system word
❌ `user name` - Contains space
❌ `user@name` - Contains special character

---

## Form Validation

### Real-Time Feedback

The username field validates as you type, providing instant feedback:

**Immediate Validation (Client-Side):**
- ✅ Format validation
- ✅ Length validation (min/max)
- ✅ Character validation

**On Submit (Server-Side):**
- ✅ Uniqueness check
- ✅ Reserved word check
- ✅ Database constraint validation

### Error Messages

You may see these validation messages:

#### Format Error
```
must start with letter, lowercase alphanumeric/underscore only
```
**Fix:** Use only lowercase letters, numbers, and underscores. Start with a letter.

#### Length Errors
```
should be at least 3 character(s)
```
**Fix:** Username too short, add more characters.

```
should be at most 30 character(s)
```
**Fix:** Username too long, remove some characters.

#### Uniqueness Error
```
has already been taken
```
**Fix:** Someone already claimed this username. Try a variation.

#### Reserved Word Error
```
is reserved
```
**Fix:** This username is reserved for system use. Choose a different one.

### Clearing Your Username

To remove your username and revert to ID-based URLs:

1. Go to `/users/settings`
2. Clear the username field (leave it empty)
3. Click "Save Changes"

Your profile will revert to numeric ID URLs: `/users/123`

---

## Accessing Profile URLs

### Your Profile URL

Once you set a username, your profile becomes accessible at:

```
https://yoursite.com/users/@yourusername
```

**Example:** If your username is `johndoe`:
```
https://yoursite.com/users/@johndoe
```

### Backward Compatibility

Your numeric ID URL **always works**, even with a username:

```
https://yoursite.com/users/123
```

Both URLs lead to the same profile:
- `/users/@johndoe` (username URL)
- `/users/123` (numeric ID URL)

### Sharing Your Profile

**Best Practices:**
- ✅ Share username URL for clean appearance
- ✅ Include in social media bios
- ✅ Add to email signatures
- ✅ Display in blog posts and articles
- ✅ Use in RSS feed URLs

**Example Bio:**
```
Elixir Developer | Phoenix Enthusiast
📝 Blog: yoursite.com/users/@johndoe
🔗 RSS: yoursite.com/users/@johndoe/rss.xml
```

---

## Profile Page Content

### What's Displayed

Your public profile page shows:

**User Information:**
- Display name (or "User Profile" if not set)
- Avatar image
- Bio/description
- Social links (website, Bluesky, Mastodon)

**Content:**
- List of published posts
- Publication dates
- Post titles and excerpts
- Links to full posts

**Empty State:**
- "No published posts yet" message when no posts

### Privacy Settings

**Public Access:**
- ✅ Profile is publicly accessible
- ✅ No login required to view
- ✅ Shareable with anyone

**Content Visibility:**
- ✅ Only **published posts** are visible
- ❌ Unpublished/draft posts remain private
- ❌ Hidden posts are not shown

**Profile Fields:**
- All profile fields you set are public
- Control what information you share in Settings

---

## Feed URLs with Username

### Supported Feed Formats

All feed formats support username routing:

**RSS Feed:**
```
https://yoursite.com/users/@yourusername/rss.xml
```

**Atom Feed:**
```
https://yoursite.com/users/@yourusername/feed.xml
```

**JSON Feed:**
```
https://yoursite.com/users/@yourusername/feed.json
```

### Feed Content

Your feeds include:
- ✅ Published posts only
- ✅ Sorted by publication date (newest first)
- ✅ Full HTML content
- ✅ Author information (name, avatar, bio)
- ✅ Post metadata (title, date, URL)

### Using with Feed Readers

Share your feed URL with popular RSS readers:

**Web Readers:**
- [Feedly](https://feedly.com)
- [Inoreader](https://inoreader.com)
- [NewsBlur](https://newsblur.com)
- [The Old Reader](https://theoldreader.com)

**Desktop/Mobile Readers:**
- NetNewsWire (macOS, iOS)
- Reeder (macOS, iOS)
- Unread (iOS)
- Newsboat (Linux)
- Fluent Reader (Cross-platform)

**Email Newsletters:**
- Substack (RSS import)
- Mailchimp (RSS campaigns)
- Buttondown

### Feed Discovery

Your feeds are discoverable via:
- HTML `<link>` tags in page header
- Feed autodiscovery in RSS readers
- Direct URL sharing

---

## Changing Your Username

### How to Change

1. Go to `/users/settings`
2. Update the username field with new username
3. Click "Save Changes"

The change takes effect immediately.

### What Happens

When you change your username:

✅ **Immediate Effects:**
- New username takes effect instantly
- New @username URLs work immediately
- Numeric ID URLs continue to work

❌ **Breaking Changes:**
- Old @username URLs return 404 (not found)
- Feed subscriptions with old username break
- Bookmarks with old username become invalid

⚠️ **Important:**
- Old username becomes immediately available for others
- Cannot reserve old username
- Cannot undo the change (one-way operation)

### Change Tracking

All username changes are logged with:
- **Old Username**: Previous username
- **New Username**: New username
- **Timestamp**: When the change occurred
- **IP Address**: Where the change was made
- **User Agent**: Browser/device information

**Purpose:**
- Audit trail for security
- Monitor username reuse
- Investigate suspicious activity
- Support dispute resolution

### Best Practices

**Before Changing:**
- ✅ Choose a username you'll keep long-term
- ✅ Notify subscribers about the change
- ✅ Update social media bio links
- ✅ Update bookmarks and saved links
- ✅ Consider impact on RSS feed subscribers

**After Changing:**
- ✅ Test new @username URL
- ✅ Share new feed URLs with subscribers
- ✅ Update external links and bios
- ✅ Announce change on social media
- ✅ Pin post explaining the change

**Recommendations:**
- ❌ Don't change frequently (confuses followers)
- ❌ Don't change without notification
- ✅ Keep username consistent across platforms
- ✅ Choose something memorable and professional

---

## Reserved Usernames

### System Reserved Words

The following usernames **cannot be claimed** because they're reserved for system routes and administrative functions:

**Administrative:**
- `admin`
- `staff`
- `support`
- `system`

**Authentication:**
- `auth`
- `login`
- `logout`
- `register`
- `signup`

**System Routes:**
- `api`
- `app`
- `dashboard`
- `dev`
- `static`
- `public`

**Content:**
- `blog`
- `posts`
- `tags`
- `feed`
- `feeds`
- `rss`
- `search`

**Generic:**
- `home`
- `help`
- `docs`
- `settings`
- `new`
- `test`
- `user`
- `users`
- `www`

### Why Reserved?

These usernames are reserved to:
- ✅ Prevent routing conflicts
- ✅ Protect system functionality
- ✅ Maintain administrative access
- ✅ Ensure clear URL structure
- ✅ Avoid user confusion

### Complete List

```
admin, api, app, auth, blog, dashboard, dev, docs,
feed, feeds, help, home, login, logout, new, posts,
public, register, rss, search, settings, signup,
staff, static, support, system, tags, test, user,
users, www
```

**Note:** This list may be updated as new system routes are added.

---

## Username Discovery

### Finding Users

**Current Status:** Direct URL access only

There is currently no public user directory or search functionality. Users must know or be given the username to access profiles.

### Sharing Your Username

To help others find your profile:

**Social Media Profiles:**
- Add profile URL to Twitter/X bio
- Include in LinkedIn about section
- Share on Mastodon/Bluesky profiles
- Link from Instagram bio

**Content:**
- Include in blog post author bios
- Add to email signatures
- Display in forum profiles
- Share in community introductions

**Direct Sharing:**
- Share via email or messaging
- Include in business cards
- Add to personal website
- Post in community forums

**Example Sharing:**
```
📝 Read my blog: yoursite.com/users/@johndoe
🔔 Subscribe: yoursite.com/users/@johndoe/rss.xml
```

### Future Enhancements

Potential future features (not yet implemented):
- User directory/search
- Username suggestions
- Profile discovery feed
- Tag-based user browsing
- Popular users list

---

## User Interface Features

### Dashboard Profile Card

**Location:** Dashboard page (`/dashboard`)

A prominent "Your Public Profile" card displays at the top of your dashboard to promote the username feature.

**With Username Claimed:**
- ✅ Displays your profile URL prominently
- ✅ **Copy** button - copies URL to clipboard
- ✅ **View** button - opens your public profile
- ✅ Profile stats: Published posts, Total views, Subscribers
- ✅ Gradient background for visual prominence

**Without Username:**
- 🎉 Encourages username claiming
- ✅ Lists benefits (memorable URL, professional appearance, custom RSS)
- ✅ **Claim Your Username** button - links to settings
- ✅ Visual indicators with checkmarks

**Feed Analytics (If You Have Feed Sources):**
- Shows feed consumption metrics below profile card
- Total items, unread count, read today/this week
- Bookmarked items count
- Top 3 feed sources by engagement
- Quick link to main feed page

### Profile Page Enhancements

**Location:** Your public profile (`/users/@yourusername`)

The profile page now includes additional features to make it a compelling personal homepage:

**Stats Section:**
- 📝 **Published Posts** - Total post count + total word count
- ⏱️ **Avg Read Time** - Average minutes per post
- 📅 **Member Since** - Month and year you joined

**Subscribe Section:**
- 📡 RSS, Atom, and JSON feed links
- Prominent call-to-action for visitors
- Encourages subscription to your content
- Clean card design with feed icons

**Share Buttons:**
- 📤 **Share Profile** - Native Web Share API (on supported devices)
  - Falls back to clipboard copy if Web Share not available
- 📋 **Copy Link** - Copies profile URL to clipboard
- Convenient one-click sharing to social media

### Navigation Integration

**Desktop Navigation:**
- 👤 **My Profile** link added to user dropdown menu
- Located above Settings, below avatar
- Uses username URL if available, falls back to numeric ID
- Consistent with existing navigation patterns

**Mobile Navigation:**
- 👤 **My Profile** link in mobile menu
- Same fallback behavior as desktop
- Positioned in user section with Settings and Log out
- Maintains consistent ordering across devices

### Username Celebration Modal

**Triggered:** When you claim a username for the first time (not on updates)

**Features:**
- 🎉 Celebratory message: "Congratulations! Your Username is Live!"
- Displays your new profile URL prominently
- **Share** button - Web Share API with fallback
- **Copy** button - Copies URL to clipboard
- **Close** button - Dismisses modal
- Encourages immediate sharing of new homepage

**When It Appears:**
- Only shown when username changes from nil → value
- Not shown when updating existing username
- Appears immediately after saving in settings
- Non-intrusive (can be closed and continue)

### Copy-to-Clipboard Functionality

**Available Throughout Application:**
- Dashboard profile card (copy profile URL)
- Profile page (copy profile link)
- Settings page (celebration modal copy button)

**Technical Details:**
- Uses modern Clipboard API
- Shows flash notification on success
- Works across all modern browsers
- Progressive enhancement approach

### Web Share API Integration

**Share Buttons Support:**
- Native share dialog on mobile devices
- Fallback to clipboard copy on desktop
- Supports: URL, title, and text
- Pre-populated share messages

**Share Locations:**
- Profile page: "Share Profile" button
- Settings celebration modal: "Share" button

**Share Content:**
- **Profile sharing**: "Check out [Name]'s Blog" + profile URL
- **Username claiming**: "I just set up my personal homepage at [URL]"

### Benefits Summary

**For Users Without Username:**
- 🎯 Prominent discovery via dashboard card
- ✅ Clear benefits explanation
- 🚀 One-click path to claiming username

**For Users With Username:**
- 📊 Profile stats make page more compelling
- 📤 Easy sharing encourages profile promotion
- 🔗 Quick access via navbar
- 📡 RSS/feed subscription options visible

**Overall UX Improvements:**
- Username feature now prominent (not hidden)
- Profile page worthy of being "independent homepage"
- Dashboard becomes actionable control center
- Celebration encourages immediate sharing
- Consistent patterns across all interfaces

---

## Technical Details (For Developers)

### Database Schema

**Table:** `users`

**Username Column:**
```sql
username citext NULL
```

**Properties:**
- Type: `citext` (case-insensitive text)
- Nullable: Yes (users can opt-out)
- Unique: Yes (unique index)
- Constraint: Regex validation at database level

**Database Constraint:**
```sql
CHECK (username ~ '^[a-z][a-z0-9_]{2,29}$')
```

**Indexes:**
```sql
CREATE UNIQUE INDEX users_username_index ON users (username);
```

### Lookup Functions

#### Get User by Identifier

Handles both numeric ID and @username:

```elixir
alias Homesite.Accounts

# By username
user = Accounts.get_user_by_identifier("@johndoe")

# By numeric ID
user = Accounts.get_user_by_identifier("123")
user = Accounts.get_user_by_identifier(123)
```

**Function Implementation:**
```elixir
def get_user_by_identifier("@" <> username) do
  get_user_by_username(username)
end

def get_user_by_identifier(id) when is_binary(id) do
  case Integer.parse(id) do
    {int_id, ""} -> Repo.get(User, int_id)
    _ -> nil
  end
end

def get_user_by_identifier(id) when is_integer(id) do
  Repo.get(User, id)
end

def get_user_by_identifier(_), do: nil
```

#### Get User by Username

Direct username lookup (case-insensitive):

```elixir
user = Accounts.get_user_by_username("johndoe")
user = Accounts.get_user_by_username("JohnDoe")  # Same result
```

**Function Implementation:**
```elixir
def get_user_by_username(username) when is_binary(username) do
  # citext handles case-insensitivity at database level
  Repo.get_by(User, username: String.downcase(username))
end
```

### Router Configuration

**Routes:** `lib/homesite_web/router.ex:187-205`

**User Profile Route:**
```elixir
live "/users/:user_identifier", UserLive.Profile, :show
```

**Feed Routes:**
```elixir
get "/users/:user_identifier/rss.xml", FeedController, :user
get "/users/:user_identifier/feed.xml", FeedController, :user
get "/users/:user_identifier/feed.json", FeedController, :user
```

**Parameter:** `:user_identifier`
- Accepts numeric ID: `123`
- Accepts username with @ prefix: `@johndoe`

### Validation

**Schema:** `lib/homesite/accounts/user.ex:196-215`

```elixir
defp validate_username(changeset) do
  changeset
  |> validate_length(:username, min: 3, max: 30)
  |> validate_format(:username, ~r/^[a-z][a-z0-9_]{2,29}$/,
    message: "must start with letter, lowercase alphanumeric/underscore only"
  )
  |> validate_not_reserved(:username)
  |> unsafe_validate_unique(:username, Homesite.Repo)
  |> unique_constraint(:username)
end
```

**Reserved Words Validation:**
```elixir
@reserved_usernames ~w(
  admin api app auth blog dashboard dev docs feed feeds
  help home login logout new posts public register rss
  search settings signup staff static support system tags
  test user users www
)

defp validate_not_reserved(changeset, field) do
  validate_change(changeset, field, fn _, value ->
    if value in @reserved_usernames do
      [{field, "is reserved"}]
    else
      []
    end
  end)
end
```

### Change Tracking

**Table:** `username_changes`

**Schema:**
```elixir
schema "username_changes" do
  belongs_to :user, User
  field :old_username, :string
  field :new_username, :string
  field :changed_at, :utc_datetime
  field :ip_address, :string
  field :user_agent, :string

  timestamps(type: :utc_datetime)
end
```

**Update Function:**
```elixir
def update_user_username(user, attrs, opts \\ []) do
  old_username = user.username
  changeset = User.username_changeset(user, attrs)

  with {:ok, updated_user} <- Repo.update(changeset),
       new_username when new_username != old_username <- updated_user.username do
    # Log username change
    log_username_change(updated_user, old_username, new_username, opts)
    {:ok, updated_user}
  else
    {:error, _} = error -> error
    _ -> {:ok, changeset |> Ecto.Changeset.apply_changes()}
  end
end
```

**Logging Function:**
```elixir
defp log_username_change(user, old_username, new_username, opts) do
  %UsernameChange{}
  |> UsernameChange.changeset(%{
    user_id: user.id,
    old_username: old_username,
    new_username: new_username,
    changed_at: DateTime.utc_now(),
    ip_address: Keyword.get(opts, :ip_address),
    user_agent: Keyword.get(opts, :user_agent)
  })
  |> Repo.insert()
end
```

### Integration with Feed Controller

**File:** `lib/homesite_web/controllers/feed_controller.ex:108-185`

```elixir
def user(conn, %{"user_identifier" => user_identifier} = params) do
  user = Accounts.get_user_by_identifier(user_identifier)

  if user == nil do
    conn
    |> put_status(:not_found)
    |> put_resp_content_type("text/plain")
    |> send_resp(404, "User not found")
  else
    # Generate feed with username URL preference
    user_path = if user.username, do: "@#{user.username}", else: user.id
    link = url(~p"/users/#{user_path}")

    # ... feed generation logic
  end
end
```

### Migration Guide

**Adding Username Support to Existing Application:**

1. **Run Migration:**
   ```bash
   mix ecto.migrate
   ```

2. **Username Field:**
   - Nullable by default
   - Users can optionally claim usernames
   - Numeric IDs always work as fallback

3. **Backward Compatibility:**
   - All existing routes continue to work with numeric IDs
   - Users gradually adopt usernames
   - No breaking changes for existing users

4. **Testing:**
   ```elixir
   # Test both ID and username routes
   test "displays user profile with ID", %{conn: conn} do
     user = user_fixture()
     {:ok, _view, html} = live(conn, ~p"/users/#{user.id}")
     assert html =~ user.display_name
   end

   test "displays user profile with username", %{conn: conn} do
     user = user_fixture(%{username: "johndoe"})
     {:ok, _view, html} = live(conn, ~p"/users/@johndoe")
     assert html =~ user.display_name
   end
   ```

---

## Additional Resources

**Source Code:**
- User Schema: `lib/homesite/accounts/user.ex`
- Accounts Context: `lib/homesite/accounts.ex`
- Username Change Schema: `lib/homesite/accounts/username_change.ex`
- Router: `lib/homesite_web/router.ex`
- Profile LiveView: `lib/homesite_web/live/user_live/profile.ex`
- Settings LiveView: `lib/homesite_web/live/user_live/settings.ex`
- Feed Controller: `lib/homesite_web/controllers/feed_controller.ex`

**Tests:**
- Profile Tests: `test/homesite_web/live/user_live/profile_test.exs`
- Accounts Tests: `test/homesite/accounts_test.exs`
- Feed Controller Tests: `test/homesite_web/controllers/feed_controller_test.exs`

**Migrations:**
- Add Username: `priv/repo/migrations/20251130102533_add_username_to_users.exs`
- Username Changes: `priv/repo/migrations/20251130111433_add_username_changes.exs`

## Support

For issues or questions:
- Check GitHub issues for existing reports
- Create new issue with username and error details
- Include validation error messages
- Describe expected vs. actual behavior

---

**Last Updated:** December 2, 2025
**Version:** 1.1 - Added User Interface Features section
