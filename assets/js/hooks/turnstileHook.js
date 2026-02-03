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
    // Extract all data attributes for Turnstile configuration
    const options = {
      sitekey: this.el.dataset.sitekey,
      callback: callbackEvent(this, "success"),
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
      }
    })

    this.handleEvent("turnstile:remove", (event) => {
      if (!event.id || event.id === this.el.id) {
        turnstile.remove(this.el)
      }
    })
  }
}
