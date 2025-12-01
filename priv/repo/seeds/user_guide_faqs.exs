# User Guide FAQs - Social Media Feeds and Username Routing
# Run with: mix run priv/repo/seeds/user_guide_faqs.exs

alias Homesite.Repo
alias Homesite.Accounts
alias Homesite.Faqs
alias Homesite.Faqs.Faq

# Get or create admin user for FAQ creation
admin_user =
  case Repo.get_by(Accounts.User, email: "admin5@example.com") do
    nil ->
      IO.puts("Creating admin user for FAQs...")

      {:ok, user} =
        Accounts.register_admin(%{
          email: "faq-admin@example.com",
          password: "adminpassword123",
          flowers: 5,
          confirmed_at: DateTime.utc_now(:second)
        })

      user

    user ->
      user
  end

# Create admin scope using Scope.for_user/1
admin_scope = Accounts.Scope.for_user(admin_user)

IO.puts("\n=== Creating User Guide FAQs ===\n")

# Social Media Feeds FAQs
social_feed_faqs = [
  %{
    category: "user",
    question_en: "What social media platforms are supported by the feed adapters?",
    question_fi: "Mitä sosiaalisen median alustoja syötteenadapterit tukevat?",
    answer_en: """
    The system supports 6 platforms: RSS/Atom/JSON feeds (for blogs and websites),
    Mastodon (Fediverse network), Bluesky (AT Protocol), YouTube (channel feeds),
    Twitter/X (via RSS bridges), and Instagram (via RSS bridges). Each platform has
    different configuration requirements - RSS needs a feed URL, while Mastodon and
    Bluesky need usernames.
    """,
    answer_fi: """
    Järjestelmä tukee 6 alustaa: RSS/Atom/JSON-syötteet (blogit ja verkkosivustot),
    Mastodon (Fediverse-verkko), Bluesky (AT-protokolla), YouTube (kanava-syötteet),
    Twitter/X (RSS-siltojen kautta) ja Instagram (RSS-siltojen kautta). Jokaisella
    alustalla on erilaiset konfiguraatiovaatimukset - RSS tarvitsee syötteen URL:n,
    kun taas Mastodon ja Bluesky tarvitsevat käyttäjätunnuksen.
    """,
    display_order: 10,
    slug: "supported-social-media-platforms"
  },
  %{
    category: "user",
    question_en: "How do I add an RSS feed to my feed list?",
    question_fi: "Miten lisään RSS-syötteen syöteluettelooni?",
    answer_en: """
    Navigate to /feeds, click \"New Feed Source\", select \"RSS\" as the feed type,
    enter the feed URL (e.g., https://example.com/feed.xml), give it a name, and
    configure the refresh interval (default 30 minutes). Click \"Save\" to activate
    the feed. The system will automatically fetch content based on your refresh interval.
    """,
    answer_fi: """
    Siirry osoitteeseen /feeds, klikkaa \"New Feed Source\", valitse \"RSS\" syötetyypiksi,
    syötä syötteen URL (esim. https://example.com/feed.xml), anna sille nimi ja
    määritä päivitysväli (oletus 30 minuuttia). Klikkaa \"Save\" aktivoidaksesi
    syötteen. Järjestelmä hakee sisältöä automaattisesti määrittämäsi päivitysvälin mukaan.
    """,
    display_order: 20,
    slug: "add-rss-feed"
  },
  %{
    category: "user",
    question_en: "What should I do if a feed shows an error status?",
    question_fi: "Mitä teen, jos syöte näyttää virhetilaa?",
    answer_en: """
    If a feed shows a red error badge, first check the error message by hovering
    over or clicking the status. Common issues include: invalid URL (verify the
    feed URL works in a browser), rate limiting (reduce refresh interval), user
    not found for social platforms (check username format and account visibility),
    or temporary server downtime. You can manually retry with the \"Refresh Now\"
    button. For persistent errors, verify the source is still active and accessible.
    """,
    answer_fi: """
    Jos syöte näyttää punaisen virheilmoituksen, tarkista ensin virheviesti viemällä
    hiiri tilan päälle tai klikkaamalla sitä. Yleisiä ongelmia ovat: virheellinen URL
    (varmista, että syötte-URL toimii selaimessa), nopeudenrajoitus (pienennä
    päivitysväliä), käyttäjää ei löydy sosiaalisen median alustoilla (tarkista
    käyttäjätunnuksen muoto ja tilin näkyvyys) tai väliaikainen palvelinkatkos.
    Voit yrittää manuaalisesti uudelleen \"Refresh Now\" -painikkeella. Jatkuvien
    virheiden kohdalla varmista, että lähde on edelleen aktiivinen ja saatavilla.
    """,
    display_order: 30,
    slug: "feed-error-troubleshooting"
  },
  %{
    category: "user",
    question_en: "What is the recommended refresh interval for different feed types?",
    question_fi: "Mikä on suositeltu päivitysväli eri syötetyypeille?",
    answer_en: """
    Recommended refresh intervals: Personal blogs (60-120 minutes) - they update
    infrequently, News feeds (15-30 minutes) - for timely updates, Social media
    platforms like Mastodon/Bluesky (30-60 minutes) - balances freshness with API
    politeness. Avoid setting intervals below 15 minutes to respect platform rate
    limits and reduce unnecessary load. You can always use \"Refresh Now\" for
    immediate updates when needed.
    """,
    answer_fi: """
    Suositellut päivitysvälit: Henkilökohtaiset blogit (60-120 minuuttia) - ne
    päivittyvät harvoin, Uutissyötteet (15-30 minuuttia) - ajantasaisiin päivityksiin,
    Sosiaalisen median alustat kuten Mastodon/Bluesky (30-60 minuuttia) - tasapainottaa
    tuoreuden ja API:n kohteliaisuuden. Vältä alle 15 minuutin välejä kunnioittaaksesi
    alustojen nopeudenrajoituksia ja vähentääksesi turhaa kuormaa. Voit aina käyttää
    \"Refresh Now\" -toimintoa välittömiin päivityksiin tarvittaessa.
    """,
    display_order: 40,
    slug: "recommended-refresh-intervals"
  },
  %{
    category: "user",
    question_en: "How do I add a Mastodon or Bluesky feed?",
    question_fi: "Miten lisään Mastodon- tai Bluesky-syötteen?",
    answer_en: """
    For Mastodon: Select \"mastodon\" as feed type and enter the full username with
    @ prefix and instance (e.g., @elixirlang@fosstodon.org). For Bluesky: Select
    \"bluesky\" and enter just the handle (e.g., user.bsky.social). Both use public
    APIs requiring no authentication, but the account must be public (not private/protected).
    The system will fetch the latest posts based on your configured refresh interval.
    """,
    answer_fi: """
    Mastodonille: Valitse \"mastodon\" syötetyypiksi ja syötä täydellinen käyttäjätunnus
    @-etuliitteellä ja instanssilla (esim. @elixirlang@fosstodon.org). Blueskyllä:
    Valitse \"bluesky\" ja syötä vain käyttäjätunnus (esim. user.bsky.social). Molemmat
    käyttävät julkisia API:ita, jotka eivät vaadi todennusta, mutta tilin on oltava
    julkinen (ei yksityinen/suojattu). Järjestelmä hakee uusimmat julkaisut määrittämäsi
    päivitysvälin mukaan.
    """,
    display_order: 50,
    slug: "add-mastodon-bluesky-feed"
  }
]

