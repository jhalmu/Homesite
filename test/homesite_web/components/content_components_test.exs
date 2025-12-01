defmodule HomesiteWeb.ContentComponentsTest do
  use HomesiteWeb.ConnCase, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest
  import HomesiteWeb.ContentComponents
  alias Homesite.Accounts

  describe "post_card/1" do
    setup do
      # Create test user struct (not inserted to DB - component test only)
      admin = %Homesite.Accounts.User{
        id: 1,
        email: "test-admin@example.com",
        display_name: "Test Admin",
        confirmed_at: ~U[2024-01-01 00:00:00Z]
      }

      scope = %Accounts.Scope{user: admin}

      # Create test tag structs
      tag1 = %Homesite.Content.Tag{
        id: 1,
        name: "Elixir",
        slug: "elixir",
        is_public: true,
        user_id: admin.id
      }

      tag2 = %Homesite.Content.Tag{
        id: 2,
        name: "Phoenix",
        slug: "phoenix",
        is_public: true,
        user_id: admin.id
      }

      published_post = %Homesite.Content.Post{
        id: 1,
        title: "Test Post",
        body: "This is a test post with some content to preview.",
        slug: "test-post",
        published_at: ~U[2024-01-15 14:30:00Z],
        read_time_minutes: 5,
        is_public: true,
        user_id: admin.id,
        user: admin,
        tags: [tag1, tag2]
      }

      draft_post = %Homesite.Content.Post{
        id: 2,
        title: "Draft Post",
        body: "Draft content",
        slug: "draft-post",
        published_at: nil,
        read_time_minutes: 3,
        is_public: false,
        user_id: admin.id,
        user: admin,
        tags: []
      }

      {:ok, scope: scope, published_post: published_post, draft_post: draft_post, admin: admin}
    end

    test "renders published post with all metadata", %{published_post: post, scope: scope} do
      assigns = %{
        post: post,
        current_scope: scope,
        show_actions: true,
        show_preview: true,
        preview_length: 150,
        id: "post-1",
        class: nil
      }

      html = rendered_to_string(~H"<.post_card {assigns} />")

      assert html =~ "Test Post"
      assert html =~ "This is a test post"
      assert html =~ "Published"
      assert html =~ "January 15, 2024"
      assert html =~ "5 min read"
      assert html =~ "Public"
      assert html =~ "Elixir"
      assert html =~ "Phoenix"
      assert html =~ "Share this post"
    end

    test "renders draft post with draft badge", %{draft_post: post, scope: scope} do
      assigns = %{
        post: post,
        current_scope: scope,
        show_actions: true,
        show_preview: true,
        preview_length: 150,
        id: "post-2",
        class: nil
      }

      html = rendered_to_string(~H"<.post_card {assigns} />")

      assert html =~ "Draft Post"
      assert html =~ "Draft"
      refute html =~ "Published"
      refute html =~ "Share this post"
    end

    test "renders private post without share link", %{published_post: post, scope: scope} do
      private_post = %Homesite.Content.Post{post | is_public: false}

      assigns = %{
        post: private_post,
        current_scope: scope,
        show_actions: true,
        show_preview: true,
        preview_length: 150,
        id: "post-1",
        class: nil
      }

      html = rendered_to_string(~H"<.post_card {assigns} />")

      assert html =~ "Private"
      refute html =~ "Share this post"
    end

    test "hides preview when show_preview is false", %{published_post: post, scope: scope} do
      assigns = %{
        post: post,
        current_scope: scope,
        show_actions: true,
        show_preview: false,
        preview_length: 150,
        id: "post-1",
        class: nil
      }

      html = rendered_to_string(~H"<.post_card {assigns} />")

      assert html =~ "Test Post"
      refute html =~ "This is a test post"
    end

    test "truncates long preview with ellipsis", %{published_post: post, scope: scope} do
      long_post = %Homesite.Content.Post{post | body: String.duplicate("a", 200)}

      assigns = %{
        post: long_post,
        current_scope: scope,
        show_actions: true,
        show_preview: true,
        preview_length: 50,
        id: "post-1",
        class: nil
      }

      html = rendered_to_string(~H"<.post_card {assigns} />")

      assert html =~ "..."
    end

    test "renders post without tags", %{draft_post: post, scope: scope} do
      assigns = %{
        post: post,
        current_scope: scope,
        show_actions: true,
        show_preview: true,
        preview_length: 150,
        id: "post-2",
        class: nil
      }

      html = rendered_to_string(~H"<.post_card {assigns} />")

      assert html =~ "Draft Post"
      refute html =~ "badge-primary"
    end

    test "shows action buttons for post owner", %{published_post: post, scope: scope} do
      assigns = %{
        post: post,
        current_scope: scope,
        show_actions: true,
        show_preview: true,
        preview_length: 150,
        id: "post-1",
        class: nil
      }

      html = rendered_to_string(~H"<.post_card {assigns} />")

      assert html =~ ~s(aria-label="View post")
      assert html =~ ~s(aria-label="Edit post")
      assert html =~ ~s(aria-label="Delete post")
      assert html =~ "hero-eye"
      assert html =~ "hero-pencil-square"
      assert html =~ "hero-trash"
    end

    test "hides action buttons when show_actions is false", %{published_post: post, scope: scope} do
      assigns = %{
        post: post,
        current_scope: scope,
        show_actions: false,
        show_preview: true,
        preview_length: 150,
        id: "post-1",
        class: nil
      }

      html = rendered_to_string(~H"<.post_card {assigns} />")

      refute html =~ ~s(aria-label="Edit post")
      refute html =~ "hero-trash"
    end

    test "hides action buttons for non-owner", %{published_post: post} do
      other_user = %{id: 999, email: "other@example.com", display_name: "Other User"}
      other_scope = %Accounts.Scope{user: other_user}

      assigns = %{
        post: post,
        current_scope: other_scope,
        show_actions: true,
        show_preview: true,
        preview_length: 150,
        id: "post-1",
        class: nil
      }

      html = rendered_to_string(~H"<.post_card {assigns} />")

      refute html =~ ~s(aria-label="Edit post")
      refute html =~ "hero-trash"
    end

    test "hides action buttons when current_scope is nil", %{published_post: post} do
      assigns = %{
        post: post,
        current_scope: nil,
        show_actions: true,
        show_preview: true,
        preview_length: 150,
        id: "post-1",
        class: nil
      }

      html = rendered_to_string(~H"<.post_card {assigns} />")

      refute html =~ ~s(aria-label="Edit post")
      refute html =~ "hero-trash"
    end

    test "escapes HTML in post title to prevent XSS", %{published_post: post, scope: scope} do
      xss_post = %Homesite.Content.Post{post | title: "<script>alert('xss')</script>"}

      assigns = %{
        post: xss_post,
        current_scope: scope,
        show_actions: true,
        show_preview: true,
        preview_length: 150,
        id: "post-1",
        class: nil
      }

      html = rendered_to_string(~H"<.post_card {assigns} />")

      refute html =~ "<script>"
      assert html =~ "&lt;script&gt;"
    end

    test "escapes HTML in post body preview to prevent XSS", %{published_post: post, scope: scope} do
      xss_post = %Homesite.Content.Post{post | body: "<img src=x onerror=alert('xss')>"}

      assigns = %{
        post: xss_post,
        current_scope: scope,
        show_actions: true,
        show_preview: true,
        preview_length: 150,
        id: "post-1",
        class: nil
      }

      html = rendered_to_string(~H"<.post_card {assigns} />")

      refute html =~ "onerror="
    end

    test "handles special characters in post title", %{published_post: post, scope: scope} do
      special_post = %Homesite.Content.Post{post | title: "C++ & Elixir: A Comparison"}

      assigns = %{
        post: special_post,
        current_scope: scope,
        show_actions: true,
        show_preview: true,
        preview_length: 150,
        id: "post-1",
        class: nil
      }

      html = rendered_to_string(~H"<.post_card {assigns} />")

      assert html =~ "C++ &amp; Elixir"
    end

    test "renders custom CSS class", %{published_post: post, scope: scope} do
      assigns = %{
        post: post,
        current_scope: scope,
        show_actions: true,
        show_preview: true,
        preview_length: 150,
        id: "post-1",
        class: "custom-class"
      }

      html = rendered_to_string(~H"<.post_card {assigns} />")

      assert html =~ "custom-class"
    end

    test "includes accessibility attributes", %{published_post: post, scope: scope} do
      assigns = %{
        post: post,
        current_scope: scope,
        show_actions: true,
        show_preview: true,
        preview_length: 150,
        id: "post-1",
        class: nil
      }

      html = rendered_to_string(~H"<.post_card {assigns} />")

      assert html =~ ~s(id="post-1")
      assert html =~ ~s(<article)
      assert html =~ ~s(<time datetime=)
    end
  end

  describe "tag_card/1" do
    setup do
      # Create test user struct (not inserted to DB - component test only)
      admin = %Homesite.Accounts.User{
        id: 2,
        email: "test-admin-tag@example.com",
        display_name: "Test Admin",
        confirmed_at: ~U[2024-01-01 00:00:00Z]
      }

      scope = %Accounts.Scope{user: admin}

      tag = %Homesite.Content.Tag{
        id: 1,
        name: "Elixir",
        slug: "elixir",
        is_public: true,
        user_id: admin.id
      }

      {:ok, scope: scope, tag: tag, admin: admin}
    end

    test "renders tag with post count", %{tag: tag, scope: scope} do
      assigns = %{
        tag: tag,
        post_count: 5,
        current_scope: scope,
        show_actions: true,
        id: "tag-1",
        class: nil
      }

      html = rendered_to_string(~H"<.tag_card {assigns} />")

      assert html =~ "Elixir"
      assert html =~ "5 posts"
      assert html =~ "Public"
    end

    test "renders singular 'post' for count of 1", %{tag: tag, scope: scope} do
      assigns = %{
        tag: tag,
        post_count: 1,
        current_scope: scope,
        show_actions: true,
        id: "tag-1",
        class: nil
      }

      html = rendered_to_string(~H"<.tag_card {assigns} />")

      assert html =~ "1 post"
      refute html =~ "1 posts"
    end

    test "renders private tag badge", %{tag: tag, scope: scope} do
      private_tag = %Homesite.Content.Tag{tag | is_public: false}

      assigns = %{
        tag: private_tag,
        post_count: 3,
        current_scope: scope,
        show_actions: true,
        id: "tag-1",
        class: nil
      }

      html = rendered_to_string(~H"<.tag_card {assigns} />")

      assert html =~ "Private"
      refute html =~ "Public"
    end

    test "shows action buttons for tag owner", %{tag: tag, scope: scope} do
      assigns = %{
        tag: tag,
        post_count: 5,
        current_scope: scope,
        show_actions: true,
        id: "tag-1",
        class: nil
      }

      html = rendered_to_string(~H"<.tag_card {assigns} />")

      assert html =~ ~s(aria-label="Edit tag")
      assert html =~ ~s(aria-label="Delete tag")
      assert html =~ "hero-pencil-square"
      assert html =~ "hero-trash"
    end

    test "hides action buttons when show_actions is false", %{tag: tag, scope: scope} do
      assigns = %{
        tag: tag,
        post_count: 5,
        current_scope: scope,
        show_actions: false,
        id: "tag-1",
        class: nil
      }

      html = rendered_to_string(~H"<.tag_card {assigns} />")

      refute html =~ ~s(aria-label="Edit tag")
      refute html =~ "hero-trash"
    end

    test "hides action buttons for non-owner", %{tag: tag} do
      other_user = %{id: 999, email: "other@example.com"}
      other_scope = %Accounts.Scope{user: other_user}

      assigns = %{
        tag: tag,
        post_count: 5,
        current_scope: other_scope,
        show_actions: true,
        id: "tag-1",
        class: nil
      }

      html = rendered_to_string(~H"<.tag_card {assigns} />")

      refute html =~ ~s(aria-label="Edit tag")
      refute html =~ "hero-trash"
    end

    test "hides action buttons when current_scope is nil", %{tag: tag} do
      assigns = %{
        tag: tag,
        post_count: 5,
        current_scope: nil,
        show_actions: true,
        id: "tag-1",
        class: nil
      }

      html = rendered_to_string(~H"<.tag_card {assigns} />")

      refute html =~ ~s(aria-label="Edit tag")
      refute html =~ "hero-trash"
    end

    test "handles zero post count", %{tag: tag, scope: scope} do
      assigns = %{
        tag: tag,
        post_count: 0,
        current_scope: scope,
        show_actions: true,
        id: "tag-1",
        class: nil
      }

      html = rendered_to_string(~H"<.tag_card {assigns} />")

      assert html =~ "0 posts"
    end

    test "escapes HTML in tag name to prevent XSS", %{tag: tag, scope: scope} do
      xss_tag = %Homesite.Content.Tag{tag | name: "<script>alert('xss')</script>"}

      assigns = %{
        tag: xss_tag,
        post_count: 5,
        current_scope: scope,
        show_actions: true,
        id: "tag-1",
        class: nil
      }

      html = rendered_to_string(~H"<.tag_card {assigns} />")

      refute html =~ "<script>"
      assert html =~ "&lt;script&gt;"
    end

    test "handles special characters in tag name", %{tag: tag, scope: scope} do
      special_tag = %Homesite.Content.Tag{tag | name: "C++ & ASP.NET"}

      assigns = %{
        tag: special_tag,
        post_count: 5,
        current_scope: scope,
        show_actions: true,
        id: "tag-1",
        class: nil
      }

      html = rendered_to_string(~H"<.tag_card {assigns} />")

      assert html =~ "C++ &amp; ASP.NET"
    end

    test "renders custom CSS class", %{tag: tag, scope: scope} do
      assigns = %{
        tag: tag,
        post_count: 5,
        current_scope: scope,
        show_actions: true,
        id: "tag-1",
        class: "custom-tag-class"
      }

      html = rendered_to_string(~H"<.tag_card {assigns} />")

      assert html =~ "custom-tag-class"
    end

    test "includes accessibility attributes", %{tag: tag, scope: scope} do
      assigns = %{
        tag: tag,
        post_count: 5,
        current_scope: scope,
        show_actions: true,
        id: "tag-1",
        class: nil
      }

      html = rendered_to_string(~H"<.tag_card {assigns} />")

      assert html =~ ~s(id="tag-1")
      assert html =~ ~s(<article)
    end
  end

  describe "divider/1" do
    test "renders divider without text" do
      assigns = %{text: nil, class: nil}

      html = rendered_to_string(~H"<.divider {assigns} />")

      assert html =~ "divider"
      assert html =~ ~r/class="divider\s*"/
    end

    test "renders divider with text" do
      assigns = %{text: "or", class: nil}

      html = rendered_to_string(~H"<.divider {assigns} />")

      assert html =~ "divider"
      assert html =~ "or"
    end

    test "renders divider with custom class" do
      assigns = %{text: nil, class: "my-8"}

      html = rendered_to_string(~H"<.divider {assigns} />")

      assert html =~ "my-8"
    end

    test "renders divider with text and custom class" do
      assigns = %{text: "Section Break", class: "my-8"}

      html = rendered_to_string(~H"<.divider {assigns} />")

      assert html =~ "Section Break"
      assert html =~ "my-8"
    end

    test "escapes HTML in divider text to prevent XSS" do
      assigns = %{text: "<script>alert('xss')</script>", class: nil}

      html = rendered_to_string(~H"<.divider {assigns} />")

      refute html =~ "<script>"
      assert html =~ "&lt;script&gt;"
    end

    test "handles special characters in divider text" do
      assigns = %{text: "A & B", class: nil}

      html = rendered_to_string(~H"<.divider {assigns} />")

      assert html =~ "A &amp; B"
    end
  end
end
