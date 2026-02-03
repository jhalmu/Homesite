# Registration Issue Fix - 2026-02-03

## Problem Report

User juha@halmu.fi tried to register but encountered errors that disappeared too quickly to read in production.

## Root Causes Identified

### 1. Registration Mode: Invite Only
**Status:** Working as designed, but not clearly communicated

The registration system is currently configured as "invite_only":
```sql
registration_mode | {"mode": "invite_only"}
```

This means:
- ✅ Users MUST provide a valid invitation code to register
- ❌ The user attempted to register without an invitation code (or with an invalid one)
- ❌ The error message disappeared before it could be read

### 2. Flash Message Timeout Too Short
**Status:** FIXED

Error and success messages were auto-dismissing after only 10 seconds, which is too fast for users to read and understand error messages, especially on mobile devices.

**Before:** 10 seconds
**After:** 30 seconds

### 3. Base Errors Not Displayed Prominently
**Status:** FIXED

When invitation code validation failed, the error was added to the changeset but not displayed in a prominent, easy-to-see location in the form.

## Changes Made

### 1. Increased Flash Message Timeout
**File:** `assets/js/app.js`

```javascript
// Before: 10000 (10 seconds)
this.timeout = setTimeout(() => {
  this.el.click()
}, 30000)  // After: 30 seconds
```

**Impact:** Users now have 3x longer to read error messages before they auto-dismiss.

### 2. Added Prominent Base Error Display
**File:** `lib/homesite_web/live/user_live/registration.ex`

Added a visible alert box at the top of the registration form that displays base-level errors (like invitation code validation failures) in a prominent red alert box with an icon:

```heex
<%!-- Display base errors (e.g., invitation code errors) prominently --%>
<%= if @form.errors[:base] do %>
  <div class="alert alert-error mb-[var(--spacing-md)]" role="alert">
    <.icon name="hero-exclamation-triangle" class="h-5 w-5" />
    <div>
      <%= for error <- @form.errors[:base] do %>
        <p><%= error %></p>
      <% end %>
    </div>
  </div>
<% end %>
```

**Impact:** Critical errors are now impossible to miss.

## Error Messages for Invitation Codes

The system provides clear error messages for different invitation code issues:

| Scenario | Error Message |
|----------|---------------|
| No code provided (invite_only mode) | "Invitation code is required" |
| Invalid code | "Invitation code is invalid" |
| Expired code | "Invitation code has expired" |
| Exhausted code | "Invitation code has been used too many times" |

## What Happened to juha@halmu.fi

Based on the investigation:

1. **Registration mode was "invite_only"** - requires valid invitation code
2. **User attempted registration** without providing a valid invitation code
3. **Error message was displayed** but disappeared after 10 seconds
4. **User couldn't read the error** before it auto-dismissed
5. **No prominent error display** made it easy to miss the error altogether

## Solutions Deployed

### For Users
- ✅ Error messages now stay visible for 30 seconds (3x longer)
- ✅ Base errors displayed in prominent red alert box
- ✅ Clearer visual feedback when something goes wrong

### For Admins
If you want to allow registration without invitation codes:

```elixir
# In IEx console or admin panel:
Homesite.Settings.update_setting("registration_mode", "open")
```

Or create an invitation code:
```elixir
# Create an invitation code valid for 7 days with 10 uses
{:ok, invite} = Homesite.Accounts.create_invitation(%{
  code: "WELCOME2024",
  expires_at: DateTime.add(DateTime.utc_now(), 7, :day),
  max_uses: 10
})
```

## Testing

All 1686 tests pass ✅

Specific registration tests verified:
- 12 registration page tests passing
- Error display working correctly
- Flash timeout updated without breaking functionality

## Deployment Notes

No database migration required. Changes are:
- Frontend JavaScript (flash timeout)
- LiveView template (error display)

Safe to deploy immediately.

## Future Enhancements

Consider adding:
1. **Visual indicator** of registration mode on the registration page
2. **Link to request invitation** if in invite_only mode
3. **Admin dashboard setting** to toggle registration mode (instead of SQL)
4. **Pre-filled invitation code** from URL parameter (already supported: `/users/register?invite=CODE`)

## Summary

✅ **Flash messages now stay visible for 30 seconds** (up from 10s)
✅ **Base errors displayed prominently** in red alert box
✅ **All tests passing**
✅ **Ready for production deployment**

The user should now be able to clearly see why registration failed (missing or invalid invitation code) with sufficient time to read and understand the error message.
