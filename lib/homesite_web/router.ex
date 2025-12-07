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
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Rate limiting for authentication actions
  pipeline :rate_limit_auth do
    plug Hammer.Plug,
      rate_limit: {"auth:login", 60_000, 5},
      by: {:conn, &__MODULE__.get_ip/1}
  end

  pipeline :rate_limit_registration do
    plug Hammer.Plug,
      rate_limit: {"auth:register", 3_600_000, 3},
      by: {:conn, &__MODULE__.get_ip/1}
  end

  # Helper function to get IP address for rate limiting
  def get_ip(conn) do
    conn.remote_ip
    |> Tuple.to_list()
    |> Enum.join(".")
  end

  scope "/", HomesiteWeb do
    pipe_through :browser

    # SEO routes
    get "/sitemap.xml", SitemapController, :index

    live_session :public,
      on_mount: [
        {HomesiteWeb.UserAuth, :mount_current_scope},
        {HomesiteWeb.SetLocaleHook, :default}
      ] do
      live "/", PageLive.Home, :index

      # Public FAQ viewing
      live "/faqs", FaqLive.Index, :index

      # Public search
      live "/search", SearchLive.Index, :index

      # Public happiness meter and testimonials
      live "/happiness", HappinessLive.Index, :index
      live "/testimonials/:token", TestimonialLive.Show, :show

      # Public portfolio showcase
      live "/portfolio", PortfolioLive.Index, :index
      live "/portfolio/:slug", PortfolioLive.Show, :show
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
        {HomesiteWeb.SetLocaleHook, :default}
      ] do
      live "/dashboard", DashboardLive.Index, :index

      live "/posts", PostLive.Index, :index
      live "/posts/new", PostLive.Form, :new
      live "/posts/:id/edit", PostLive.Form, :edit

      live "/tags", TagLive.Index, :index
      live "/tags/new", TagLive.Form, :new
      live "/tags/:id/edit", TagLive.Form, :edit
      live "/tags/:id", TagLive.Show, :show

      live "/feed", FeedLive.Index, :index

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

      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email

      # Feedback submission (authenticated users only)
      live "/feedback", FeedbackLive.Index, :index
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
        {HomesiteWeb.SetLocaleHook, :default}
      ] do
      live "/admin", AdminLive.Dashboard, :index
      live "/admin/users", AdminLive.Users.Index, :index
      live "/admin/invitations", AdminLive.Invitations.Index, :index
      live "/admin/analytics", AdminLive.Analytics.Index, :index
      live "/admin/feedback", AdminLive.Feedback.Index, :index

      # Admin FAQ management
      live "/faqs/new", FaqLive.Form, :new
      live "/faqs/:id/edit", FaqLive.Form, :edit
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
        {HomesiteWeb.SetLocaleHook, :default}
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
        {HomesiteWeb.SetLocaleHook, :default}
      ] do
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
  end

  scope "/", HomesiteWeb do
    pipe_through [:browser]

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

    live_session :current_user,
      on_mount: [
        {HomesiteWeb.UserAuth, :mount_current_scope},
        {HomesiteWeb.SetLocaleHook, :default}
      ] do
      live "/users/:user_identifier", UserLive.Profile, :show
      live "/posts/:id", PostLive.Show, :show
    end

    delete "/users/log-out", UserSessionController, :delete
  end
end
