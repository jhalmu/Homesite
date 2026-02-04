defmodule HomesiteWeb.PrivacyLive.Index do
  @moduledoc """
  Privacy Policy page with bilingual content (Finnish/English).
  """
  use HomesiteWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="px-[var(--space-sm)] py-[var(--space-lg)] container mx-auto max-w-4xl">
      <h1 class="mb-[var(--space-md)] text-3xl font-bold">
        {gettext("Privacy Policy")}
      </h1>

      <div class="space-y-[var(--space-md)] prose prose-lg max-w-none dark:prose-invert">
        <section>
          <h2 class="text-xl font-semibold">{gettext("What data we collect")}</h2>
          <p>
            {gettext(
              "We collect only the information necessary to provide our services. This includes your email address (for authentication), profile information you choose to provide (display name, bio, avatar), and content you create (posts, tags)."
            )}
          </p>
        </section>

        <section>
          <h2 class="text-xl font-semibold">{gettext("How we use your data")}</h2>
          <p>
            {gettext(
              "Your data is used to provide the blog service, authenticate your account, and display your content. We do not sell your data to third parties or use it for advertising purposes."
            )}
          </p>
        </section>

        <section>
          <h2 class="text-xl font-semibold">{gettext("Your rights")}</h2>
          <ul class="pl-[var(--space-sm)] list-disc">
            <li>
              {gettext(
                "Right to access: You can download all your data from Settings → Download my data"
              )}
            </li>
            <li>
              {gettext("Right to rectification: You can edit your profile and content at any time")}
            </li>
            <li>
              {gettext("Right to erasure: You can delete your account from Settings → Delete Account")}
            </li>
            <li>
              {gettext(
                "Right to data portability: Your data export is provided in machine-readable JSON format"
              )}
            </li>
          </ul>
        </section>

        <section>
          <h2 class="text-xl font-semibold">{gettext("Data Retention")}</h2>
          <p>
            {gettext(
              "Your account data is retained as long as your account is active. When you delete your account, you can choose to anonymize your content (keeping posts with author shown as 'Deleted User') or delete everything. Server logs are retained for security purposes for up to 90 days."
            )}
          </p>
        </section>

        <section>
          <h2 class="text-xl font-semibold">{gettext("Cookies")}</h2>
          <p>
            {gettext(
              "We use essential cookies only: a session cookie for authentication and a locale preference cookie. We do not use tracking or advertising cookies."
            )}
          </p>
        </section>

        <section>
          <h2 class="text-xl font-semibold">{gettext("Third-party services")}</h2>
          <p>
            {gettext(
              "We use Cloudflare Turnstile for CAPTCHA protection during registration. No other third-party analytics or tracking services are used."
            )}
          </p>
        </section>

        <section>
          <h2 class="text-xl font-semibold">{gettext("Contact")}</h2>
          <p>
            {gettext(
              "For questions about your data or this privacy policy, please contact the site administrator."
            )}
          </p>
        </section>

        <p class="text-base-content/70 mt-[var(--space-lg)] text-sm">
          {gettext("Last updated: February 2026")}
        </p>
      </div>
    </div>
    """
  end
end
