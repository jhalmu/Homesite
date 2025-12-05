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
      // Auto-dismiss flash message after 10 seconds
      this.timeout = setTimeout(() => {
        // Trigger the click event to dismiss the flash
        this.el.click()
      }, 10000)
    },
    destroyed() {
      // Clear timeout if flash is manually dismissed before 10 seconds
      if (this.timeout) {
        clearTimeout(this.timeout)
      }
    }
  },
  CopyToClipboard: {
    mounted() {
      this.handleEvent("copy-to-clipboard", ({text}) => {
        navigator.clipboard.writeText(text).then(() => {
          console.log("Copied to clipboard:", text)
        }).catch((err) => {
          console.error("Failed to copy to clipboard:", err)
        })
      })
    }
  },
  Share: {
    mounted() {
      this.handleEvent("share", async ({title, text, url}) => {
        if (navigator.share) {
          try {
            await navigator.share({title, text, url})
            console.log("Shared successfully:", url)
          } catch (err) {
            // User cancelled or error - fallback to copy
            if (err.name !== 'AbortError') {
              console.log("Share failed, copying to clipboard:", err)
              navigator.clipboard.writeText(url)
            }
          }
        } else {
          // Fallback: copy to clipboard
          navigator.clipboard.writeText(url).then(() => {
            console.log("Link copied to clipboard:", url)
          }).catch((err) => {
            console.error("Failed to copy:", err)
          })
        }
      })
    }
  },
  WebShareApi,
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

