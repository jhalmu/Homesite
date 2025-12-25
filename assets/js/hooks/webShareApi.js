const WebShareApi = {
  mounted() {
    const { title, url } = this.el.dataset;
    const shareData = { title, url };
    this.initializeSharing(shareData);
  },

  initializeSharing(shareData) {
    const shareButton = this.el.querySelector("button[data-share-btn]");

    if (navigator.share && navigator.canShare(shareData) && shareButton) {
      this.setupWebSharing(shareButton, shareData);
    } else if (shareButton) {
      this.setupFallbackSharing(shareButton, shareData);
    } else {
      console.error("Can not initialize sharing");
    }
  },

  setupWebSharing(shareButton, shareData) {
    shareButton.addEventListener("click", async () => {
      try {
        await navigator.share(shareData);
        // Track successful share
        this.pushEvent("track_share", {
          platform: "webshare",
          url: shareData.url
        });
      } catch (err) {
        // User cancelled or error - don't track
        console.error("Error sharing:", err);
      }
    });
  },

  setupFallbackSharing(shareButton, shareData) {
    shareButton.addEventListener("click", () => {
      navigator.clipboard.writeText(shareData.url);

      // Track clipboard copy
      this.pushEvent("track_share", {
        platform: "webshare",
        url: shareData.url
      });

      // Visual feedback - preserve HTML content
      const originalHTML = shareButton.innerHTML;
      const copiedText = shareButton.dataset.copiedText || "Link Copied";
      shareButton.innerHTML = `<svg class="h-4 w-4" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path></svg> ${copiedText}`;
      setTimeout(() => {
        shareButton.innerHTML = originalHTML;
      }, 2000);
    });
  }
};

export default WebShareApi;