# Username Routing FAQs
username_routing_faqs = [
  %{
    category: "user",
    question_en: "How do I set up a custom username for my profile URL?",
    question_fi: "Miten määritän mukautetun käyttäjätunnuksen profiili-URL:lleni?",
    answer_en: """
    Go to /users/settings, find the \"Username\" field in the profile form, and
    enter your desired username (3-30 characters, must start with a lowercase letter,
    only lowercase letters, numbers, and underscores allowed). Click \"Save Changes\"
    to activate. Your profile will then be accessible at /users/@yourusername in
    addition to the numeric ID URL (/users/123). The username must be unique and
    cannot be a reserved system word.
    """,
    answer_fi: """
    Siirry osoitteeseen /users/settings, etsi \"Username\" -kenttä profiililomakkeesta
    ja syötä haluamasi käyttäjätunnus (3-30 merkkiä, aloitettava pienellä kirjaimella,
    vain pienet kirjaimet, numerot ja alaviivat sallittu). Klikkaa \"Save Changes\"
    aktivoidaksesi. Profiilisi on sitten saatavilla osoitteessa /users/@käyttäjätunnuksesi
    numeerisen ID-URL:n lisäksi (/users/123). Käyttäjätunnuksen on oltava ainutlaatuinen
    eikä se voi olla varattu järjestelmäsana.
    """,
    display_order: 60,
    slug: "setup-custom-username"
  },
  %{
    category: "user",
    question_en: "What are the username format requirements?",
    question_fi: "Mitkä ovat käyttäjätunnuksen muotovaatimukset?",
    answer_en: """
    Username must be 3-30 characters long, start with a lowercase letter (a-z),
    and contain only lowercase letters, numbers, and underscores. No uppercase
    letters, hyphens, spaces, or special characters allowed. Examples of valid
    usernames: johndoe, alice_smith, dev123, elixir_fan. Examples of invalid:
    JohnDoe (uppercase), 123user (starts with number), jo (too short), john-doe
    (hyphen not allowed), admin (reserved word).
    """,
    answer_fi: """
    Käyttäjätunnuksen on oltava 3-30 merkkiä pitkä, aloitettava pienellä kirjaimella
    (a-z) ja sisältää vain pieniä kirjaimia, numeroita ja alaviivoja. Isot kirjaimet,
    väliviivat, välilyönnit tai erikoismerkit eivät ole sallittuja. Esimerkkejä
    kelvollisista käyttäjätunnuksista: johndoe, alice_smith, dev123, elixir_fan.
    Esimerkkejä virheellisistä: JohnDoe (isot kirjaimet), 123user (alkaa numerolla),
    jo (liian lyhyt), john-doe (väliviiva ei sallittu), admin (varattu sana).
    """,
    display_order: 70,
    slug: "username-format-requirements"
  },
  %{
    category: "user",
    question_en: "What happens if I change my username?",
    question_fi: "Mitä tapahtuu, jos vaihdan käyttäjätunnukseni?",
    answer_en: """
    When you change your username, the new @username URL works immediately, but
    old @username URLs return 404 (not found). Your numeric ID URL (/users/123)
    continues to work. The old username becomes available for others to claim.
    RSS feed subscriptions using the old username will break - you'll need to share
    new feed URLs with subscribers. All username changes are logged with timestamp,
    IP address, and user agent for security. Choose usernames carefully as frequent
    changes confuse followers.
    """,
    answer_fi: """
    Kun vaihdat käyttäjätunnuksesi, uusi @käyttäjätunnus-URL toimii välittömästi,
    mutta vanha @käyttäjätunnus-URL palauttaa 404 (ei löydy). Numeerinen ID-URL
    (/users/123) toimii edelleen. Vanha käyttäjätunnus tulee muiden varattavaksi.
    RSS-syötetilaukset vanhalla käyttäjätunnuksella rikkoutuvat - sinun on jaettava
    uudet syöte-URL:t tilaajille. Kaikki käyttäjätunnusten vaihdot kirjataan
    aikaleimalla, IP-osoitteella ja käyttäjäagentilla turvallisuussyistä. Valitse
    käyttäjätunnukset huolellisesti, sillä toistuvat muutokset hämmentävät seuraajia.
    """,
    display_order: 80,
    slug: "changing-username-effects"
  },
  %{
    category: "user",
    question_en: "Can I use my username in RSS feed URLs?",
    question_fi: "Voinko käyttää käyttäjätunnustani RSS-syöte-URL:issa?",
    answer_en: """
    Yes! Once you set a username, all feed formats support it: RSS at
    /users/@yourusername/rss.xml, Atom at /users/@yourusername/feed.xml, and
    JSON Feed at /users/@yourusername/feed.json. These URLs are more memorable
    and professional than numeric IDs. Share these with RSS readers like Feedly,
    Inoreader, NetNewsWire, or email newsletter services. Your feeds include only
    published posts, sorted by publication date.
    """,
    answer_fi: """
    Kyllä! Kun olet asettanut käyttäjätunnuksen, kaikki syötemuodot tukevat sitä:
    RSS osoitteessa /users/@käyttäjätunnuksesi/rss.xml, Atom osoitteessa
    /users/@käyttäjätunnuksesi/feed.xml ja JSON Feed osoitteessa
    /users/@käyttäjätunnuksesi/feed.json. Nämä URL:t ovat helpommin muistettavia
    ja ammattimaisempia kuin numeeriset ID:t. Jaa nämä RSS-lukijoiden kanssa kuten
    Feedly, Inoreader, NetNewsWire tai sähköpostilistan palveluiden kanssa. Syötteesi
    sisältävät vain julkaistut artikkelit, järjestettynä julkaisupäivän mukaan.
    """,
    display_order: 90,
    slug: "username-in-feed-urls"
  },
  %{
    category: "user",
    question_en: "Why can't I use certain usernames like 'admin' or 'api'?",
    question_fi: "Miksi en voi käyttää tiettyjä käyttäjätunnuksia kuten 'admin' tai 'api'?",
    answer_en: """
    Over 30 usernames are reserved for system routes and administrative functions
    to prevent routing conflicts. Reserved words include: admin, api, app, auth,
    blog, dashboard, dev, docs, feed, feeds, help, home, login, logout, new, posts,
    public, register, rss, search, settings, signup, staff, static, support, system,
    tags, test, user, users, www. These ensure the application's core functionality
    remains accessible and prevents confusion between user profiles and system pages.
    """,
    answer_fi: """
    Yli 30 käyttäjätunnusta on varattu järjestelmäreiteille ja hallinnollisille
    toiminnoille reitityskonfliktin estämiseksi. Varatut sanat sisältävät: admin,
    api, app, auth, blog, dashboard, dev, docs, feed, feeds, help, home, login,
    logout, new, posts, public, register, rss, search, settings, signup, staff,
    static, support, system, tags, test, user, users, www. Nämä varmistavat, että
    sovelluksen ydintoiminnot pysyvät saavutettavina ja estävät sekaannukset
    käyttäjäprofiilien ja järjestelmäsivujen välillä.
    """,
    display_order: 100,
    slug: "reserved-usernames-explanation"
  }
]

