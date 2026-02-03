// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {hooks as colocatedHooks} from "phoenix-colocated/homesite"
import topbar from "../vendor/topbar"
import WebShareApi from "./hooks/webShareApi"
import CopyToClipboard from "./hooks/copyToClipboard"
import { SortableProjects, SortableSections } from "./hooks/sortable"
import { TurnstileHook } from "./hooks/turnstileHook"
import Chart from "chart.js/auto"
import ApexCharts from "apexcharts"

// Custom hooks for date formatting
const Hooks = {
  LocalTime: {
    mounted() {
      this.formatTime()
    },
    updated() {
      this.formatTime()
    },
    formatTime() {
      const datetime = this.el.getAttribute('datetime')
      const locale = this.el.dataset.locale || navigator.language
      const showRelative = this.el.dataset.relative === 'true'

      if (!datetime) return

      const date = new Date(datetime)

      if (showRelative) {
        // Show relative time for recent posts
        const rtf = new Intl.RelativeTimeFormat(locale, { numeric: 'auto' })
        const now = new Date()
        const diffInSeconds = Math.floor((date - now) / 1000)
        const diffInMinutes = Math.floor(diffInSeconds / 60)
        const diffInHours = Math.floor(diffInMinutes / 60)
        const diffInDays = Math.floor(diffInHours / 24)

        let formatted
        if (Math.abs(diffInDays) > 7) {
          // Use absolute date for posts older than 7 days
          formatted = new Intl.DateTimeFormat(locale, {
            year: 'numeric',
            month: 'long',
            day: 'numeric'
          }).format(date)
        } else if (Math.abs(diffInDays) >= 1) {
          formatted = rtf.format(diffInDays, 'day')
        } else if (Math.abs(diffInHours) >= 1) {
          formatted = rtf.format(diffInHours, 'hour')
        } else {
          formatted = rtf.format(diffInMinutes, 'minute')
        }

        this.el.textContent = formatted
      } else {
        // Show full formatted date
        const formatted = new Intl.DateTimeFormat(locale, {
          year: 'numeric',
          month: 'long',
          day: 'numeric'
        }).format(date)

        this.el.textContent = formatted
      }
    }
  },
  AvatarPreview: {
    mounted() {
      const fileInput = this.el.querySelector('input[type="file"]')
      const avatarImg = this.el.querySelector('#avatar-preview')

      if (!fileInput || !avatarImg) return

      fileInput.addEventListener('change', (e) => {
        const file = e.target.files[0]

        if (file && file.type.startsWith('image/')) {
          const reader = new FileReader()

          reader.onload = (e) => {
            avatarImg.src = e.target.result
          }

          reader.readAsDataURL(file)
        }
      })
    }
  },
  AutoDismissFlash: {
    mounted() {
      // Auto-dismiss flash message after 30 seconds (increased from 10s for better visibility)
      this.timeout = setTimeout(() => {
        // Trigger the click event to dismiss the flash
        this.el.click()
      }, 30000)
    },
    destroyed() {
      // Clear timeout if flash is manually dismissed before 30 seconds
      if (this.timeout) {
        clearTimeout(this.timeout)
      }
    }
  },
  Share: {
    mounted() {
      this.handleEvent("share", async ({title, text, url}) => {
        if (navigator.share) {
          try {
            await navigator.share({title, text, url})
          } catch (err) {
            console.log("Share cancelled or failed:", err)
          }
        }
      })
    }
  },
  WebShareApi,
  CopyToClipboard,
  SortableProjects,
  SortableSections,
  Turnstile: TurnstileHook,
  CopyButton: {
    mounted() {
      this.el.addEventListener('click', () => {
        const text = this.el.dataset.clipboardText
        if (text) {
          navigator.clipboard.writeText(text).then(() => {
            // Show success feedback
            const originalText = this.el.innerHTML
            this.el.innerHTML = '<svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path></svg> Copied!'

            // Restore original text after 2 seconds
            setTimeout(() => {
              this.el.innerHTML = originalText
            }, 2000)
          }).catch((err) => {
            console.error("Failed to copy to clipboard:", err)
          })
        }
      })
    }
  },
  TableOfContents: {
    mounted() {
      this.observer = null
      this.links = this.el.querySelectorAll('.toc-link')
      this.sections = []

      // Find all sections that TOC links point to
      this.links.forEach(link => {
        const targetId = link.dataset.target
        const section = document.getElementById(targetId)
        if (section) {
          this.sections.push({id: targetId, element: section, link: link})
        }
      })

      // Set up Intersection Observer for active section tracking
      this.setupObserver()

      // Handle smooth scroll on TOC link click
      this.links.forEach(link => {
        link.addEventListener('click', (e) => {
          e.preventDefault()
          const targetId = link.dataset.target
          const target = document.getElementById(targetId)

          if (target) {
            // Get scroll-margin-top from element's computed style
            const style = window.getComputedStyle(target)
            const scrollMarginTop = parseInt(style.scrollMarginTop) || 96

            // Calculate target position with offset
            const targetPosition = target.getBoundingClientRect().top + window.pageYOffset - scrollMarginTop

            // Smooth scroll to position
            window.scrollTo({
              top: targetPosition,
              behavior: 'smooth'
            })

            // Update URL hash without jumping
            if (history.pushState) {
              history.pushState(null, null, `#${targetId}`)
            } else {
              location.hash = `#${targetId}`
            }
          }
        })
      })

      // Highlight current section on mount (if hash in URL)
      const hash = window.location.hash.slice(1)
      if (hash) {
        this.setActiveLink(hash)
      }
    },

    setupObserver() {
      const options = {
        root: null,
        rootMargin: '-10% 0px -80% 0px', // Trigger when section enters top 10% of viewport
        threshold: 0
      }

      this.observer = new IntersectionObserver((entries) => {
        // Find all currently intersecting sections
        const intersectingSections = this.sections
          .filter(section => {
            const rect = section.element.getBoundingClientRect()
            const windowHeight = window.innerHeight
            // Section is visible if its top is above 10% viewport and bottom is below 10%
            return rect.top < windowHeight * 0.1 && rect.bottom > windowHeight * 0.1
          })

        // Pick the topmost intersecting section
        if (intersectingSections.length > 0) {
          const topmost = intersectingSections.reduce((top, current) => {
            const topRect = top.element.getBoundingClientRect()
            const currentRect = current.element.getBoundingClientRect()
            return currentRect.top < topRect.top ? current : top
          })

          this.setActiveLink(topmost.id)
        }
      }, options)

      // Observe all sections
      this.sections.forEach(section => {
        this.observer.observe(section.element)
      })

      // Also update on scroll (for smoother tracking)
      this.scrollHandler = () => {
        const intersectingSections = this.sections
          .filter(section => {
            const rect = section.element.getBoundingClientRect()
            const windowHeight = window.innerHeight
            return rect.top < windowHeight * 0.1 && rect.bottom > windowHeight * 0.1
          })

        if (intersectingSections.length > 0) {
          const topmost = intersectingSections.reduce((top, current) => {
            const topRect = top.element.getBoundingClientRect()
            const currentRect = current.element.getBoundingClientRect()
            return currentRect.top < topRect.top ? current : top
          })

          this.setActiveLink(topmost.id)
        }
      }

      window.addEventListener('scroll', this.scrollHandler, {passive: true})
    },

    setActiveLink(targetId) {
      // Remove active class from all links
      this.links.forEach(link => {
        link.classList.remove('bg-primary', 'text-primary-content', 'opacity-100')
        link.classList.add('opacity-70')
      })

      // Add active class to matching link
      const activeLink = Array.from(this.links).find(link => link.dataset.target === targetId)
      if (activeLink) {
        activeLink.classList.remove('opacity-70')
        activeLink.classList.add('bg-primary', 'text-primary-content', 'opacity-100')
      }
    },

    destroyed() {
      if (this.observer) {
        this.observer.disconnect()
      }
      if (this.scrollHandler) {
        window.removeEventListener('scroll', this.scrollHandler)
      }
    }
  },
  DownloadHTML: {
    mounted() {
      this.handleEvent("download-html", ({filename, content}) => {
        const blob = new Blob([content], {type: 'text/html'})
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = filename
        document.body.appendChild(a)
        a.click()
        document.body.removeChild(a)
        URL.revokeObjectURL(url)
        console.log("HTML file downloaded:", filename)
      })
    }
  },
  OpenWindow: {
    mounted() {
      this.handleEvent("open_window", ({url}) => {
        window.open(url, '_blank', 'noopener,noreferrer')
      })
    }
  },
  ChatScroll: {
    mounted() {
      // Scroll to bottom on mount
      this.scrollToBottom()

      // Listen for scroll_to_bottom event from server
      this.handleEvent("scroll_to_bottom", () => {
        this.scrollToBottom()
      })
    },
    updated() {
      // Auto-scroll if user is near bottom (within 100px)
      if (this.isNearBottom()) {
        this.scrollToBottom()
      }
    },
    scrollToBottom() {
      this.el.scrollTop = this.el.scrollHeight
    },
    isNearBottom() {
      const threshold = 100
      return this.el.scrollHeight - this.el.scrollTop - this.el.clientHeight < threshold
    }
  },
  // Hook for select elements that need to send value without form conflicts
  SelectValue: {
    mounted() {
      this.el.addEventListener("change", (e) => {
        const event = this.el.dataset.event
        const field = this.el.dataset.field
        if (event) {
          this.pushEvent(event, {
            field: field,
            value: e.target.value
          })
        }
      })
    }
  },
  AutoGrow: {
    mounted() {
      this.el.style.overflow = "hidden"
      this.el.style.minHeight = "200px"
      this.resize()
      this.el.addEventListener("input", () => this.resize())
    },
    updated() {
      // Preserve scroll position during LiveView updates
      const scrollY = window.scrollY
      const scrollX = window.scrollX
      this.resize()
      window.scrollTo(scrollX, scrollY)
    },
    resize() {
      // Store current height to check if resize is needed
      const currentHeight = this.el.style.height
      this.el.style.height = "auto"
      const newHeight = this.el.scrollHeight + "px"

      // Only update if height actually changed
      if (currentHeight !== newHeight) {
        this.el.style.height = newHeight
      } else {
        this.el.style.height = currentHeight
      }
    }
  },
  // Chart.js hook for analytics visualizations (legacy)
  ChartJS: {
    mounted() {
      this.chart = null
      this.renderChart()
    },
    updated() {
      this.renderChart()
    },
    destroyed() {
      if (this.chart) {
        this.chart.destroy()
      }
    },
    renderChart() {
      const config = JSON.parse(this.el.dataset.chart)

      if (this.chart) {
        this.chart.destroy()
      }

      // Default styling for dark/light mode compatibility
      const isDark = document.documentElement.getAttribute('data-theme')?.includes('dark') ||
                     window.matchMedia('(prefers-color-scheme: dark)').matches

      const textColor = isDark ? '#a6adbb' : '#1f2937'
      const gridColor = isDark ? 'rgba(166, 173, 187, 0.1)' : 'rgba(31, 41, 55, 0.1)'

      // Apply default options
      Chart.defaults.color = textColor
      Chart.defaults.borderColor = gridColor

      this.chart = new Chart(this.el, {
        type: config.type,
        data: config.data,
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            legend: {
              display: config.showLegend !== false,
              position: config.legendPosition || 'bottom',
              labels: { color: textColor }
            }
          },
          scales: config.type === 'doughnut' || config.type === 'pie' ? {} : {
            x: {
              grid: { color: gridColor },
              ticks: { color: textColor }
            },
            y: {
              grid: { color: gridColor },
              ticks: { color: textColor },
              beginAtZero: true
            }
          },
          ...config.options
        }
      })
    }
  },
  // ApexCharts hook for modern analytics visualizations
  ApexChart: {
    mounted() {
      this.chart = null
      this.renderChart()
      // Listen for theme changes
      this.themeObserver = new MutationObserver(() => this.renderChart())
      this.themeObserver.observe(document.documentElement, {
        attributes: true,
        attributeFilter: ['data-theme']
      })
    },
    updated() {
      this.renderChart()
    },
    destroyed() {
      if (this.chart) {
        this.chart.destroy()
      }
      if (this.themeObserver) {
        this.themeObserver.disconnect()
      }
    },
    renderChart() {
      const config = JSON.parse(this.el.dataset.chart)

      if (this.chart) {
        this.chart.destroy()
      }

      // Detect dark/light mode
      const isDark = document.documentElement.getAttribute('data-theme')?.includes('dark') ||
                     window.matchMedia('(prefers-color-scheme: dark)').matches

      // Modern color palette
      const colors = config.colors || [
        '#6366f1', // indigo
        '#22c55e', // green
        '#f59e0b', // amber
        '#ef4444', // red
        '#8b5cf6', // violet
        '#06b6d4', // cyan
        '#ec4899', // pink
        '#14b8a6'  // teal
      ]

      // Base theme configuration
      const theme = {
        mode: isDark ? 'dark' : 'light',
        palette: 'palette1'
      }

      // Check if sparkline mode
      const isSparkline = config.sparkline || (config.options?.chart?.sparkline?.enabled)

      // Common chart options
      const baseOptions = {
        chart: {
          type: config.type || 'bar',
          height: config.height || '100%',
          background: 'transparent',
          fontFamily: 'inherit',
          toolbar: { show: false },
          sparkline: isSparkline ? { enabled: true } : { enabled: false },
          animations: {
            enabled: true,
            easing: 'easeinout',
            speed: 400
          },
          dropShadow: {
            enabled: config.type === 'donut' || config.type === 'pie',
            blur: 3,
            opacity: 0.2
          }
        },
        theme: theme,
        colors: colors,
        stroke: {
          curve: 'smooth',
          width: config.options?.stroke?.width ?? (config.type === 'line' || config.type === 'area' ? 3 : 0)
        },
        fill: {
          type: config.type === 'area' ? 'gradient' : 'solid',
          gradient: {
            shadeIntensity: 1,
            opacityFrom: 0.4,
            opacityTo: 0.1,
            stops: [0, 90, 100]
          }
        },
        grid: {
          borderColor: isDark ? 'rgba(166, 173, 187, 0.1)' : 'rgba(31, 41, 55, 0.1)',
          strokeDashArray: 4
        },
        dataLabels: {
          enabled: config.dataLabels !== false && (config.type === 'donut' || config.type === 'pie')
        },
        legend: {
          show: config.showLegend !== false,
          position: config.legendPosition || 'bottom',
          horizontalAlign: 'center',
          labels: {
            colors: isDark ? '#a6adbb' : '#1f2937'
          }
        },
        tooltip: {
          theme: isDark ? 'dark' : 'light',
          style: {
            fontSize: '12px'
          }
        },
        plotOptions: {
          bar: {
            horizontal: config.horizontal || false,
            borderRadius: 4,
            columnWidth: '60%',
            distributed: config.distributed || false
          },
          pie: {
            donut: {
              size: '65%',
              labels: {
                show: true,
                total: {
                  show: true,
                  label: 'Total',
                  color: isDark ? '#a6adbb' : '#1f2937'
                }
              }
            }
          }
        },
        xaxis: {
          categories: config.categories || [],
          labels: {
            style: {
              colors: isDark ? '#a6adbb' : '#1f2937',
              fontSize: '12px'
            }
          },
          axisBorder: { show: false },
          axisTicks: { show: false }
        },
        yaxis: {
          labels: {
            style: {
              colors: isDark ? '#a6adbb' : '#1f2937',
              fontSize: '12px'
            }
          }
        },
        // Merge any custom options
        ...config.options
      }

      // Set series data
      baseOptions.series = config.series || []

      this.chart = new ApexCharts(this.el, baseOptions)
      this.chart.render()
    }
  }
}

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {...colocatedHooks, ...Hooks},
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// Scroll-hide navbar: hide on scroll down, show on scroll up
;(function initScrollHideNavbar() {
  let lastScrollY = window.scrollY
  let ticking = false
  let initialized = false

  function setup() {
    if (initialized) return
    const navbar = document.querySelector('.technical-header')
    if (!navbar) return

    initialized = true
    console.log('Scroll-hide navbar initialized')

    window.addEventListener('scroll', () => {
      if (!ticking) {
        window.requestAnimationFrame(() => {
          const currentScrollY = window.scrollY

          // Only hide after scrolling down past 100px
          if (currentScrollY > 100) {
            if (currentScrollY > lastScrollY) {
              // Scrolling down - hide navbar
              navbar.classList.add('nav-hidden')
            } else {
              // Scrolling up - show navbar
              navbar.classList.remove('nav-hidden')
            }
          } else {
            // At top of page - always show
            navbar.classList.remove('nav-hidden')
          }

          lastScrollY = currentScrollY
          ticking = false
        })
        ticking = true
      }
    }, { passive: true })
  }

  // Try immediately
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', setup)
  } else {
    setup()
  }
})()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", e => keyDown = null)
    window.addEventListener("click", e => {
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}

