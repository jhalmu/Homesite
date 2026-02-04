defmodule HomesiteWeb.Router do
  use HomesiteWeb, :router

  import HomesiteWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {HomesiteWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug HomesiteWeb.Plugs.ContentSecurityPolicy
    plug :fetch_current_scope_for_user
    plug HomesiteWeb.Plugs.SetLocale
    plug HomesiteWeb.Plugs.SEOPlug
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Rate limiting pipelines using Hammer 7.x via RateLimitPlug
  pipeline :rate_limit_auth do
    plug HomesiteWeb.Plugs.RateLimitPlug, limiter: :auth
  end

  pipeline :rate_limit_registration do
    plug HomesiteWeb.Plugs.RateLimitPlug, limiter: :registration
  end

  pipeline :rate_limit_search do
    plug HomesiteWeb.Plugs.RateLimitPlug, limiter: :search
  end

  pipeline :rate_limit_feeds do
    plug HomesiteWeb.Plugs.RateLimitPlug, limiter: :feeds
  end

  scope "/", HomesiteWeb do
    pipe_through :browser

    # SEO routes
    get "/sitemap.xml", SitemapController, :index

    # Image serving for OpenGraph and social sharing
    get "/images/posts/:post_id/hero", ImageController, :post_hero
    get "/images/posts/:post_id/og-card.png", ImageController, :post_og_card
    get "/images/users/:user_id/avatar", ImageController, :user_avatar
    get "/images/users/:user_id/avatar.png", ImageController, :user_avatar_png
    get "/images/og-default.png", ImageController, :default_og_image

    live_session :public,
      on_mount: [
        {HomesiteWeb.UserAuth, :mount_current_scope},
        {HomesiteWeb.SetLocaleHook, :default},
        {HomesiteWeb.CaptureConnectionInfoHook, :default}
      ] do
      live "/", PageLive.Home, :index

      # Public FAQ viewing
      live "/faqs", FaqLive.Index, :index

      # Public happiness meter and testimonials
      live "/happiness", HappinessLive.Index, :index
      live "/testimonials/:token", TestimonialLive.Show, :show

      # Public portfolio showcase
      live "/portfolio", PortfolioLive.Index, :index
      live "/portfolio/:slug", PortfolioLive.Show, :show

      # Legal pages
      live "/privacy", PrivacyLive.Index, :index
    end
  end

  # Public search with rate limiting
  scope "/", HomesiteWeb do
    if Mix.env() != :test do
      pipe_through [:browser, :rate_limit_search]
    else
      pipe_through [:browser]
    end

    live_session :public_search,
      on_mount: [
        {HomesiteWeb.UserAuth, :mount_current_scope},
        {HomesiteWeb.SetLocaleHook, :default},
        {HomesiteWeb.CaptureConnectionInfoHook, :default}
      ] do
      live "/search", SearchLive.Index, :index
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", HomesiteWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:homesite, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: HomesiteWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview

      # DEV FAQs - development documentation
      live "/faqs", HomesiteWeb.DevFaqsLive.Index, :index
    end
  end

  ## Authentication routes

  scope "/", HomesiteWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [
        {HomesiteWeb.UserAuth, :require_authenticated},
        {HomesiteWeb.SetLocaleHook, :default},
        {HomesiteWeb.CaptureConnectionInfoHook, :default}
      ] do
      live "/dashboard", DashboardLive.Index, :index

      live "/posts", PostLive.Index, :index
      live "/posts/new", PostLive.Form, :new
      live "/posts/:slug/edit", PostLive.Form, :edit

      live "/tags", TagLive.Index, :index
      live "/tags/new", TagLive.Form, :new
      live "/tags/:id/edit", TagLive.Form, :edit
      live "/tags/:id", TagLive.Show, :show

      live "/feed", FeedLive.Index, :index
      live "/following", FollowingLive.Index, :index

      live "/feeds", FeedSourceLive.Index, :index
      live "/feeds/new", FeedSourceLive.Form, :new
      live "/feeds/:id/edit", FeedSourceLive.Form, :edit
      live "/feeds/:id", FeedSourceLive.Show, :show

      live "/folders", FeedFolderLive.Index, :index

      live "/projects", ProjectLive.Index, :index
      live "/projects/new", ProjectLive.SteppedForm, :new
      live "/projects/:id/edit", ProjectLive.SteppedForm, :edit
      live "/projects/:id", ProjectLive.Show, :show

      live "/media", MediaLive.Index, :index
      live "/media/:id", MediaLive.Show, :show

      live "/chat", ChatLive.Index, :index
      live "/chat/:slug", ChatLive.Show, :show

      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email

      # Feedback submission (authenticated users only)
      live "/feedback", FeedbackLive.Index, :index

      # User moderation
      live "/moderation/mutes", ModerationLive.Mutes, :index
      live "/moderation/report/:user_id", ModerationLive.Report, :new

      # Notifications
      live "/notifications", NotificationLive.Index, :index
      live "/notifications/settings", NotificationLive.Settings, :index
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  # Admin routes (require admin role)
  scope "/", HomesiteWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_admin,
      on_mount: [
        {HomesiteWeb.UserAuth, :require_authenticated},
        {HomesiteWeb.UserAuth, :require_admin},
        {HomesiteWeb.SetLocaleHook, :default},
        {HomesiteWeb.CaptureConnectionInfoHook, :default}
      ] do
      live "/admin", AdminLive.Dashboard, :index
      live "/admin/users", AdminLive.Users.Index, :index
      live "/admin/invitations", AdminLive.Invitations.Index, :index
      live "/admin/feedback", AdminLive.Feedback.Index, :index
      live "/admin/system", AdminLive.System.Index, :index

      # Admin moderation
      live "/admin/moderation", AdminLive.Moderation.Dashboard, :index
      live "/admin/moderation/reports", AdminLive.Moderation.Reports, :index
      live "/admin/moderation/reports/:id", AdminLive.Moderation.Reports, :show
      live "/admin/moderation/suspensions", AdminLive.Moderation.Suspensions, :index
      live "/admin/moderation/bans", AdminLive.Moderation.Bans, :index
      live "/admin/moderation/banners", AdminLive.Moderation.Banners, :index
      live "/admin/moderation/logs", AdminLive.Moderation.Logs, :index
      live "/admin/moderation/violations", AdminLive.Moderation.Violations, :index
      live "/admin/moderation/settings", AdminLive.Moderation.Settings, :index

      # Admin FAQ management
      live "/faqs/new", FaqLive.Form, :new
      live "/faqs/:id/edit", FaqLive.Form, :edit

      # Admin settings
      live "/admin/settings", AdminLive.Settings.Index, :index

      # Admin threat reputation management
      live "/admin/threats", AdminLive.Threat.Dashboard, :index
      live "/admin/threats/ip-watchlist", AdminLive.Threat.IpWatchlist, :index
      live "/admin/threats/country-watchlist", AdminLive.Threat.CountryWatchlist, :index
    end
  end

  # Registration route - requires invitation code
  scope "/", HomesiteWeb do
    # Only apply rate limiting in non-test environments
    if Mix.env() != :test do
      pipe_through [:browser, :rate_limit_registration]
    else
      pipe_through [:browser]
    end

    live_session :registration,
      on_mount: [
        {HomesiteWeb.UserAuth, :mount_current_scope},
        {HomesiteWeb.SetLocaleHook, :default},
        {HomesiteWeb.CaptureConnectionInfoHook, :default}
      ] do
      live "/users/register", UserLive.Registration, :new
    end
  end

  scope "/", HomesiteWeb do
    # Only apply rate limiting in non-test environments
    if Mix.env() != :test do
      pipe_through [:browser, :rate_limit_auth]
    else
      pipe_through [:browser]
    end

    live_session :login,
      on_mount: [
        {HomesiteWeb.UserAuth, :mount_current_scope},
        {HomesiteWeb.SetLocaleHook, :default},
        {HomesiteWeb.CaptureConnectionInfoHook, :default}
      ] do
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
  end

  # Feed endpoints with rate limiting
  scope "/", HomesiteWeb do
    if Mix.env() != :test do
      pipe_through [:browser, :rate_limit_feeds]
    else
      pipe_through [:browser]
    end

    # Feeds - RSS, Atom, and JSON
    get "/rss.xml", FeedController, :index
    get "/feed.xml", FeedController, :index
    get "/feed.json", FeedController, :index

    get "/users/:user_identifier/rss.xml", FeedController, :user
    get "/users/:user_identifier/feed.xml", FeedController, :user
    get "/users/:user_identifier/feed.json", FeedController, :user

    get "/tags/:slug/rss.xml", FeedController, :tag
    get "/tags/:slug/feed.xml", FeedController, :tag
    get "/tags/:slug/feed.json", FeedController, :tag
  end

  scope "/", HomesiteWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [
        {HomesiteWeb.UserAuth, :mount_current_scope},
        {HomesiteWeb.SetLocaleHook, :default},
        {HomesiteWeb.CaptureConnectionInfoHook, :default}
      ] do
      live "/users/:user_identifier", UserLive.Profile, :show
      live "/users/:user_identifier/projects", UserLive.Projects, :index
      live "/users/:user_identifier/followers", UserLive.Followers, :followers
      live "/users/:user_identifier/following", UserLive.Followers, :following
      live "/posts/:slug", PostLive.Show, :show
    end

    # Redirect old /posts/:id/:slug URLs to new /posts/:slug format
    get "/posts/:id/:slug", PostRedirectController, :show_with_slug

    delete "/users/log-out", UserSessionController, :delete
  end
end