IO.puts("Creating Social Media Feeds FAQs...")

Enum.each(social_feed_faqs, fn faq_attrs ->
  case Faqs.create_faq(admin_scope, faq_attrs) do
    {:ok, faq} ->
      IO.puts("  ✅ Created: #{faq.question_en |> String.slice(0, 60)}...")

    {:error, changeset} ->
      IO.puts("  ❌ Failed: #{faq_attrs.question_en |> String.slice(0, 60)}...")
      IO.inspect(changeset.errors)
  end
end)

IO.puts("\nCreating Username Routing FAQs...")

Enum.each(username_routing_faqs, fn faq_attrs ->
  case Faqs.create_faq(admin_scope, faq_attrs) do
    {:ok, faq} ->
      IO.puts("  ✅ Created: #{faq.question_en |> String.slice(0, 60)}...")

    {:error, changeset} ->
      IO.puts("  ❌ Failed: #{faq_attrs.question_en |> String.slice(0, 60)}...")
      IO.inspect(changeset.errors)
  end
end)

IO.puts("\n=== FAQ Creation Complete ===")
IO.puts("Total FAQs created: #{length(social_feed_faqs) + length(username_routing_faqs)}")
IO.puts("\nView FAQs at: /faqs (when implemented)")
IO.puts("Or query with: Faqs.list_user_faqs(\"en\") or Faqs.list_user_faqs(\"fi\")")
