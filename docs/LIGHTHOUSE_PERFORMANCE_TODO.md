# Lighthouse Performance Improvement TODO

**Current Score**: 80/100 (as of 2026-02-04)
**Target**: 80+ (ACHIEVED)

## Optimization Summary (2026-02-04)

Successfully improved performance from 71 to 80 through:

1. **Removed unused chart.js** (was 161KB minified)
   - ChartJS hook was marked "legacy" but never used
   - ApexCharts provides same functionality

2. **Enabled esbuild code splitting**
   - Added `--splitting --format=esm` to esbuild config
   - Changed script tag to `type="module"`
   - ApexCharts now loads dynamically only on admin dashboard

### Bundle Size Comparison

| Version | app.js Size | ApexCharts (lazy) | Total | Performance Score |
|---------|-------------|-------------------|-------|-------------------|
| Before optimization | 970 KB | - | 970 KB | 71 |
| After optimization | 180 KB | 566 KB (on demand) | 180 KB* | 80 |

*Regular users only download 180KB. Admin dashboard users load additional 566KB when viewing charts.

## Root Cause Analysis (2026-02-04)

The primary issue was **JavaScript bundle size**:

| Build Mode | app.js Size | Performance Score |
|------------|-------------|-------------------|
| Dev (unminified) | 5.8 MB | 54 |
| Minified (before) | 970 KB | 71 |
| Minified (after code-split) | 180 KB | 80 |

Lighthouse simulates slow 4G (1.6 Mbps), so large bundles severely impact scores.

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

### Completed
- [x] JS minification in production (via `mix assets.deploy`)
- [x] CSS minification in production
- [x] Remove unused chart.js dependency (saved 161KB)
- [x] Code-split ApexCharts with dynamic imports (566KB loaded on demand)
- [x] Enable esbuild splitting for ESM output
- [x] Update script tag to `type="module"`
- [x] Analyze bundle with esbuild --analyze
- [x] Preconnect hints for Google Fonts (already had)

### Quick Wins (Optional - Score already at 80)
1. [ ] Add explicit dimensions to all images (prevents CLS)
2. [ ] Add `loading="lazy"` to below-fold images
3. [ ] Set cache headers for static assets in production

### Medium Effort - Further Improvements (if targeting 90+)
4. [ ] Tree-shake unused Phoenix/LiveView code
5. [ ] Implement critical CSS inlining
6. [ ] Review and optimize database queries on home page

### Larger Projects (if targeting 95+)
7. [ ] Implement image optimization pipeline (WebP generation)
8. [ ] Set up CDN for static assets
9. [ ] Profile and optimize LiveView mount time

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
- Performance optimization tracking: Target achieved (80+)

---
Created: 2026-02-04
Updated: 2026-02-04 (Code splitting optimization completed)
