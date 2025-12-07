defmodule HomesiteWeb.LayoutsTest do
  use HomesiteWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias HomesiteWeb.Layouts

  describe "app/1 layout" do
    test "renders inner block content" do
      html =
        render_component(&Layouts.app/1, %{
          flash: %{},
          current_scope: nil,
          inner_block: [%{__slot__: :inner_block, inner_block: fn _, _ -> "Test Content" end}]
        })

      assert html =~ "Test Content"
    end

    test "renders footer with branding" do
      html =
        render_component(&Layouts.app/1, %{
          flash: %{},
          current_scope: nil,
          inner_block: [%{__slot__: :inner_block, inner_block: fn _, _ -> "" end}]
        })

      assert html =~ "Portal of JH"
      assert html =~ "Phoenix Framework"
      assert html =~ "Elixir"
      assert html =~ "Tailwind CSS"
    end

    test "renders RSS and JSON feed links in footer" do
      html =
        render_component(&Layouts.app/1, %{
          flash: %{},
          current_scope: nil,
          inner_block: [%{__slot__: :inner_block, inner_block: fn _, _ -> "" end}]
        })

      assert html =~ "/rss.xml"
      assert html =~ "/feed.json"
    end

    test "renders navigation links when user is logged in" do
      user = %Homesite.Accounts.User{
        id: 1,
        email: "test@example.com",
        display_name: "Test User",
        role: "user"
      }

      scope = %Homesite.Accounts.Scope{user: user}

      html =
        render_component(&Layouts.app/1, %{
          flash: %{},
          current_scope: scope,
          inner_block: [%{__slot__: :inner_block, inner_block: fn _, _ -> "" end}]
        })

      assert html =~ "/dashboard"
      assert html =~ "/posts"
      assert html =~ "/tags"
    end

    test "hides logged-in navigation when no scope" do
      html =
        render_component(&Layouts.app/1, %{
          flash: %{},
          current_scope: nil,
          inner_block: [%{__slot__: :inner_block, inner_block: fn _, _ -> "" end}]
        })

      refute html =~ "href=\"/dashboard\""
    end

    test "renders copyright with current year" do
      html =
        render_component(&Layouts.app/1, %{
          flash: %{},
          current_scope: nil,
          inner_block: [%{__slot__: :inner_block, inner_block: fn _, _ -> "" end}]
        })

      current_year = Date.utc_today().year |> to_string()
      assert html =~ current_year
    end
  end

  describe "flash_group/1" do
    test "renders with required id" do
      html = render_component(&Layouts.flash_group/1, %{flash: %{}})
      assert html =~ "id=\"flash-group\""
    end

    test "accepts custom id" do
      html = render_component(&Layouts.flash_group/1, %{flash: %{}, id: "custom-flash"})
      assert html =~ "id=\"custom-flash\""
    end

    test "has aria-live attribute for accessibility" do
      html = render_component(&Layouts.flash_group/1, %{flash: %{}})
      assert html =~ "aria-live=\"polite\""
    end

    test "includes client error flash" do
      html = render_component(&Layouts.flash_group/1, %{flash: %{}})
      assert html =~ "id=\"client-error\""
    end

    test "includes server error flash" do
      html = render_component(&Layouts.flash_group/1, %{flash: %{}})
      assert html =~ "id=\"server-error\""
    end
  end

  describe "navbar/1" do
    test "renders site branding" do
      html = render_component(&Layouts.navbar/1, %{current_scope: nil})
      assert html =~ "Portal of JH"
    end

    test "renders search link" do
      html = render_component(&Layouts.navbar/1, %{current_scope: nil})
      assert html =~ "/search"
    end

    test "renders login link when not authenticated" do
      html = render_component(&Layouts.navbar/1, %{current_scope: nil})
      assert html =~ "/users/log-in"
    end

    test "renders FAQs link" do
      html = render_component(&Layouts.navbar/1, %{current_scope: nil})
      assert html =~ "/faqs"
    end

    test "renders authenticated user navigation when logged in" do
      user = %Homesite.Accounts.User{
        id: 1,
        email: "test@example.com",
        display_name: "Test User",
        role: "user"
      }

      scope = %Homesite.Accounts.Scope{user: user}
      html = render_component(&Layouts.navbar/1, %{current_scope: scope})

      assert html =~ "/dashboard"
      assert html =~ "/posts"
      assert html =~ "/tags"
      assert html =~ "/users/settings"
      assert html =~ "Log out"
    end

    test "renders admin link for admin users" do
      user = %Homesite.Accounts.User{
        id: 1,
        email: "admin@example.com",
        display_name: "Admin User",
        role: "admin"
      }

      # Scope.admin? checks admin_override? field
      scope = %Homesite.Accounts.Scope{user: user, admin_override?: true}
      html = render_component(&Layouts.navbar/1, %{current_scope: scope})

      assert html =~ "/admin"
    end

    test "hides admin link for regular users" do
      user = %Homesite.Accounts.User{
        id: 1,
        email: "test@example.com",
        display_name: "Test User",
        role: "user"
      }

      scope = %Homesite.Accounts.Scope{user: user}
      html = render_component(&Layouts.navbar/1, %{current_scope: scope})

      refute html =~ "href=\"/admin\""
    end

    test "renders mobile menu button" do
      html = render_component(&Layouts.navbar/1, %{current_scope: nil})
      assert html =~ "mobile_menu"
      assert html =~ "hero-bars-3"
    end

    test "has proper accessibility attributes" do
      html = render_component(&Layouts.navbar/1, %{current_scope: nil})
      assert html =~ "role=\"banner\""
      assert html =~ "role=\"navigation\""
    end
  end

  describe "language_toggle/1" do
    test "renders English and Finnish options" do
      html = render_component(&Layouts.language_toggle/1, %{})
      assert html =~ "EN"
      assert html =~ "FI"
    end

    test "has locale data attributes" do
      html = render_component(&Layouts.language_toggle/1, %{})
      assert html =~ "data-phx-locale=\"en\""
      assert html =~ "data-phx-locale=\"fi\""
    end

    test "dispatches phx:set-locale event" do
      html = render_component(&Layouts.language_toggle/1, %{})
      assert html =~ "phx:set-locale"
    end
  end

  describe "theme_toggle/1" do
    test "renders theme dropdown" do
      html = render_component(&Layouts.theme_toggle/1, %{})
      assert html =~ "dropdown"
    end

    test "has light theme option" do
      html = render_component(&Layouts.theme_toggle/1, %{})
      assert html =~ "Light"
    end

    test "has dark theme option" do
      html = render_component(&Layouts.theme_toggle/1, %{})
      assert html =~ "Dark"
    end

    test "has brownie theme option" do
      html = render_component(&Layouts.theme_toggle/1, %{})
      assert html =~ "Brownie"
    end

    test "dispatches phx:set-theme event" do
      html = render_component(&Layouts.theme_toggle/1, %{})
      assert html =~ "phx:set-theme"
    end

    test "has accessibility label" do
      html = render_component(&Layouts.theme_toggle/1, %{})
      assert html =~ "aria-label"
    end
  end
end
