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
    // Find the parent form
    const form = this.el.closest('form')

    // Extract all data attributes for Turnstile configuration
    const options = {
      sitekey: this.el.dataset.sitekey,
      callback: (token) => {
        // When Turnstile completes, inject the token into the form
        // Remove any existing hidden input first
        const existingInput = form?.querySelector('input[name="cf-turnstile-response"]')
        if (existingInput) {
          existingInput.value = token
        } else if (form) {
          // Create hidden input for the token
          const input = document.createElement('input')
          input.type = 'hidden'
          input.name = 'cf-turnstile-response'
          input.value = token
          form.appendChild(input)
        }

        // Also call the event callback
        callbackEvent(this, "success")(token)
      },
      "error-callback": callbackEvent(this, "error"),
      "expired-callback": callbackEvent(this, "expired"),
      "before-interactive-callback": callbackEvent(this, "beforeInteractive", "before-interactive"),
      "after-interactive-callback": callbackEvent(this, "afterInteractive", "after-interactive"),
      "unsupported-callback": callbackEvent(this, "unsupported"),
      "timeout-callback": callbackEvent(this, "timeout")
    }

    // Add any other data attributes (like theme, size, etc.)
    Object.keys(this.el.dataset).forEach(key => {
      if (key !== 'sitekey' && key !== 'events') {
        options[key] = this.el.dataset[key]
      }
    })

    turnstile.render(this.el, options)

    this.handleEvent("turnstile:refresh", (event) => {
      if (!event.id || event.id === this.el.id) {
        turnstile.reset(this.el)
        // Clear the hidden input when refreshing
        const input = form?.querySelector('input[name="cf-turnstile-response"]')
        if (input) input.value = ''
      }
    })

    this.handleEvent("turnstile:remove", (event) => {
      if (!event.id || event.id === this.el.id) {
        turnstile.remove(this.el)
        // Remove the hidden input
        const input = form?.querySelector('input[name="cf-turnstile-response"]')
        if (input) input.remove()
      }
    })
  }
}
