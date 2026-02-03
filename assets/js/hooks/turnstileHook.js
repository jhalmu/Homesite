function callbackEvent(self, name, eventName) {
  return (payload) => {
    const events = self.el.dataset.events || ""

    if (events.split(",").indexOf(name) > -1) {
      self.pushEventTo(self.el, `turnstile:${eventName || name}`, payload)
    }
  }
}

export const TurnstileHook = {
  mounted() {
    this.widgetId = null
    this.form = this.el.closest('form')
    this.renderWidget()

    this.handleEvent("turnstile:refresh", (event) => {
      if (!event.id || event.id === this.el.id) {
        this.resetWidget()
      }
    })

    this.handleEvent("turnstile:remove", (event) => {
      if (!event.id || event.id === this.el.id) {
        this.removeWidget()
      }
    })
  },

  destroyed() {
    this.removeWidget()
  },

  renderWidget() {
    if (typeof turnstile === 'undefined') {
      setTimeout(() => this.renderWidget(), 100)
      return
    }

    const options = {
      sitekey: this.el.dataset.sitekey,
      callback: (token) => {
        this.setToken(token)
        callbackEvent(this, "success")(token)
      },
      "error-callback": (errorCode) => {
        console.error('Turnstile error:', errorCode)
        callbackEvent(this, "error")(errorCode)
      },
      "expired-callback": () => {
        this.setToken('')
        callbackEvent(this, "expired")()
      },
      "timeout-callback": () => {
        this.setToken('')
        callbackEvent(this, "timeout")()
      },
      "before-interactive-callback": callbackEvent(this, "beforeInteractive", "before-interactive"),
      "after-interactive-callback": callbackEvent(this, "afterInteractive", "after-interactive"),
      "unsupported-callback": callbackEvent(this, "unsupported")
    }

    // Add any other data attributes (like theme, size, etc.)
    Object.keys(this.el.dataset).forEach(key => {
      if (key !== 'sitekey' && key !== 'events') {
        options[key] = this.el.dataset[key]
      }
    })

    this.widgetId = turnstile.render(this.el, options)
    console.log('Turnstile widget rendered with ID:', this.widgetId)
  },

  setToken(token) {
    const tokenInput = this.form?.querySelector('input[name="user[cf-turnstile-response]"]') ||
                       this.form?.querySelector('input[name="cf-turnstile-response"]')
    if (tokenInput) {
      tokenInput.value = token
      if (token) {
        console.log('Turnstile token set:', token.substring(0, 50) + '...')
      } else {
        console.log('Turnstile token cleared')
      }
    }
  },

  resetWidget() {
    if (this.widgetId !== null && typeof turnstile !== 'undefined') {
      turnstile.reset(this.widgetId)
      this.setToken('')
      console.log('Turnstile widget reset')
    }
  },

  removeWidget() {
    if (this.widgetId !== null && typeof turnstile !== 'undefined') {
      turnstile.remove(this.widgetId)
      this.widgetId = null
      console.log('Turnstile widget removed')
    }
  }
}
