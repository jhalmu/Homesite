defmodule HomesiteWeb.SocialComponents do
  @moduledoc """
  Social sharing components for posts and other content.
  """
  use Phoenix.Component
  import HomesiteWeb.CoreComponents

  @doc """
  Renders social share buttons for a given URL and title.

  ## Examples

      <.social_share_buttons url={@current_url} title={@post.title} />
  """
  attr :url, :string, required: true
  attr :title, :string, required: true
  attr :class, :string, default: ""

  def social_share_buttons(assigns) do
    ~H"""
    <div class={"#{@class} flex flex-wrap gap-2"}>
      <.share_button platform="bluesky" url={@url} title={@title} />
      <.share_button platform="mastodon" url={@url} title={@title} />
      <.share_button platform="twitter" url={@url} title={@title} />
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
    icon_name = platform_icon(assigns.platform)
    label = platform_label(assigns.platform)

    assigns =
      assigns
      |> assign(:share_url, share_url)
      |> assign(:icon_name, icon_name)
      |> assign(:label, label)

    ~H"""
    <a
      href={@share_url}
      target="_blank"
      rel="noopener noreferrer"
      class="btn btn-sm btn-outline gap-2"
      title={"Share on #{@label}"}
    >
      <.icon name={@icon_name} class="h-4 w-4" />
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

  # Map platforms to heroicons
  defp platform_icon("bluesky"), do: "hero-cloud"
  defp platform_icon("mastodon"), do: "hero-chat-bubble-left-right"
  defp platform_icon("twitter"), do: "hero-chat-bubble-oval-left"
  defp platform_icon("facebook"), do: "hero-user-group"
  defp platform_icon("linkedin"), do: "hero-briefcase"
  defp platform_icon("email"), do: "hero-envelope"

  # Platform labels
  defp platform_label("bluesky"), do: "Bluesky"
  defp platform_label("mastodon"), do: "Mastodon"
  defp platform_label("twitter"), do: "X"
  defp platform_label("facebook"), do: "Facebook"
  defp platform_label("linkedin"), do: "LinkedIn"
  defp platform_label("email"), do: "Email"
end
