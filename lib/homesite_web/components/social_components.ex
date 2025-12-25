defmodule HomesiteWeb.SocialComponents do
  @moduledoc """
  Social sharing components for posts and other content.
  """
  use Phoenix.Component
  use Gettext, backend: HomesiteWeb.Gettext

  @doc """
  Native Web Share API button with clipboard fallback.
  Uses JavaScript hook to detect browser capability.

  ## Examples

      <.web_share_button url={@current_url} title={@post.title} />
  """
  attr :url, :string, required: true
  attr :title, :string, required: true
  attr :class, :string, default: nil

  def web_share_button(assigns) do
    # Generate unique ID using the URL hash to avoid duplicate IDs on pages with multiple share buttons
    unique_id = "web-share-#{:erlang.phash2(assigns.url)}"
    assigns = assign(assigns, :unique_id, unique_id)

    ~H"""
    <div
      id={@unique_id}
      phx-hook="WebShareApi"
      data-title={@title}
      data-url={@url}
      class={@class}
    >
      <button
        data-share-btn
        data-copied-text={gettext("Link copied!")}
        type="button"
        class="btn btn-ghost btn-sm gap-[var(--space-xs)]"
      >
        {share_icon(%{class: "h-5 w-5"})}
        <span>{gettext("Share this post")}</span>
      </button>
    </div>
    """
  end

  @doc """
  Renders social share buttons for a given URL and title.
  Displays native Web Share API button first, then platform-specific buttons.

  ## Examples

      <.social_share_buttons url={@current_url} title={@post.title} />
  """
  attr :url, :string, required: true
  attr :title, :string, required: true
  attr :class, :string, default: ""

  def social_share_buttons(assigns) do
    ~H"""
    <div class={"#{@class} space-y-[var(--space-sm)]"}>
      <%!-- Native Web Share (primary option) --%>
      <.web_share_button title={@title} url={@url} class="mb-[var(--space-sm)]" />

      <%!-- Platform Share Buttons (alternative options) --%>
      <div class="mb-[var(--space-xs)] text-[var(--text-xs)] opacity-40">Share:</div>
      <div class="gap-[var(--space-xs)] flex flex-wrap">
        <.share_button platform="bluesky" url={@url} title={@title} />
        <.share_button platform="mastodon" url={@url} title={@title} />
        <.share_button platform="facebook" url={@url} title={@title} />
        <.share_button platform="linkedin" url={@url} title={@title} />
        <.share_button platform="email" url={@url} title={@title} />
      </div>
    </div>
    """
  end

  @doc """
  Platform-specific share buttons without Web Share API button.
  Used for longer posts (2+ min read time) where platform sharing is preferred.

  ## Examples

      <.platform_share_buttons url={@current_url} title={@post.title} />
  """
  attr :url, :string, required: true
  attr :title, :string, required: true

  def platform_share_buttons(assigns) do
    ~H"""
    <div class="gap-[var(--space-xs)] flex flex-wrap">
      <div class="mb-[var(--space-xs)] text-[var(--text-xs)] w-full opacity-40">Share:</div>
      <.share_button platform="bluesky" url={@url} title={@title} />
      <.share_button platform="mastodon" url={@url} title={@title} />
      <.share_button platform="facebook" url={@url} title={@title} />
      <.share_button platform="linkedin" url={@url} title={@title} />
      <.share_button platform="email" url={@url} title={@title} />
    </div>
    """
  end

  attr :platform, :string, required: true
  attr :url, :string, required: true
  attr :title, :string, required: true

  defp share_button(assigns) do
    share_url = build_share_url(assigns.platform, assigns.url, assigns.title)
    icon_function = platform_icon(assigns.platform)
    label = platform_label(assigns.platform)

    assigns =
      assigns
      |> assign(:share_url, share_url)
      |> assign(:icon_function, icon_function)
      |> assign(:label, label)

    ~H"""
    <a
      href={@share_url}
      target="_blank"
      rel="noopener noreferrer"
      class="btn btn-sm btn-ghost gap-[var(--space-xs)]"
      title={"Share on #{@label}"}
    >
      {apply(__MODULE__, @icon_function, [%{class: "h-4 w-4"}])}
      <span class="hidden sm:inline">{@label}</span>
    </a>
    """
  end

  # Build share URLs for different platforms
  defp build_share_url("bluesky", url, title) do
    text = URI.encode_www_form("#{title} #{url}")
    "https://bsky.app/intent/compose?text=#{text}"
  end

  defp build_share_url("mastodon", url, title) do
    text = URI.encode_www_form("#{title} #{url}")
    # Opens Mastodon share dialog (user chooses their instance)
    "https://mastodonshare.com/?text=#{text}"
  end

  defp build_share_url("twitter", url, title) do
    text = URI.encode_www_form(title)
    "https://twitter.com/intent/tweet?text=#{text}&url=#{URI.encode_www_form(url)}"
  end

  defp build_share_url("facebook", url, _title) do
    "https://www.facebook.com/sharer/sharer.php?u=#{URI.encode_www_form(url)}"
  end

  defp build_share_url("linkedin", url, title) do
    "https://www.linkedin.com/sharing/share-offsite/?url=#{URI.encode_www_form(url)}&title=#{URI.encode_www_form(title)}"
  end

  defp build_share_url("email", url, title) do
    subject = URI.encode_www_form(title)
    body = URI.encode_www_form("Check out this post: #{url}")
    "mailto:?subject=#{subject}&body=#{body}"
  end

  defp build_share_url("instagram", _url, _title) do
    # Instagram doesn't have a web share intent URL
    # Link to Instagram homepage
    "https://www.instagram.com/"
  end

  # Map platforms to custom icon functions
  defp platform_icon("bluesky"), do: :bluesky_icon
  defp platform_icon("mastodon"), do: :mastodon_icon
  defp platform_icon("twitter"), do: :twitter_icon
  defp platform_icon("facebook"), do: :facebook_icon
  defp platform_icon("linkedin"), do: :linkedin_icon
  defp platform_icon("instagram"), do: :instagram_icon
  defp platform_icon("email"), do: :email_icon

  # Platform labels
  defp platform_label("bluesky"), do: "Bluesky"
  defp platform_label("mastodon"), do: "Mastodon"
  defp platform_label("twitter"), do: "X"
  defp platform_label("facebook"), do: "Facebook"
  defp platform_label("linkedin"), do: "LinkedIn"
  defp platform_label("instagram"), do: "Instagram"
  defp platform_label("email"), do: "Email"

  # Brand icon SVGs (from Simple Icons: https://simpleicons.org/)
  # Note: These are public functions (def) because they're called dynamically via apply/3

  def bluesky_icon(assigns) do
    ~H"""
    <svg viewBox="0 0 24 24" aria-hidden="true" class={@class} fill="currentColor">
      <path d="M12 10.8c-1.087-2.114-4.046-6.053-6.798-7.995C2.566.944 1.561 1.266.902 1.565C.139 1.908 0 3.08 0 3.768c0 .69.378 5.65.624 6.479c.815 2.736 3.713 3.66 6.383 3.364q.204-.03.415-.056q-.207.033-.415.056c-3.912.58-7.387 2.005-2.83 7.078c5.013 5.19 6.87-1.113 7.823-4.308c.953 3.195 2.05 9.271 7.733 4.308c4.267-4.308 1.172-6.498-2.74-7.078a9 9 0 0 1-.415-.056q.21.026.415.056c2.67.297 5.568-.628 6.383-3.364c.246-.828.624-5.79.624-6.478c0-.69-.139-1.861-.902-2.206c-.659-.298-1.664-.62-4.3 1.24C16.046 4.748 13.087 8.687 12 10.8" />
    </svg>
    """
  end

  def mastodon_icon(assigns) do
    ~H"""
    <svg viewBox="0 0 24 24" aria-hidden="true" class={@class} fill="currentColor">
      <path d="M23.268 5.313c-.35-2.578-2.617-4.61-5.304-5.004C17.51.242 15.792 0 11.813 0h-.03c-3.98 0-4.835.242-5.288.309C3.882.692 1.496 2.518.917 5.127.64 6.412.61 7.837.661 9.143c.074 1.874.088 3.745.26 5.611.118 1.24.325 2.47.62 3.68.55 2.237 2.777 4.098 4.96 4.857 2.336.792 4.849.923 7.256.38.265-.061.527-.132.786-.213.585-.184 1.27-.39 1.774-.753a.057.057 0 0 0 .023-.043v-1.809a.052.052 0 0 0-.02-.041.053.053 0 0 0-.046-.01 20.282 20.282 0 0 1-4.709.545c-2.73 0-3.463-1.284-3.674-1.818a5.593 5.593 0 0 1-.319-1.433.053.053 0 0 1 .066-.054c1.517.363 3.072.546 4.632.546.376 0 .75 0 1.125-.01 1.57-.044 3.224-.124 4.768-.422.038-.008.077-.015.11-.024 2.435-.464 4.753-1.92 4.989-5.604.008-.145.03-1.52.03-1.67.002-.512.167-3.63-.024-5.545zm-3.748 9.195h-2.561V8.29c0-1.309-.55-1.976-1.67-1.976-1.23 0-1.846.79-1.846 2.35v3.403h-2.546V8.663c0-1.56-.617-2.35-1.848-2.35-1.112 0-1.668.668-1.67 1.977v6.218H4.822V8.102c0-1.31.337-2.35 1.011-3.12.696-.77 1.608-1.164 2.74-1.164 1.311 0 2.302.5 2.962 1.498l.638 1.06.638-1.06c.66-.999 1.65-1.498 2.96-1.498 1.13 0 2.043.395 2.74 1.164.675.77 1.012 1.81 1.012 3.12z" />
    </svg>
    """
  end

  def twitter_icon(assigns) do
    ~H"""
    <svg viewBox="0 0 24 24" aria-hidden="true" class={@class} fill="currentColor">
      <path d="M14.234 10.162 22.977 0h-2.072l-7.591 8.824L7.251 0H.258l9.168 13.343L.258 24H2.33l8.016-9.318L16.749 24h6.993zm-2.837 3.299-.929-1.329L3.076 1.56h3.182l5.965 8.532.929 1.329 7.754 11.09h-3.182z" />
    </svg>
    """
  end

  def facebook_icon(assigns) do
    ~H"""
    <svg viewBox="0 0 24 24" aria-hidden="true" class={@class} fill="currentColor">
      <path d="M9.101 23.691v-7.98H6.627v-3.667h2.474v-1.58c0-4.085 1.848-5.978 5.858-5.978.401 0 .955.042 1.468.103a8.68 8.68 0 0 1 1.141.195v3.325a8.623 8.623 0 0 0-.653-.036 26.805 26.805 0 0 0-.733-.009c-.707 0-1.259.096-1.675.309a1.686 1.686 0 0 0-.679.622c-.258.42-.374.995-.374 1.752v1.297h3.919l-.386 2.103-.287 1.564h-3.246v8.245C19.396 23.238 24 18.179 24 12.044c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.628 3.874 10.35 9.101 11.647Z" />
    </svg>
    """
  end

  def linkedin_icon(assigns) do
    ~H"""
    <svg viewBox="0 0 24 24" aria-hidden="true" class={@class} fill="currentColor">
      <path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z" />
    </svg>
    """
  end

  def instagram_icon(assigns) do
    ~H"""
    <svg viewBox="0 0 24 24" aria-hidden="true" class={@class} fill="currentColor">
      <path d="M7.0301.084c-1.2768.0602-2.1487.264-2.911.5634-.7888.3075-1.4575.72-2.1228 1.3877-.6652.6677-1.075 1.3368-1.3802 2.127-.2954.7638-.4956 1.6365-.552 2.914-.0564 1.2775-.0689 1.6882-.0626 4.947.0062 3.2586.0206 3.6671.0825 4.9473.061 1.2765.264 2.1482.5635 2.9107.308.7889.72 1.4573 1.388 2.1228.6679.6655 1.3365 1.0743 2.1285 1.38.7632.295 1.6361.4961 2.9134.552 1.2773.056 1.6884.069 4.9462.0627 3.2578-.0062 3.668-.0207 4.9478-.0814 1.28-.0607 2.147-.2652 2.9098-.5633.7889-.3086 1.4578-.72 2.1228-1.3881.665-.6682 1.0745-1.3378 1.3795-2.1284.2957-.7632.4966-1.636.552-2.9124.056-1.2809.0692-1.6898.063-4.948-.0063-3.2583-.021-3.6668-.0817-4.9465-.0607-1.2797-.264-2.1487-.5633-2.9117-.3084-.7889-.72-1.4568-1.3876-2.1228C21.2982 1.33 20.628.9208 19.8378.6165 19.074.321 18.2017.1197 16.9244.0645 15.6471.0093 15.236-.005 11.977.0014 8.718.0076 8.31.0215 7.0301.0839m.1402 21.6932c-1.17-.0509-1.8053-.2453-2.2287-.408-.5606-.216-.96-.4771-1.3819-.895-.422-.4178-.6811-.8186-.9-1.378-.1644-.4234-.3624-1.058-.4171-2.228-.0595-1.2645-.072-1.6442-.079-4.848-.007-3.2037.0053-3.583.0607-4.848.05-1.169.2456-1.805.408-2.2282.216-.5613.4762-.96.895-1.3816.4188-.4217.8184-.6814 1.3783-.9003.423-.1651 1.0575-.3614 2.227-.4171 1.2655-.06 1.6447-.072 4.848-.079 3.2033-.007 3.5835.005 4.8495.0608 1.169.0508 1.8053.2445 2.228.408.5608.216.96.4754 1.3816.895.4217.4194.6816.8176.9005 1.3787.1653.4217.3617 1.056.4169 2.2263.0602 1.2655.0739 1.645.0796 4.848.0058 3.203-.0055 3.5834-.061 4.848-.051 1.17-.245 1.8055-.408 2.2294-.216.5604-.4763.96-.8954 1.3814-.419.4215-.8181.6811-1.3783.9-.4224.1649-1.0577.3617-2.2262.4174-1.2656.0595-1.6448.072-4.8493.079-3.2045.007-3.5825-.006-4.848-.0608M16.953 5.5864A1.44 1.44 0 1 0 18.39 4.144a1.44 1.44 0 0 0-1.437 1.4424M5.8385 12.012c.0067 3.4032 2.7706 6.1557 6.173 6.1493 3.4026-.0065 6.157-2.7701 6.1506-6.1733-.0065-3.4032-2.771-6.1565-6.174-6.1498-3.403.0067-6.156 2.771-6.1496 6.1738M8 12.0077a4 4 0 1 1 4.008 3.9921A3.9996 3.9996 0 0 1 8 12.0077" />
    </svg>
    """
  end

  def email_icon(assigns) do
    ~H"""
    <svg
      viewBox="0 0 24 24"
      aria-hidden="true"
      class={@class}
      fill="none"
      stroke="currentColor"
      stroke-width="2"
    >
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        d="M21.75 6.75v10.5a2.25 2.25 0 0 1-2.25 2.25h-15a2.25 2.25 0 0 1-2.25-2.25V6.75m19.5 0A2.25 2.25 0 0 0 19.5 4.5h-15a2.25 2.25 0 0 0-2.25 2.25m19.5 0v.243a2.25 2.25 0 0 1-1.07 1.916l-7.5 4.615a2.25 2.25 0 0 1-2.36 0L3.32 8.91a2.25 2.25 0 0 1-1.07-1.916V6.75"
      />
    </svg>
    """
  end

  def share_icon(assigns) do
    ~H"""
    <svg
      viewBox="0 0 24 24"
      aria-hidden="true"
      class={@class}
      fill="none"
      stroke="currentColor"
      stroke-width="2"
    >
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        d="M7.217 10.907a2.25 2.25 0 1 0 0 2.186m0-2.186c.18.324.283.696.283 1.093s-.103.77-.283 1.093m0-2.186 9.566-5.314m-9.566 7.5 9.566 5.314m0 0a2.25 2.25 0 1 0 3.935 2.186 2.25 2.25 0 0 0-3.935-2.186zm0-12.814a2.25 2.25 0 1 0 3.933-2.185 2.25 2.25 0 0 0-3.933 2.185z"
      />
    </svg>
    """
  end
end
