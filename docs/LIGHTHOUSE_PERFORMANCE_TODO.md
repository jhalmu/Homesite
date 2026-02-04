# Lighthouse Performance Improvement TODO

**Current Score**: 54-71/100 (as of 2026-02-04)
- Dev mode (unminified): 54
- With minified JS: 71
**Target**: 80+

## Root Cause Analysis (2026-02-04)

The primary issue is **JavaScript bundle size**:

| Build Mode | app.js Size | Performance Score |
|------------|-------------|-------------------|
| Dev (unminified) | 5.8 MB | 54 |
| Minified | 970 KB | 71 |

Lighthouse simulates slow 4G (1.6 Mbps), so large bundles severely impact scores.

**Note**: Production builds (`mix assets.deploy`) already enable minification, so deployed sites will have the 71+ score.

## Detailed Analysis

Common causes for low Phoenix/LiveView performance scores:

### 1. Large JavaScript Bundle
- **Issue**: LiveView JS + custom hooks can create large bundles
- **Check**: Analyze `priv/static/assets/app.js` size
- **Solutions**:
  - Enable esbuild minification in production
  - Code-split unused JavaScript
  - Review custom hooks for optimization

### 2. Render-Blocking Resources
- **Issue**: CSS/JS blocking initial render
- **Solutions**:
  - Inline critical CSS
  - Defer non-critical JavaScript
  - Use `async` or `defer` on script tags

### 3. Image Optimization
- **Issue**: Unoptimized images, missing dimensions
- **Solutions**:
  - Add explicit width/height to images (prevents CLS)
  - Use WebP/AVIF formats
  - Implement lazy loading for below-fold images
  - Use responsive images with srcset

### 4. Server Response Time (TTFB)
- **Issue**: Slow initial HTML response
- **Solutions**:
  - Enable HTTP caching headers
  - Use CDN for static assets
  - Database query optimization
  - Connection pooling tuning

### 5. Cumulative Layout Shift (CLS)
- **Issue**: Elements shifting during page load
- **Solutions**:
  - Reserve space for dynamic content
  - Set dimensions on images and embeds
  - Avoid inserting content above existing content

### 6. First Contentful Paint (FCP) / Largest Contentful Paint (LCP)
- **Issue**: Slow initial render
- **Solutions**:
  - Optimize critical rendering path
  - Preload important resources
  - Server-side render critical content

## Action Items

### Already Done
- [x] JS minification in production (via `mix assets.deploy`)
- [x] CSS minification in production

### Quick Wins (Do First)
1. [ ] Add explicit dimensions to all images (prevents CLS)
2. [ ] Add `loading="lazy"` to below-fold images
3. [ ] Set cache headers for static assets in production
4. [ ] Minify CSS in dev mode for consistent testing

### Medium Effort - Reduce Bundle Size (970KB → target 500KB)
5. [ ] Analyze bundle with `npx esbuild-visualizer`
6. [ ] Code-split LiveView hooks (load on demand)
7. [ ] Tree-shake unused Phoenix/LiveView code
8. [ ] Review dependencies in assets/js/app.js

### Medium Effort - Other
9. [ ] Add preconnect hints for Google Fonts, Cloudflare
10. [ ] Implement critical CSS inlining
11. [ ] Review and optimize database queries on home page

### Larger Projects
12. [ ] Implement image optimization pipeline (WebP generation)
13. [ ] Set up CDN for static assets
14. [ ] Profile and optimize LiveView mount time

## How to Test

```bash
# Run Lighthouse audit
mix lighthouse

# Or manually via Chrome DevTools:
# 1. Open Chrome DevTools (F12)
# 2. Go to Lighthouse tab
# 3. Select "Performance" category
# 4. Click "Analyze page load"
```

## Related Issues
- Performance optimization tracking: Create GitHub issue when starting work

---
Created: 2026-02-04
