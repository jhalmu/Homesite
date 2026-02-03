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
        // When Turnstile completes, update the token in the existing hidden input
        // Look for the input with the correct name attribute for LiveView forms
        const tokenInput = form?.querySelector('input[name="user[cf-turnstile-response]"]') ||
                          form?.querySelector('input[name="cf-turnstile-response"]')

        if (tokenInput) {
          tokenInput.value = token
          console.log('Turnstile token set:', token.substring(0, 50) + '...')
        } else {
          console.error('Could not find Turnstile token input field')
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
