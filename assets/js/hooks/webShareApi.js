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

      // Visual feedback
      const originalText = shareButton.textContent;
      shareButton.textContent = "Link Copied";
      setTimeout(() => {
        shareButton.textContent = originalText;
      }, 2000);
    });
  }
};

export default WebShareApi;
