/**
 * CopyToClipboard Hook
 * Copies a URL to clipboard when button is clicked
 */
const CopyToClipboard = {
  mounted() {
    this.el.addEventListener("click", () => this.copyToClipboard())
  },

  copyToClipboard() {
    const url = this.el.dataset.url
    const copiedText = this.el.dataset.copiedText || "Copied!"
    const labelEl = this.el.querySelector("[data-label]")
    const originalText = labelEl ? labelEl.textContent : null

    navigator.clipboard.writeText(url).then(() => {
      // Show success feedback
      if (labelEl) {
        labelEl.textContent = copiedText
        setTimeout(() => {
          labelEl.textContent = originalText
        }, 2000)
      }

      // Add visual feedback
      this.el.classList.add("btn-success")
      setTimeout(() => {
        this.el.classList.remove("btn-success")
      }, 2000)
    }).catch((err) => {
      console.error("Failed to copy:", err)
      // Fallback for older browsers
      this.fallbackCopy(url)
    })
  },

  fallbackCopy(text) {
    const textArea = document.createElement("textarea")
    textArea.value = text
    textArea.style.position = "fixed"
    textArea.style.left = "-999999px"
    document.body.appendChild(textArea)
    textArea.select()
    try {
      document.execCommand("copy")
    } catch (err) {
      console.error("Fallback copy failed:", err)
    }
    document.body.removeChild(textArea)
  }
}

export default CopyToClipboard
