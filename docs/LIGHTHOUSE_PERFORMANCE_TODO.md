# Lighthouse Performance Improvement TODO

**Current Score**: 55/100 (as of 2026-02-04)
**Target**: 80+

## Analysis of Low Performance Score

The Lighthouse performance score of 55 indicates several areas need improvement. Common causes for low Phoenix/LiveView performance scores:

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

### Quick Wins (Do First)
1. [ ] Add explicit dimensions to all images
2. [ ] Enable CSS/JS minification in production config
3. [ ] Add `loading="lazy"` to below-fold images
4. [ ] Set cache headers for static assets

### Medium Effort
5. [ ] Analyze and reduce JavaScript bundle size
6. [ ] Implement critical CSS inlining
7. [ ] Add preconnect hints for external resources
8. [ ] Review and optimize database queries on home page

### Larger Projects
9. [ ] Implement image optimization pipeline (WebP generation)
10. [ ] Set up CDN for static assets
11. [ ] Profile and optimize LiveView mount time

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
