defmodule HomesiteWeb.SocialComponentsTest do
  use HomesiteWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias HomesiteWeb.SocialComponents

  describe "web_share_button/1" do
    test "renders with required attributes" do
      html =
        render_component(&SocialComponents.web_share_button/1, %{
          url: "https://example.com/post/1",
          title: "Test Post"
        })

      assert html =~ "phx-hook=\"WebShareApi\""
      assert html =~ "data-title=\"Test Post\""
      assert html =~ "data-url=\"https://example.com/post/1\""
      assert html =~ "Share this post"
    end

    test "generates unique id from url hash" do
      html =
        render_component(&SocialComponents.web_share_button/1, %{
          url: "https://example.com/post/1",
          title: "Test Post"
        })

      assert html =~ ~r/id="web-share-\d+"/
    end

    test "applies custom class when provided" do
      html =
        render_component(&SocialComponents.web_share_button/1, %{
          url: "https://example.com/post/1",
          title: "Test Post",
          class: "custom-class"
        })

      assert html =~ "custom-class"
    end
  end

  describe "social_share_buttons/1" do
    test "renders all platform share buttons" do
      html =
        render_component(&SocialComponents.social_share_buttons/1, %{
          url: "https://example.com/post/1",
          title: "Test Post"
        })

      assert html =~ "Bluesky"
      assert html =~ "Mastodon"
      assert html =~ "Facebook"
      assert html =~ "LinkedIn"
      assert html =~ "Email"
      # Twitter and Instagram are intentionally removed
      refute html =~ ">X</span>"
      refute html =~ "Instagram"
    end

    test "includes web share button" do
      html =
        render_component(&SocialComponents.social_share_buttons/1, %{
          url: "https://example.com/post/1",
          title: "Test Post"
        })

      assert html =~ "phx-hook=\"WebShareApi\""
      assert html =~ "Share this post"
    end

    test "applies custom class" do
      html =
        render_component(&SocialComponents.social_share_buttons/1, %{
          url: "https://example.com/post/1",
          title: "Test Post",
          class: "my-custom-class"
        })

      assert html =~ "my-custom-class"
    end
  end

  describe "platform_share_buttons/1" do
    test "renders all platform buttons without web share button" do
      html =
        render_component(&SocialComponents.platform_share_buttons/1, %{
          url: "https://example.com/post/1",
          title: "Test Post"
        })

      assert html =~ "Bluesky"
      assert html =~ "Mastodon"
      refute html =~ "phx-hook=\"WebShareApi\""
    end

    test "displays share label" do
      html =
        render_component(&SocialComponents.platform_share_buttons/1, %{
          url: "https://example.com/post/1",
          title: "Test Post"
        })

      assert html =~ "Share:"
    end
  end

  describe "share URL generation" do
    test "bluesky share button has correct URL" do
      html =
        render_component(&SocialComponents.platform_share_buttons/1, %{
          url: "https://example.com/post/1",
          title: "Test Post"
        })

      assert html =~ "href=\"https://bsky.app/intent/compose"
      assert html =~ "text="
    end

    test "mastodon share button uses mastodonshare.com" do
      html =
        render_component(&SocialComponents.platform_share_buttons/1, %{
          url: "https://example.com/post/1",
          title: "Test Post"
        })

      assert html =~ "href=\"https://mastodonshare.com/"
    end

    test "facebook share button has correct URL" do
      html =
        render_component(&SocialComponents.platform_share_buttons/1, %{
          url: "https://example.com/post/1",
          title: "Test Post"
        })

      assert html =~ "href=\"https://www.facebook.com/sharer/sharer.php"
    end

    test "linkedin share button has correct URL" do
      html =
        render_component(&SocialComponents.platform_share_buttons/1, %{
          url: "https://example.com/post/1",
          title: "Test Post"
        })

      assert html =~ "href=\"https://www.linkedin.com/sharing/share-offsite/"
    end

    test "email share button has mailto URL" do
      html =
        render_component(&SocialComponents.platform_share_buttons/1, %{
          url: "https://example.com/post/1",
          title: "Test Post"
        })

      assert html =~ "href=\"mailto:?"
    end
  end

  describe "share buttons accessibility" do
    test "all share links open in new tab" do
      html =
        render_component(&SocialComponents.platform_share_buttons/1, %{
          url: "https://example.com/post/1",
          title: "Test Post"
        })

      # Count target="_blank" attributes
      matches = Regex.scan(~r/target="_blank"/, html)

      # Should have at least 5 (one for each platform: Bluesky, Mastodon, Facebook, LinkedIn, Email)
      assert length(matches) >= 5
    end

    test "all share links have noopener noreferrer" do
      html =
        render_component(&SocialComponents.platform_share_buttons/1, %{
          url: "https://example.com/post/1",
          title: "Test Post"
        })

      matches = Regex.scan(~r/rel="noopener noreferrer"/, html)
      assert length(matches) >= 5
    end

    test "share links have title attributes" do
      html =
        render_component(&SocialComponents.platform_share_buttons/1, %{
          url: "https://example.com/post/1",
          title: "Test Post"
        })

      assert html =~ "title=\"Share on Bluesky\""
      assert html =~ "title=\"Share on Facebook\""
    end
  end

  describe "icon components" do
    test "bluesky_icon renders SVG" do
      html = render_component(&SocialComponents.bluesky_icon/1, %{class: "h-4 w-4"})
      assert html =~ "<svg"
      assert html =~ "class=\"h-4 w-4\""
    end

    test "mastodon_icon renders SVG" do
      html = render_component(&SocialComponents.mastodon_icon/1, %{class: "h-4 w-4"})
      assert html =~ "<svg"
    end

    test "twitter_icon renders SVG" do
      html = render_component(&SocialComponents.twitter_icon/1, %{class: "h-4 w-4"})
      assert html =~ "<svg"
    end

    test "facebook_icon renders SVG" do
      html = render_component(&SocialComponents.facebook_icon/1, %{class: "h-4 w-4"})
      assert html =~ "<svg"
    end

    test "linkedin_icon renders SVG" do
      html = render_component(&SocialComponents.linkedin_icon/1, %{class: "h-4 w-4"})
      assert html =~ "<svg"
    end

    test "instagram_icon renders SVG" do
      html = render_component(&SocialComponents.instagram_icon/1, %{class: "h-4 w-4"})
      assert html =~ "<svg"
    end

    test "email_icon renders SVG" do
      html = render_component(&SocialComponents.email_icon/1, %{class: "h-4 w-4"})
      assert html =~ "<svg"
    end

    test "share_icon renders SVG" do
      html = render_component(&SocialComponents.share_icon/1, %{class: "h-5 w-5"})
      assert html =~ "<svg"
      assert html =~ "class=\"h-5 w-5\""
    end
  end

  describe "URL encoding" do
    test "handles special characters in title" do
      html =
        render_component(&SocialComponents.platform_share_buttons/1, %{
          url: "https://example.com/post/1",
          title: "Test & Post with <special> chars"
        })

      # Should be URL encoded
      refute html =~ "Test & Post"
      assert html =~ "%26"
    end

    test "handles special characters in URL" do
      html =
        render_component(&SocialComponents.platform_share_buttons/1, %{
          url: "https://example.com/post/1?param=value&other=test",
          title: "Test Post"
        })

      # URL should be encoded
      assert html =~ "%3F"
    end
  end
end
