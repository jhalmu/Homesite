defmodule HomesiteWeb.E2E.AccessibilityTest do
  @moduledoc """
  Accessibility audit tests using axe-core via a11y_audit.

  These tests verify WCAG compliance including color contrast, keyboard navigation,
  ARIA labels, and other accessibility requirements.

  ## Running These Tests

  1. Ensure Playwright is installed:
     ```bash
     npm --prefix assets i -D playwright
     npm --prefix assets exec -- playwright install chromium --with-deps
     ```

  2. Run tests:
     ```bash
     mix test --include playwright test/homesite_web/e2e/accessibility_test.exs
     ```

  3. Debug mode (show browser):
     ```bash
     PW_HEADLESS=false mix test --include playwright test/homesite_web/e2e/accessibility_test.exs
     ```
  """
  # Note: Only use Playwright.Case, NOT ConnCase - they conflict on sandbox setup
  use PhoenixTest.Playwright.Case, async: false
  use HomesiteWeb, :verified_routes

  import HomesiteWeb.PlaywrightAuthHelper
  import HomesiteWeb.PlaywrightJsHelper
  import Homesite.AccountsFixtures

  setup do
    # Playwright.Case handles sandbox, but we need test invitation for fixtures
    Homesite.DataCase.ensure_test_invitation()
    :ok
  end

  # Helper to run axe-core accessibility audit
  defp audit_page(session) do
    # Force light theme for accessibility testing (WCAG AA compliance testing)
    session = run_js(session, "document.documentElement.setAttribute('data-theme', 'light')")

    # Inject axe-core library
    session = run_js(session, A11yAudit.JS.axe_core())

    # Run the audit and get results
    {session, axe_result} = execute_js(session, A11yAudit.JS.await_audit_results())

    results = A11yAudit.Results.from_json(axe_result)
    {session, results}
  end

  defp assert_no_violations(session) do
    {session, results} = audit_page(session)
    A11yAudit.Assertions.assert_no_violations(results)
    session
  end

  defp audit_page_dark_theme(session) do
    # Force dark theme for accessibility testing
    session = run_js(session, "document.documentElement.setAttribute('data-theme', 'dark')")

    # Wait for CSS to recalculate after theme change
    # Use requestAnimationFrame to ensure styles are applied
    session =
      run_js(session, """
        await new Promise(resolve => {
          requestAnimationFrame(() => {
            requestAnimationFrame(resolve);
          });
        });
      """)

    # Inject axe-core library
    session = run_js(session, A11yAudit.JS.axe_core())

    # Run the audit and get results
    {session, axe_result} = execute_js(session, A11yAudit.JS.await_audit_results())

    results = A11yAudit.Results.from_json(axe_result)
    {session, results}
  end

  defp assert_no_violations_dark(session) do
    {session, results} = audit_page_dark_theme(session)
    A11yAudit.Assertions.assert_no_violations(results)
    session
  end

  describe "Login Page Accessibility" do
    @tag :playwright
    test "login page has no accessibility violations", %{conn: conn} do
      conn
      |> visit(~p"/users/log-in")
      |> assert_has("body .phx-connected")
      |> assert_no_violations()
    end

    @tag :playwright
    test "login page has proper contrast ratios", %{conn: conn} do
      conn
      |> visit(~p"/users/log-in")
      |> assert_has("body .phx-connected")
      |> then(fn session ->
        {session, results} = audit_page(session)

        # Check specifically for color-contrast violations
        contrast_violations =
          Enum.filter(results.violations, fn v ->
            v.id == "color-contrast"
          end)

        if length(contrast_violations) > 0 do
          IO.puts("\n❌ Color Contrast Violations Found:")

          Enum.each(contrast_violations, fn violation ->
            IO.puts("\n  Issue: #{violation.description}")
            IO.puts("  Impact: #{violation.impact}")
            IO.puts("  Help: #{violation.help_url}")

            Enum.each(violation.nodes, fn node ->
              IO.puts("\n  Element: #{String.slice(node.html, 0..100)}...")
              IO.puts("  Failure: #{node.failure_summary}")
            end)
          end)
        end

        A11yAudit.Assertions.assert_no_violations(results)
        session
      end)
    end

    @tag :playwright
    test "login page has proper contrast ratios in DARK theme", %{conn: conn} do
      conn
      |> visit(~p"/users/log-in")
      |> assert_has("body .phx-connected")
      |> then(fn session ->
        {session, results} = audit_page_dark_theme(session)

        # Check specifically for color-contrast violations
        contrast_violations =
          Enum.filter(results.violations, fn v ->
            v.id == "color-contrast"
          end)

        if length(contrast_violations) > 0 do
          IO.puts("\n❌ Color Contrast Violations Found (DARK THEME):")

          Enum.each(contrast_violations, fn violation ->
            IO.puts("\n  Issue: #{violation.description}")
            IO.puts("  Impact: #{violation.impact}")
            IO.puts("  Help: #{violation.help_url}")

            Enum.each(violation.nodes, fn node ->
              IO.puts("\n  Element: #{String.slice(node.html, 0..100)}...")
              IO.puts("  Failure: #{node.failure_summary}")
            end)
          end)
        end

        A11yAudit.Assertions.assert_no_violations(results)
        session
      end)
    end
  end

  describe "User Settings Page Accessibility" do
    @tag :playwright
    test "settings page has no accessibility violations", %{conn: conn} do
      user = user_fixture()

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/users/settings")
      |> assert_has("body .phx-connected")
      |> assert_no_violations()
    end
  end

  describe "Dashboard Accessibility" do
    @tag :playwright
    test "dashboard has no accessibility violations", %{conn: conn} do
      user = user_fixture()

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/dashboard")
      |> assert_has("body .phx-connected")
      |> assert_no_violations()
    end
  end

  describe "Homepage Accessibility" do
    @tag :playwright
    test "homepage has no accessibility violations", %{conn: conn} do
      conn
      |> visit(~p"/")
      |> assert_has("body .phx-connected")
      |> assert_no_violations()
    end
  end

  describe "Posts Page Accessibility" do
    @tag :playwright
    test "posts list page has no accessibility violations", %{conn: conn} do
      user = user_fixture()

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/posts")
      |> assert_has("body .phx-connected")
      |> assert_no_violations()
    end

    @tag :playwright
    test "post show page has no accessibility violations", %{conn: conn} do
      user = user_fixture()

      {:ok, post} =
        Homesite.Content.create_post(
          %Homesite.Accounts.Scope{user: user},
          %{
            title: "Test Post for A11y",
            body: "This is a test post for accessibility testing.",
            is_public: true,
            published_at: DateTime.utc_now(:second)
          }
        )

      conn
      |> visit(~p"/posts/#{post}")
      |> assert_has("body .phx-connected")
      |> assert_no_violations()
    end
  end

  describe "Tags Page Accessibility" do
    @tag :playwright
    test "tags list page has no accessibility violations", %{conn: conn} do
      user = user_fixture()

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/tags")
      |> assert_has("body .phx-connected")
      |> assert_no_violations()
    end

    @tag :playwright
    test "tag show page has no accessibility violations", %{conn: conn} do
      user = user_fixture()

      {:ok, tag} =
        Homesite.Content.create_tag(
          %Homesite.Accounts.Scope{user: user},
          %{
            name: "Accessibility",
            description: "Posts about accessibility",
            is_public: true
          }
        )

      conn
      |> visit(~p"/tags/#{tag.slug}")
      |> assert_has("body .phx-connected")
      |> assert_no_violations()
    end
  end

  describe "FAQs Page Accessibility" do
    @tag :playwright
    test "public FAQs page has no accessibility violations", %{conn: conn} do
      conn
      |> visit(~p"/faqs")
      |> assert_has("body .phx-connected")
      |> assert_no_violations()
    end
  end

  describe "Search Page Accessibility" do
    @tag :playwright
    test "search page has no accessibility violations", %{conn: conn} do
      conn
      |> visit(~p"/search")
      |> assert_has("body .phx-connected")
      |> assert_no_violations()
    end
  end

  describe "Media Library Page Accessibility" do
    @tag :playwright
    test "media library page has no accessibility violations", %{conn: conn} do
      user = user_fixture()

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/media")
      |> assert_has("body .phx-connected")
      |> assert_no_violations()
    end

    @tag :playwright
    test "media library with items has no accessibility violations", %{conn: conn} do
      user = user_fixture()
      scope = %Homesite.Accounts.Scope{user: user}

      # Create a media item
      _media =
        Homesite.MediaFixtures.media_item_fixture(scope, %{
          title: "Test Image",
          alt_text: "A test image for accessibility"
        })

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/media")
      |> assert_has("body .phx-connected")
      |> assert_no_violations()
    end

    @tag :playwright
    test "media library orphan filter has accessible button", %{conn: conn} do
      user = user_fixture()
      scope = %Homesite.Accounts.Scope{user: user}

      # Create an orphan media item
      _orphan =
        Homesite.MediaFixtures.media_item_fixture(scope, %{
          title: "Orphan Image",
          alt_text: "An orphaned test image"
        })

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/media")
      |> assert_has("body .phx-connected")
      |> then(fn session ->
        # Click the orphan filter button (using attribute selector since button has badge inside)
        session = click(session, "button[phx-click='toggle-orphan-filter']")
        assert_no_violations(session)
      end)
    end
  end

  describe "Feed Page Accessibility" do
    @tag :playwright
    test "feed page has no accessibility violations when empty", %{conn: conn} do
      user = user_fixture()

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/feed")
      |> assert_has("body .phx-connected")
      |> assert_no_violations()
    end

    @tag :playwright
    test "feed page with items has no accessibility violations", %{conn: conn} do
      user = user_fixture()
      scope = Homesite.Accounts.Scope.for_user(user)

      # Create a feed source and item
      {:ok, feed_source} =
        Homesite.ExternalFeeds.create_feed_source(scope, %{
          feed_type: "rss",
          name: "Test Blog",
          url: "https://example.com/feed.xml",
          enabled: true
        })

      {:ok, _item} =
        Homesite.ExternalFeeds.upsert_feed_item(feed_source.id, %{
          external_id: "a11y-test",
          title: "Accessible Feed Item",
          content: "Test content for accessibility",
          url: "https://example.com/post",
          published_at: DateTime.utc_now()
        })

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/feed")
      |> assert_has("body .phx-connected")
      |> assert_no_violations()
    end

    @tag :playwright
    test "feed page has no violations in dark theme", %{conn: conn} do
      user = user_fixture()

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/feed")
      |> assert_has("body .phx-connected")
      |> assert_no_violations_dark()
    end
  end

  describe "Portfolio Page Accessibility" do
    @tag :playwright
    test "portfolio page has no accessibility violations", %{conn: conn} do
      conn
      |> visit(~p"/portfolio")
      |> assert_has("body .phx-connected")
      |> assert_no_violations()
    end
  end
end
