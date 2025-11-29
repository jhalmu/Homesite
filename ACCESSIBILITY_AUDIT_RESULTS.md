# Accessibility Audit Results

Date: 2025-11-29
Tool: axe-core via a11y_audit + PhoenixTest.Playwright

## Summary

Automated accessibility audit run on all major pages of the application using axe-core.

### Pages Tested

1. Login Page (`/users/log-in`)
2. User Settings Page (`/users/settings`)
3. Dashboard (`/dashboard`)
4. Homepage (`/`)

## Violations Found

### Login Page (`/users/log-in`)

#### 1. ✅ **Buttons must have discernible text** (CRITICAL) - FIXED

**Rule:** `button-name`
**Status:** ✅ **RESOLVED**

**Fix Applied:**
Added `aria-label` attributes to all icon-only buttons:
- Mobile menu button: `aria-label="Open menu"`
- Mobile menu close button: `aria-label="Close menu"`
- Theme toggle buttons: `aria-label="Use system/light/dark theme"`

---

#### 2. **Color Contrast Issues** (SERIOUS)

**Rule:** `color-contrast`
**Impact:** Serious
**WCAG:** 1.4.3 Contrast (Minimum) - Level AA
**Learn more:** https://dequeuniversity.com/rules/axe/4.11/color-contrast?application=axeAPI

**Description:** Text must have sufficient color contrast against background (4.5:1 for normal text, 3:1 for large text).

**Affected Elements:** Multiple

**Details:**
1. **Language toggle button** - 1.13:1 contrast (needs 4.5:1)
   - Foreground: #c9d1d9
   - Background: #c0c4cc
   - Font size: 9.6pt (12.8px)
   - Element: `<button class="flex w-1/2 cursor-pointer items-center justify-center p-1 text-xs font-semibold" ...>`

2. **Form labels** - 1.28:1 to 1.54:1 contrast
   - Foreground: #dfe3e8 to #c9d1d9
   - Background: #ffffff
   - Font sizes: 9.0pt to 13.5pt
   - Elements: Input labels like "Email"

**Fix Needed:**
Update light theme colors to increase contrast:
- Make text darker (lower lightness value in OKLCH)
- Ensure minimum 4.5:1 contrast ratio for all text
- Test with contrast checker tool

---

#### 3. **Landmark Structure Issues** (MODERATE)

**Multiple violations related to page landmarks:**

**3a. Duplicate Main Landmarks**
- **Rule:** `landmark-no-duplicate-main`
- **Issue:** Document has more than one `<main>` landmark
- **Affected:** Multiple `<main>` elements in layout

**3b. Main Contained in Landmark**
- **Rule:** `landmark-main-is-top-level`
- **Issue:** Main landmark should not be contained in another landmark
- **Affected:** `<main class="technical-main">` nested inside another landmark

**3c. Non-Unique Landmarks**
- **Rule:** `landmark-unique`
- **Issue:** Landmarks must have unique role or role/label/title combination
- **Affected:** `<main>` elements need unique labels

**3d. Content Outside Landmarks**
- **Rule:** `region`
- **Issue:** All page content should be contained by landmarks
- **Affected:** 4 elements including:
  - `<span class="font-display">Portal of JH</span>` (site title)
  - Navigation menu items (`<li>` elements)

**Fix Needed:**
- Remove duplicate `<main>` elements
- Wrap navigation in `<nav role="navigation">` landmark
- Ensure single top-level `<main>` element per page
- Add unique labels to repeated landmarks if needed

### Other Pages

#### Homepage (`/`)

**Status:** Same violations as login page plus additional issues
- Color contrast: 6 violations total
- Landmark issues: Same structural problems

#### Dashboard & Settings Pages

**Status:** Additional testing needed
**Note:** Initial tests showed database timeout - need to re-run with fixes applied

## Test Infrastructure Issues

### Database Connection Timeouts

**Issue:** Tests are timing out after ~15 seconds due to database connection limits.

**Error:**
```
** (DBConnection.ConnectionError) client timed out because it queued and checked out the connection for longer than 15000ms
```

**Cause:**
- Playwright tests are slower than regular tests
- `ensure_test_invitation/0` being called multiple times causing connection saturation

**Fix needed:**
1. Remove redundant `ensure_test_invitation/0` calls from individual test setups
2. Increase database checkout timeout for Playwright tests
3. Ensure test isolation with proper connection cleanup

## Next Steps

1. ✅ Install Playwright and set up infrastructure
2. ✅ Run initial accessibility audit
3. ✅ Document violations found on login page
4. 🔄 Fix database timeout issues
5. ⏳ Fix button accessibility violations
6. ⏳ Re-run full audit on all pages
7. ⏳ Address any additional violations found
8. ⏳ Verify all tests pass with 0 violations

## Notes

- Successfully integrated axe-core with PhoenixTest.Playwright
- Created custom JavaScript helper for executing axe-core in Playwright sessions
- Wallaby dependency satisfied by installing chromedriver (though not used for actual testing)
- Tests must be run with `export PATH="/tmp/chromedriver_bin:$PATH" && mix test --include playwright test/homesite_web/e2e/accessibility_test.exs`
