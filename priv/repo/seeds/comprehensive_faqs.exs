# Comprehensive FAQs - All System Features
# Run with: mix run priv/repo/seeds/comprehensive_faqs.exs
#
# This seed creates professional, bilingual (EN/FI) FAQs for:
# - User FAQs: Getting started, blog posts, profile, feeds, media, search
# - Admin FAQs: User management, invitations, FAQ management, analytics

alias Homesite.Repo
alias Homesite.Accounts
alias Homesite.Faqs

# Get or create admin user for FAQ creation
import Ecto.Query

admin_user =
  case Repo.one(from u in Accounts.User, where: u.role == "admin", limit: 1) do
    nil ->
      IO.puts("Creating admin user for FAQs...")

      {:ok, user} =
        Accounts.register_admin(%{
          email: "faq-admin@example.com",
          password: "adminpassword123!",
          flowers: 5,
          confirmed_at: DateTime.utc_now(:second)
        })

      user

    user ->
      IO.puts("Using existing admin: #{user.email}")
      user
  end

admin_scope = Accounts.Scope.for_user(admin_user)

IO.puts("\n========================================")
IO.puts("Creating Comprehensive FAQs")
IO.puts("========================================\n")

# =============================================================================
# USER FAQs - Getting Started
# =============================================================================

getting_started_faqs = [
  %{
    category: "user",
    question_en: "How do I register for an account?",
    question_fi: "Miten rekisteröidyn käyttäjäksi?",
    answer_en: """
    <p>To register for an account, you need an <strong>invitation code</strong> from an existing user or administrator. Here's how:</p>
    <ol>
      <li>Click "Log in" in the navigation menu</li>
      <li>Click "Register" on the login page</li>
      <li>Enter your email address, choose a secure password (minimum 8 characters)</li>
      <li>Enter your invitation code in the designated field</li>
      <li>Click "Create account"</li>
    </ol>
    <p>After registration, you'll receive a confirmation email. Click the link to verify your account and gain full access.</p>
    """,
    answer_fi: """
    <p>Rekisteröityäksesi tarvitset <strong>kutsukoodin</strong> olemassa olevalta käyttäjältä tai ylläpitäjältä. Toimi näin:</p>
    <ol>
      <li>Klikkaa "Kirjaudu" navigaatiovalikossa</li>
      <li>Klikkaa "Rekisteröidy" kirjautumissivulla</li>
      <li>Syötä sähköpostiosoitteesi ja valitse turvallinen salasana (vähintään 8 merkkiä)</li>
      <li>Syötä kutsukoodisi sille varattuun kenttään</li>
      <li>Klikkaa "Luo tili"</li>
    </ol>
    <p>Rekisteröitymisen jälkeen saat vahvistussähköpostin. Klikkaa linkkiä vahvistaaksesi tilisi ja saadaksesi täyden käyttöoikeuden.</p>
    """,
    display_order: 100,
    slug: "how-to-register"
  },
  %{
    category: "user",
    question_en: "How do I log in to my account?",
    question_fi: "Miten kirjaudun tililleni?",
    answer_en: """
    <p>There are two ways to log in:</p>
    <h4>Standard Login (Email + Password)</h4>
    <ol>
      <li>Click "Log in" in the navigation</li>
      <li>Enter your registered email address</li>
      <li>Enter your password</li>
      <li>Click "Log in"</li>
    </ol>
    <h4>Magic Link (Passwordless)</h4>
    <ol>
      <li>On the login page, click "Sign in with email link"</li>
      <li>Enter your email address</li>
      <li>Check your inbox for the magic link email</li>
      <li>Click the link to log in instantly (valid for 15 minutes)</li>
    </ol>
    <p><strong>Tip:</strong> Enable "Remember me" to stay logged in on trusted devices.</p>
    """,
    answer_fi: """
    <p>Kirjautumiseen on kaksi tapaa:</p>
    <h4>Tavallinen kirjautuminen (sähköposti + salasana)</h4>
    <ol>
      <li>Klikkaa "Kirjaudu" navigaatiossa</li>
      <li>Syötä rekisteröity sähköpostiosoitteesi</li>
      <li>Syötä salasanasi</li>
      <li>Klikkaa "Kirjaudu"</li>
    </ol>
    <h4>Taikainkki (salasanaton)</h4>
    <ol>
      <li>Klikkaa kirjautumissivulla "Kirjaudu sähköpostilinkillä"</li>
      <li>Syötä sähköpostiosoitteesi</li>
      <li>Tarkista sähköpostisi taikalinkkiviestin varalta</li>
      <li>Klikkaa linkkiä kirjautuaksesi välittömästi (voimassa 15 minuuttia)</li>
    </ol>
    <p><strong>Vinkki:</strong> Ota "Muista minut" käyttöön pysyäksesi kirjautuneena luotetuilla laitteilla.</p>
    """,
    display_order: 110,
    slug: "how-to-login"
  },
  %{
    category: "user",
    question_en: "How do I reset my password?",
    question_fi: "Miten nollaan salasanani?",
    answer_en: """
    <p>If you've forgotten your password:</p>
    <ol>
      <li>Go to the login page and click "Forgot password?"</li>
      <li>Enter your registered email address</li>
      <li>Click "Send reset instructions"</li>
      <li>Check your email for the reset link (valid for 1 hour)</li>
      <li>Click the link and enter your new password (minimum 8 characters)</li>
      <li>Confirm by entering the password again</li>
    </ol>
    <p><strong>Security note:</strong> The reset link can only be used once. For security reasons, we don't confirm whether an email exists in our system.</p>
    """,
    answer_fi: """
    <p>Jos olet unohtanut salasanasi:</p>
    <ol>
      <li>Mene kirjautumissivulle ja klikkaa "Unohditko salasanan?"</li>
      <li>Syötä rekisteröity sähköpostiosoitteesi</li>
      <li>Klikkaa "Lähetä nollausohjeet"</li>
      <li>Tarkista sähköpostisi nollauslinkin varalta (voimassa 1 tunti)</li>
      <li>Klikkaa linkkiä ja syötä uusi salasanasi (vähintään 8 merkkiä)</li>
      <li>Vahvista syöttämällä salasana uudelleen</li>
    </ol>
    <p><strong>Turvallisuushuomautus:</strong> Nollauslinkkiä voi käyttää vain kerran. Turvallisuussyistä emme vahvista, onko sähköpostiosoite järjestelmässämme.</p>
    """,
    display_order: 120,
    slug: "reset-password"
  },
  %{
    category: "user",
    question_en: "What is the Dashboard and what can I do there?",
    question_fi: "Mikä on kojelauta ja mitä siellä voi tehdä?",
    answer_en: """
    <p>The <strong>Dashboard</strong> is your personal command center showing:</p>
    <ul>
      <li><strong>Statistics:</strong> Total posts, tags, and views at a glance</li>
      <li><strong>Recent Activity:</strong> Your latest posts and interactions</li>
      <li><strong>Quick Actions:</strong> Shortcuts to create new posts or manage tags</li>
      <li><strong>Feed Updates:</strong> Latest items from your subscribed external feeds</li>
    </ul>
    <p>Access your dashboard anytime by clicking "Dashboard" in the navigation menu after logging in.</p>
    """,
    answer_fi: """
    <p><strong>Kojelauta</strong> on henkilökohtainen komentokeskuksesi, joka näyttää:</p>
    <ul>
      <li><strong>Tilastot:</strong> Julkaisujen, tagien ja katseluiden kokonaismäärä yhdellä silmäyksellä</li>
      <li><strong>Viimeaikainen toiminta:</strong> Uusimmat julkaisusi ja vuorovaikutuksesi</li>
      <li><strong>Pikatoiminnot:</strong> Pikakuvakkeet uusien julkaisujen luomiseen tai tagien hallintaan</li>
      <li><strong>Syötepäivitykset:</strong> Uusimmat kohteet tilaamistasi ulkoisista syötteistä</li>
    </ul>
    <p>Pääset kojelautaan milloin tahansa klikkaamalla "Kojelauta" navigaatiovalikossa kirjautumisen jälkeen.</p>
    """,
    display_order: 130,
    slug: "dashboard-overview"
  }
]

# =============================================================================
# USER FAQs - Blog Posts
# =============================================================================

blog_post_faqs = [
  %{
    category: "user",
    question_en: "How do I create a new blog post?",
    question_fi: "Miten luon uuden blogikirjoituksen?",
    answer_en: """
    <p>Creating a blog post is simple:</p>
    <ol>
      <li>Click "Posts" in the navigation menu</li>
      <li>Click the "New Post" button</li>
      <li>Enter a compelling title for your post</li>
      <li>Write your content using Markdown formatting</li>
      <li>Add relevant tags to categorize your post</li>
      <li>Set a publication date (leave blank for immediate publishing)</li>
      <li>Click "Save" to publish or "Save as Draft" to continue later</li>
    </ol>
    <p><strong>Tip:</strong> Use the preview feature to see how your post will look before publishing.</p>
    """,
    answer_fi: """
    <p>Blogikirjoituksen luominen on helppoa:</p>
    <ol>
      <li>Klikkaa "Julkaisut" navigaatiovalikossa</li>
      <li>Klikkaa "Uusi julkaisu" -painiketta</li>
      <li>Syötä kiinnostava otsikko julkaisullesi</li>
      <li>Kirjoita sisältösi käyttäen Markdown-muotoilua</li>
      <li>Lisää relevantteja tageja julkaisusi luokittelemiseksi</li>
      <li>Aseta julkaisupäivä (jätä tyhjäksi välittömään julkaisuun)</li>
      <li>Klikkaa "Tallenna" julkaistaksesi tai "Tallenna luonnoksena" jatkaaksesi myöhemmin</li>
    </ol>
    <p><strong>Vinkki:</strong> Käytä esikatselutoimintoa nähdäksesi miltä julkaisusi näyttää ennen julkaisua.</p>
    """,
    display_order: 200,
    slug: "create-blog-post"
  },
  %{
    category: "user",
    question_en: "What Markdown formatting is supported?",
    question_fi: "Mitä Markdown-muotoilua tuetaan?",
    answer_en: """
    <p>Our editor supports full <strong>GitHub Flavored Markdown</strong> with these features:</p>
    <ul>
      <li><strong>Headers:</strong> Use # for h1, ## for h2, etc.</li>
      <li><strong>Text styling:</strong> **bold**, *italic*, ~~strikethrough~~</li>
      <li><strong>Lists:</strong> Numbered (1. 2. 3.) and bullet points (- or *)</li>
      <li><strong>Links:</strong> [text](url) or auto-linked URLs</li>
      <li><strong>Images:</strong> ![alt text](image-url)</li>
      <li><strong>Code:</strong> Inline `code` and fenced code blocks with syntax highlighting</li>
      <li><strong>Tables:</strong> Using pipe | characters</li>
      <li><strong>Task lists:</strong> - [ ] unchecked, - [x] checked</li>
      <li><strong>Blockquotes:</strong> > for quoted text</li>
    </ul>
    <p>Code blocks support syntax highlighting for Elixir, JavaScript, Python, and 100+ languages.</p>
    """,
    answer_fi: """
    <p>Editorimme tukee täydellistä <strong>GitHub Flavored Markdownia</strong> näillä ominaisuuksilla:</p>
    <ul>
      <li><strong>Otsikot:</strong> Käytä # h1:lle, ## h2:lle jne.</li>
      <li><strong>Tekstin muotoilu:</strong> **lihavoitu**, *kursivoitu*, ~~yliviivattu~~</li>
      <li><strong>Listat:</strong> Numeroidut (1. 2. 3.) ja luettelomerkit (- tai *)</li>
      <li><strong>Linkit:</strong> [teksti](url) tai automaattisesti linkitetyt URL:t</li>
      <li><strong>Kuvat:</strong> ![vaihtoehtoinen teksti](kuvan-url)</li>
      <li><strong>Koodi:</strong> Rivikoodi `koodi` ja koodilohkot syntaksikorostuksella</li>
      <li><strong>Taulukot:</strong> Käyttäen pystyviivaa |</li>
      <li><strong>Tehtävälistat:</strong> - [ ] valitsematon, - [x] valittu</li>
      <li><strong>Lainaukset:</strong> > lainatulle tekstille</li>
    </ul>
    <p>Koodilohkot tukevat syntaksikorostusta Elixirille, JavaScriptille, Pythonille ja yli 100 muulle kielelle.</p>
    """,
    display_order: 210,
    slug: "markdown-formatting"
  },
  %{
    category: "user",
    question_en: "How do I edit or delete a post?",
    question_fi: "Miten muokkaan tai poistan julkaisun?",
    answer_en: """
    <p><strong>To edit a post:</strong></p>
    <ol>
      <li>Go to "Posts" and find the post you want to edit</li>
      <li>Click the post title to view it, then click "Edit post"</li>
      <li>Or click the edit icon (pencil) directly from the post list</li>
      <li>Make your changes and click "Save"</li>
    </ol>
    <p><strong>To delete a post:</strong></p>
    <ol>
      <li>Open the post you want to delete</li>
      <li>Click the "Delete" button</li>
      <li>Confirm the deletion when prompted</li>
    </ol>
    <p><strong>Warning:</strong> Deleted posts cannot be recovered. Consider unpublishing instead by clearing the publication date.</p>
    """,
    answer_fi: """
    <p><strong>Julkaisun muokkaaminen:</strong></p>
    <ol>
      <li>Mene "Julkaisut"-osioon ja etsi muokattava julkaisu</li>
      <li>Klikkaa julkaisun otsikkoa nähdäksesi sen, sitten klikkaa "Muokkaa julkaisua"</li>
      <li>Tai klikkaa muokkauskuvaketta (kynä) suoraan julkaisulistasta</li>
      <li>Tee muutoksesi ja klikkaa "Tallenna"</li>
    </ol>
    <p><strong>Julkaisun poistaminen:</strong></p>
    <ol>
      <li>Avaa julkaisu, jonka haluat poistaa</li>
      <li>Klikkaa "Poista"-painiketta</li>
      <li>Vahvista poisto pyydettäessä</li>
    </ol>
    <p><strong>Varoitus:</strong> Poistettuja julkaisuja ei voi palauttaa. Harkitse julkaisun poistamista julkisesta näkyvyydestä tyhjentämällä julkaisupäivä.</p>
    """,
    display_order: 220,
    slug: "edit-delete-post"
  },
  %{
    category: "user",
    question_en: "Who can see my posts?",
    question_fi: "Kuka voi nähdä julkaisuni?",
    answer_en: """
    <p>Post visibility depends on the publication status:</p>
    <ul>
      <li><strong>Published posts</strong> (with a publication date): Visible to everyone, including non-logged-in visitors</li>
      <li><strong>Draft posts</strong> (no publication date): Only visible to you</li>
      <li><strong>Future-dated posts:</strong> Hidden until the publication date arrives</li>
    </ul>
    <p>Published posts appear on:</p>
    <ul>
      <li>Your public profile page (/users/@username)</li>
      <li>Tag pages for any tags you've assigned</li>
      <li>Site-wide search results</li>
      <li>RSS/Atom/JSON feeds</li>
    </ul>
    """,
    answer_fi: """
    <p>Julkaisun näkyvyys riippuu julkaisutilasta:</p>
    <ul>
      <li><strong>Julkaistut julkaisut</strong> (julkaisupäivän kanssa): Näkyvät kaikille, mukaan lukien kirjautumattomille vierailijoille</li>
      <li><strong>Luonnosjulkaisut</strong> (ei julkaisupäivää): Näkyvät vain sinulle</li>
      <li><strong>Tulevaisuuteen ajastetut julkaisut:</strong> Piilotettu kunnes julkaisupäivä koittaa</li>
    </ul>
    <p>Julkaistut julkaisut näkyvät:</p>
    <ul>
      <li>Julkisella profiilisivullasi (/users/@käyttäjätunnus)</li>
      <li>Tagisivuilla määrittämillesi tageille</li>
      <li>Sivuston hakutuloksissa</li>
      <li>RSS/Atom/JSON-syötteissä</li>
    </ul>
    """,
    display_order: 230,
    slug: "post-visibility"
  }
]

# =============================================================================
# USER FAQs - Tags
# =============================================================================

tag_faqs = [
  %{
    category: "user",
    question_en: "How do I create and use tags?",
    question_fi: "Miten luon ja käytän tageja?",
    answer_en: """
    <p><strong>Creating tags:</strong></p>
    <ol>
      <li>Go to "Tags" in the navigation</li>
      <li>Click "New Tag"</li>
      <li>Enter a name (unique, descriptive)</li>
      <li>Optionally add a description</li>
      <li>Click "Save"</li>
    </ol>
    <p><strong>Using tags in posts:</strong></p>
    <ol>
      <li>When creating or editing a post, find the "Tags" field</li>
      <li>Select existing tags from the dropdown</li>
      <li>Posts can have multiple tags</li>
    </ol>
    <p><strong>Benefits of tags:</strong></p>
    <ul>
      <li>Help readers find related content</li>
      <li>Organize your posts by topic</li>
      <li>Each tag has its own page showing all tagged posts</li>
    </ul>
    """,
    answer_fi: """
    <p><strong>Tagien luominen:</strong></p>
    <ol>
      <li>Mene "Tagit"-osioon navigaatiossa</li>
      <li>Klikkaa "Uusi tagi"</li>
      <li>Syötä nimi (uniikki, kuvaava)</li>
      <li>Lisää valinnaisesti kuvaus</li>
      <li>Klikkaa "Tallenna"</li>
    </ol>
    <p><strong>Tagien käyttö julkaisuissa:</strong></p>
    <ol>
      <li>Julkaisua luodessa tai muokatessa etsi "Tagit"-kenttä</li>
      <li>Valitse olemassa olevia tageja pudotusvalikosta</li>
      <li>Julkaisuilla voi olla useita tageja</li>
    </ol>
    <p><strong>Tagien hyödyt:</strong></p>
    <ul>
      <li>Auttavat lukijoita löytämään liittyvää sisältöä</li>
      <li>Järjestävät julkaisusi aiheen mukaan</li>
      <li>Jokaisella tagilla on oma sivu, joka näyttää kaikki tagitetyt julkaisut</li>
    </ul>
    """,
    display_order: 300,
    slug: "create-use-tags"
  }
]

# =============================================================================
# USER FAQs - Profile & Settings
# =============================================================================

profile_faqs = [
  %{
    category: "user",
    question_en: "How do I customize my profile?",
    question_fi: "Miten mukautan profiiliani?",
    answer_en: """
    <p>Go to <strong>Settings</strong> in the navigation menu to customize:</p>
    <ul>
      <li><strong>Display Name:</strong> The name shown on your profile and posts</li>
      <li><strong>Username:</strong> Your unique @username for profile URL</li>
      <li><strong>Bio:</strong> A short description about yourself</li>
      <li><strong>Avatar:</strong> Upload a profile picture (JPG, PNG, max 5MB)</li>
      <li><strong>Website:</strong> Link to your personal website</li>
      <li><strong>Social Links:</strong> Your Bluesky and Mastodon handles</li>
    </ul>
    <p>Your public profile at <code>/users/@username</code> displays this information along with your published posts.</p>
    """,
    answer_fi: """
    <p>Mene <strong>Asetukset</strong>-osioon navigaatiovalikossa mukauttaaksesi:</p>
    <ul>
      <li><strong>Näyttönimi:</strong> Profiilissasi ja julkaisuissasi näytettävä nimi</li>
      <li><strong>Käyttäjätunnus:</strong> Uniikki @käyttäjätunnus profiilin URL:lle</li>
      <li><strong>Bio:</strong> Lyhyt kuvaus itsestäsi</li>
      <li><strong>Avatar:</strong> Lataa profiilikuva (JPG, PNG, max 5MB)</li>
      <li><strong>Verkkosivusto:</strong> Linkki henkilökohtaiselle verkkosivustollesi</li>
      <li><strong>Sosiaalisen median linkit:</strong> Bluesky- ja Mastodon-tunnuksesi</li>
    </ul>
    <p>Julkinen profiilisi osoitteessa <code>/users/@käyttäjätunnus</code> näyttää nämä tiedot sekä julkaistut julkaisusi.</p>
    """,
    display_order: 400,
    slug: "customize-profile"
  },
  %{
    category: "user",
    question_en: "How do I change my email address?",
    question_fi: "Miten vaihdan sähköpostiosoitteeni?",
    answer_en: """
    <p>To change your email address:</p>
    <ol>
      <li>Go to Settings → Email section</li>
      <li>Enter your new email address</li>
      <li>Enter your current password to confirm</li>
      <li>Click "Change email"</li>
      <li>Check your new email for a confirmation link</li>
      <li>Click the confirmation link to activate the new address</li>
    </ol>
    <p><strong>Important:</strong> Your old email remains active until you confirm the new one. The confirmation link expires after 1 hour.</p>
    """,
    answer_fi: """
    <p>Sähköpostiosoitteen vaihtaminen:</p>
    <ol>
      <li>Mene Asetukset → Sähköposti-osioon</li>
      <li>Syötä uusi sähköpostiosoitteesi</li>
      <li>Syötä nykyinen salasanasi vahvistaaksesi</li>
      <li>Klikkaa "Vaihda sähköposti"</li>
      <li>Tarkista uusi sähköpostisi vahvistuslinkin varalta</li>
      <li>Klikkaa vahvistuslinkkiä aktivoidaksesi uuden osoitteen</li>
    </ol>
    <p><strong>Tärkeää:</strong> Vanha sähköpostisi pysyy aktiivisena kunnes vahvistat uuden. Vahvistuslinkki vanhenee 1 tunnin kuluttua.</p>
    """,
    display_order: 410,
    slug: "change-email"
  },
  %{
    category: "user",
    question_en: "How do I change my password?",
    question_fi: "Miten vaihdan salasanani?",
    answer_en: """
    <p>To change your password while logged in:</p>
    <ol>
      <li>Go to Settings → Password section</li>
      <li>Enter your current password</li>
      <li>Enter your new password (minimum 8 characters)</li>
      <li>Confirm by entering the new password again</li>
      <li>Click "Change password"</li>
    </ol>
    <p><strong>Password requirements:</strong></p>
    <ul>
      <li>Minimum 8 characters</li>
      <li>Mix of letters, numbers, and symbols recommended</li>
      <li>Avoid common words or personal information</li>
    </ul>
    """,
    answer_fi: """
    <p>Salasanan vaihtaminen kirjautuneena:</p>
    <ol>
      <li>Mene Asetukset → Salasana-osioon</li>
      <li>Syötä nykyinen salasanasi</li>
      <li>Syötä uusi salasanasi (vähintään 8 merkkiä)</li>
      <li>Vahvista syöttämällä uusi salasana uudelleen</li>
      <li>Klikkaa "Vaihda salasana"</li>
    </ol>
    <p><strong>Salasanavaatimukset:</strong></p>
    <ul>
      <li>Vähintään 8 merkkiä</li>
      <li>Suositellaan kirjainten, numeroiden ja symbolien yhdistelmää</li>
      <li>Vältä yleisiä sanoja tai henkilökohtaisia tietoja</li>
    </ul>
    """,
    display_order: 420,
    slug: "change-password"
  }
]

# =============================================================================
# USER FAQs - RSS Feeds
# =============================================================================

rss_faqs = [
  %{
    category: "user",
    question_en: "How can readers subscribe to my blog?",
    question_fi: "Miten lukijat voivat tilata blogini?",
    answer_en: """
    <p>Your blog automatically provides feeds in three formats:</p>
    <ul>
      <li><strong>RSS:</strong> <code>/users/@username/rss.xml</code></li>
      <li><strong>Atom:</strong> <code>/users/@username/feed.xml</code></li>
      <li><strong>JSON Feed:</strong> <code>/users/@username/feed.json</code></li>
    </ul>
    <p>Readers can subscribe using any feed reader like Feedly, Inoreader, NetNewsWire, or Newsblur.</p>
    <p>The site also provides global feeds:</p>
    <ul>
      <li>RSS: <code>/rss.xml</code></li>
      <li>Atom: <code>/feed.xml</code></li>
      <li>JSON: <code>/feed.json</code></li>
    </ul>
    <p>Feed links are automatically included in your page's HTML for autodiscovery.</p>
    """,
    answer_fi: """
    <p>Blogisi tarjoaa automaattisesti syötteet kolmessa muodossa:</p>
    <ul>
      <li><strong>RSS:</strong> <code>/users/@käyttäjätunnus/rss.xml</code></li>
      <li><strong>Atom:</strong> <code>/users/@käyttäjätunnus/feed.xml</code></li>
      <li><strong>JSON Feed:</strong> <code>/users/@käyttäjätunnus/feed.json</code></li>
    </ul>
    <p>Lukijat voivat tilata millä tahansa syötteenlukijalla kuten Feedly, Inoreader, NetNewsWire tai Newsblur.</p>
    <p>Sivusto tarjoaa myös yleiset syötteet:</p>
    <ul>
      <li>RSS: <code>/rss.xml</code></li>
      <li>Atom: <code>/feed.xml</code></li>
      <li>JSON: <code>/feed.json</code></li>
    </ul>
    <p>Syötelinkit sisällytetään automaattisesti sivusi HTML:ään automaattista löytämistä varten.</p>
    """,
    display_order: 500,
    slug: "subscribe-to-blog"
  }
]

# =============================================================================
# USER FAQs - Search
# =============================================================================

search_faqs = [
  %{
    category: "user",
    question_en: "How do I search for content?",
    question_fi: "Miten haen sisältöä?",
    answer_en: """
    <p>Use the <strong>Search</strong> feature in the navigation to find content:</p>
    <ol>
      <li>Click the search icon or "Search" in the menu</li>
      <li>Enter your search terms</li>
      <li>Press Enter or click Search</li>
    </ol>
    <p><strong>Search finds:</strong></p>
    <ul>
      <li>Blog posts (titles and content)</li>
      <li>Tags (names and descriptions)</li>
      <li>FAQs (questions and answers)</li>
    </ul>
    <p><strong>Tips:</strong></p>
    <ul>
      <li>Use multiple keywords for more specific results</li>
      <li>Search is case-insensitive</li>
      <li>Results are ranked by relevance</li>
    </ul>
    """,
    answer_fi: """
    <p>Käytä <strong>Haku</strong>-toimintoa navigaatiossa sisällön löytämiseen:</p>
    <ol>
      <li>Klikkaa hakukuvaketta tai "Haku" valikossa</li>
      <li>Syötä hakusanasi</li>
      <li>Paina Enter tai klikkaa Hae</li>
    </ol>
    <p><strong>Haku löytää:</strong></p>
    <ul>
      <li>Blogikirjoitukset (otsikot ja sisältö)</li>
      <li>Tagit (nimet ja kuvaukset)</li>
      <li>Usein kysytyt kysymykset (kysymykset ja vastaukset)</li>
    </ul>
    <p><strong>Vinkkejä:</strong></p>
    <ul>
      <li>Käytä useita avainsanoja tarkempiin tuloksiin</li>
      <li>Haku ei erottele isoja ja pieniä kirjaimia</li>
      <li>Tulokset järjestetään relevanssin mukaan</li>
    </ul>
    """,
    display_order: 600,
    slug: "search-content"
  }
]

# =============================================================================
# USER FAQs - Media & Projects
# =============================================================================

media_faqs = [
  %{
    category: "user",
    question_en: "How do I upload and manage media files?",
    question_fi: "Miten lataan ja hallinnoin mediatiedostoja?",
    answer_en: """
    <p>The <strong>Media Library</strong> lets you upload and organize images and files:</p>
    <ol>
      <li>Go to "Media" in the navigation</li>
      <li>Click "Upload" or drag files into the upload area</li>
      <li>Supported formats: JPG, PNG, GIF, WebP (images), PDF (documents)</li>
      <li>Maximum file size: 10MB per file</li>
    </ol>
    <p><strong>Organizing media:</strong></p>
    <ul>
      <li>Add tags to categorize your media</li>
      <li>Use the search to find specific files</li>
      <li>Click any item to view details and get embed URLs</li>
    </ul>
    <p><strong>Using in posts:</strong> Copy the media URL and use Markdown image syntax: <code>![description](url)</code></p>
    """,
    answer_fi: """
    <p><strong>Mediakirjasto</strong> mahdollistaa kuvien ja tiedostojen lataamisen ja järjestämisen:</p>
    <ol>
      <li>Mene "Media"-osioon navigaatiossa</li>
      <li>Klikkaa "Lataa" tai vedä tiedostot latausahueelle</li>
      <li>Tuetut muodot: JPG, PNG, GIF, WebP (kuvat), PDF (dokumentit)</li>
      <li>Maksimitiedostokoko: 10MB per tiedosto</li>
    </ol>
    <p><strong>Median järjestäminen:</strong></p>
    <ul>
      <li>Lisää tageja median luokittelemiseksi</li>
      <li>Käytä hakua tiettyjen tiedostojen löytämiseen</li>
      <li>Klikkaa kohdetta nähdäksesi yksityiskohdat ja saadaksesi upotus-URL:t</li>
    </ul>
    <p><strong>Käyttö julkaisuissa:</strong> Kopioi median URL ja käytä Markdown-kuvasyntaksia: <code>![kuvaus](url)</code></p>
    """,
    display_order: 700,
    slug: "upload-manage-media"
  },
  %{
    category: "user",
    question_en: "What are Projects and how do I use them?",
    question_fi: "Mitä projektit ovat ja miten niitä käytetään?",
    answer_en: """
    <p><strong>Projects</strong> let you showcase your work in organized collections:</p>
    <h4>Project Types:</h4>
    <ul>
      <li><strong>Portfolio:</strong> Showcase your best work publicly</li>
      <li><strong>Library:</strong> Organize media into private collections</li>
    </ul>
    <h4>Creating a project:</h4>
    <ol>
      <li>Go to "Projects" in the navigation</li>
      <li>Click "New Project"</li>
      <li>Choose a type (Portfolio or Library)</li>
      <li>Add a title, description, and cover image</li>
      <li>Add media items to the project</li>
      <li>Set visibility (public or private)</li>
    </ol>
    <p>Portfolio projects are displayed on your public profile page for visitors to browse.</p>
    """,
    answer_fi: """
    <p><strong>Projektit</strong> mahdollistavat työnäytteiden esittelyn järjestetyissä kokoelmissa:</p>
    <h4>Projektityypit:</h4>
    <ul>
      <li><strong>Portfolio:</strong> Esittele parhaita töitäsi julkisesti</li>
      <li><strong>Kirjasto:</strong> Järjestä media yksityisiin kokoelmiin</li>
    </ul>
    <h4>Projektin luominen:</h4>
    <ol>
      <li>Mene "Projektit"-osioon navigaatiossa</li>
      <li>Klikkaa "Uusi projekti"</li>
      <li>Valitse tyyppi (Portfolio tai Kirjasto)</li>
      <li>Lisää otsikko, kuvaus ja kansikuva</li>
      <li>Lisää mediakohteita projektiin</li>
      <li>Aseta näkyvyys (julkinen tai yksityinen)</li>
    </ol>
    <p>Portfolio-projektit näytetään julkisella profiilisivullasi vierailijoiden selattavaksi.</p>
    """,
    display_order: 710,
    slug: "projects-overview"
  }
]

# =============================================================================
# USER FAQs - Feedback
# =============================================================================

feedback_faqs = [
  %{
    category: "user",
    question_en: "How do I provide feedback about the site?",
    question_fi: "Miten annan palautetta sivustosta?",
    answer_en: """
    <p>We value your feedback! Here's how to share your thoughts:</p>
    <ol>
      <li>Click "Feedback" in the navigation or footer</li>
      <li>Rate your overall experience (happiness meter)</li>
      <li>Share specific feedback or suggestions</li>
      <li>Optionally allow your feedback as a testimonial</li>
      <li>Submit your feedback</li>
    </ol>
    <p><strong>What we'd love to hear:</strong></p>
    <ul>
      <li>Features you'd like to see</li>
      <li>Issues you've encountered</li>
      <li>What you enjoy about the site</li>
      <li>Suggestions for improvement</li>
    </ul>
    <p>Your feedback helps us improve the platform for everyone!</p>
    """,
    answer_fi: """
    <p>Arvostamme palautettasi! Näin jaat ajatuksesi:</p>
    <ol>
      <li>Klikkaa "Palaute" navigaatiossa tai alatunnisteessa</li>
      <li>Arvioi kokonaiskokemuksesi (tyytyväisyysmittari)</li>
      <li>Jaa erityistä palautetta tai ehdotuksia</li>
      <li>Valinnaisesti salli palautteesi käyttö suosituksena</li>
      <li>Lähetä palautteesi</li>
    </ol>
    <p><strong>Haluaisimme kuulla:</strong></p>
    <ul>
      <li>Ominaisuuksia, joita haluaisit nähdä</li>
      <li>Kohtaamiasi ongelmia</li>
      <li>Mitä pidät sivustossa</li>
      <li>Parannusehdotuksia</li>
    </ul>
    <p>Palautteesi auttaa meitä parantamaan alustaa kaikille!</p>
    """,
    display_order: 800,
    slug: "provide-feedback"
  }
]

# =============================================================================
# USER FAQs - Security
# =============================================================================

security_faqs = [
  %{
    category: "user",
    question_en: "How is my account protected?",
    question_fi: "Miten tilini on suojattu?",
    answer_en: """
    <p>We take security seriously. Your account is protected by:</p>
    <ul>
      <li><strong>Secure password hashing:</strong> Using Argon2, the industry standard</li>
      <li><strong>HTTPS encryption:</strong> All data is encrypted in transit</li>
      <li><strong>CSRF protection:</strong> Prevents cross-site request forgery</li>
      <li><strong>Rate limiting:</strong> Protects against brute-force attacks</li>
      <li><strong>Secure sessions:</strong> Auto-logout after inactivity</li>
    </ul>
    <p><strong>Best practices:</strong></p>
    <ul>
      <li>Use a unique, strong password</li>
      <li>Don't share your login credentials</li>
      <li>Log out on shared devices</li>
      <li>Report any suspicious activity</li>
    </ul>
    """,
    answer_fi: """
    <p>Otamme turvallisuuden vakavasti. Tilisi on suojattu:</p>
    <ul>
      <li><strong>Turvallinen salasanan tiivistys:</strong> Käyttäen Argon2:ta, alan standardia</li>
      <li><strong>HTTPS-salaus:</strong> Kaikki data on salattu siirron aikana</li>
      <li><strong>CSRF-suojaus:</strong> Estää sivustojen välisen pyyntöväärennöksen</li>
      <li><strong>Nopeudenrajoitus:</strong> Suojaa brute-force-hyökkäyksiltä</li>
      <li><strong>Turvalliset istunnot:</strong> Automaattinen uloskirjaus toimettomuuden jälkeen</li>
    </ul>
    <p><strong>Parhaat käytännöt:</strong></p>
    <ul>
      <li>Käytä ainutlaatuista, vahvaa salasanaa</li>
      <li>Älä jaa kirjautumistietojasi</li>
      <li>Kirjaudu ulos jaetuilla laitteilla</li>
      <li>Ilmoita epäilyttävästä toiminnasta</li>
    </ul>
    """,
    display_order: 900,
    slug: "account-security"
  }
]

# =============================================================================
# ADMIN FAQs
# =============================================================================

admin_faqs = [
  %{
    category: "admin",
    question_en: "How do I access the admin dashboard?",
    question_fi: "Miten pääsen ylläpidon kojelaudalle?",
    answer_en: """
    <p>The admin dashboard is accessible only to users with admin privileges:</p>
    <ol>
      <li>Log in with an admin account</li>
      <li>Click "Admin" in the navigation menu</li>
      <li>You'll see the admin dashboard with management options</li>
    </ol>
    <p><strong>Admin dashboard features:</strong></p>
    <ul>
      <li>User management and overview</li>
      <li>Invitation code management</li>
      <li>FAQ management</li>
      <li>Feedback review</li>
      <li>System analytics</li>
    </ul>
    <p><strong>Note:</strong> The "Admin" link only appears for users with admin role.</p>
    """,
    answer_fi: """
    <p>Ylläpidon kojelauta on saatavilla vain ylläpitäjän oikeuksilla:</p>
    <ol>
      <li>Kirjaudu ylläpitäjätilillä</li>
      <li>Klikkaa "Ylläpito" navigaatiovalikossa</li>
      <li>Näet ylläpidon kojelaudan hallintatoiminnoilla</li>
    </ol>
    <p><strong>Ylläpidon kojelaudan ominaisuudet:</strong></p>
    <ul>
      <li>Käyttäjien hallinta ja yleiskatsaus</li>
      <li>Kutsukoodien hallinta</li>
      <li>UKK:n hallinta</li>
      <li>Palautteen tarkastelu</li>
      <li>Järjestelmäanalytiikka</li>
    </ul>
    <p><strong>Huomaa:</strong> "Ylläpito"-linkki näkyy vain ylläpitäjän roolilla oleville käyttäjille.</p>
    """,
    display_order: 1000,
    slug: "admin-dashboard-access"
  },
  %{
    category: "admin",
    question_en: "How do I create and manage invitation codes?",
    question_fi: "Miten luon ja hallinnoin kutsukoodeja?",
    answer_en: """
    <p>Invitation codes control user registration. To manage them:</p>
    <h4>Creating a new code:</h4>
    <ol>
      <li>Go to Admin → Invitations</li>
      <li>Click "New Invitation"</li>
      <li>Configure options:
        <ul>
          <li><strong>Code:</strong> Auto-generated or custom (XXXX-XXXX-XXXX format)</li>
          <li><strong>Max uses:</strong> Limit how many times the code can be used</li>
          <li><strong>Expiration:</strong> Set an expiry date (optional)</li>
          <li><strong>Default role:</strong> User or admin</li>
        </ul>
      </li>
      <li>Click "Create"</li>
    </ol>
    <h4>Managing existing codes:</h4>
    <ul>
      <li>View usage statistics for each code</li>
      <li>Deactivate codes that shouldn't be used anymore</li>
      <li>Track who used each code</li>
    </ul>
    """,
    answer_fi: """
    <p>Kutsukoodit hallitsevat käyttäjien rekisteröitymistä. Hallinnoidaksesi niitä:</p>
    <h4>Uuden koodin luominen:</h4>
    <ol>
      <li>Mene Ylläpito → Kutsut</li>
      <li>Klikkaa "Uusi kutsu"</li>
      <li>Määritä asetukset:
        <ul>
          <li><strong>Koodi:</strong> Automaattisesti luotu tai mukautettu (XXXX-XXXX-XXXX-muoto)</li>
          <li><strong>Käyttökerrat:</strong> Rajoita kuinka monta kertaa koodia voi käyttää</li>
          <li><strong>Vanheneminen:</strong> Aseta vanhenemispäivä (valinnainen)</li>
          <li><strong>Oletusrooli:</strong> Käyttäjä tai ylläpitäjä</li>
        </ul>
      </li>
      <li>Klikkaa "Luo"</li>
    </ol>
    <h4>Olemassa olevien koodien hallinta:</h4>
    <ul>
      <li>Katso käyttötilastoja kullekin koodille</li>
      <li>Poista käytöstä koodit, joita ei pitäisi enää käyttää</li>
      <li>Seuraa kuka käytti mitäkin koodia</li>
    </ul>
    """,
    display_order: 1010,
    slug: "manage-invitation-codes"
  },
  %{
    category: "admin",
    question_en: "How do I manage users?",
    question_fi: "Miten hallinnoin käyttäjiä?",
    answer_en: """
    <p>User management is available in the admin dashboard:</p>
    <h4>Viewing users:</h4>
    <ol>
      <li>Go to Admin → Users</li>
      <li>Browse the user list with sorting and filtering</li>
      <li>Click a user to see their details</li>
    </ol>
    <h4>User information shown:</h4>
    <ul>
      <li>Email and username</li>
      <li>Registration date</li>
      <li>Role (user/admin)</li>
      <li>Confirmation status</li>
      <li>Post count and activity</li>
      <li>Invitation code used</li>
    </ul>
    <h4>Admin actions:</h4>
    <ul>
      <li>View user's posts and content</li>
      <li>Check user activity log</li>
      <li>Manage user role if needed</li>
    </ul>
    """,
    answer_fi: """
    <p>Käyttäjien hallinta on saatavilla ylläpidon kojelaudalla:</p>
    <h4>Käyttäjien katselu:</h4>
    <ol>
      <li>Mene Ylläpito → Käyttäjät</li>
      <li>Selaa käyttäjälistaa lajittelun ja suodatuksen avulla</li>
      <li>Klikkaa käyttäjää nähdäksesi heidän tietonsa</li>
    </ol>
    <h4>Näytettävät käyttäjätiedot:</h4>
    <ul>
      <li>Sähköposti ja käyttäjätunnus</li>
      <li>Rekisteröitymispäivä</li>
      <li>Rooli (käyttäjä/ylläpitäjä)</li>
      <li>Vahvistustila</li>
      <li>Julkaisumäärä ja aktiivisuus</li>
      <li>Käytetty kutsukoodi</li>
    </ul>
    <h4>Ylläpitotoiminnot:</h4>
    <ul>
      <li>Katso käyttäjän julkaisuja ja sisältöä</li>
      <li>Tarkista käyttäjän toimintaloki</li>
      <li>Hallitse käyttäjän roolia tarvittaessa</li>
    </ul>
    """,
    display_order: 1020,
    slug: "manage-users"
  },
  %{
    category: "admin",
    question_en: "How do I create and manage FAQs?",
    question_fi: "Miten luon ja hallinnoin UKK:ta?",
    answer_en: """
    <p>FAQs help users find answers quickly. Here's how to manage them:</p>
    <h4>Creating a FAQ:</h4>
    <ol>
      <li>Go to FAQs page as an admin</li>
      <li>Click "New FAQ"</li>
      <li>Fill in both English and Finnish versions:
        <ul>
          <li>Question (EN and FI)</li>
          <li>Answer (EN and FI) - supports HTML formatting</li>
        </ul>
      </li>
      <li>Choose category: "user" (public) or "admin" (admin-only)</li>
      <li>Set display order (lower numbers appear first)</li>
      <li>Click "Save"</li>
    </ol>
    <h4>FAQ categories:</h4>
    <ul>
      <li><strong>User FAQs:</strong> Visible to everyone on /faqs</li>
      <li><strong>Admin FAQs:</strong> Only visible to admin users</li>
    </ul>
    <h4>Tips:</h4>
    <ul>
      <li>Use HTML for formatting (lists, bold, links)</li>
      <li>Keep answers concise but complete</li>
      <li>Update FAQs when features change</li>
    </ul>
    """,
    answer_fi: """
    <p>UKK:t auttavat käyttäjiä löytämään vastauksia nopeasti. Näin hallinnoit niitä:</p>
    <h4>UKK:n luominen:</h4>
    <ol>
      <li>Mene UKK-sivulle ylläpitäjänä</li>
      <li>Klikkaa "Uusi UKK"</li>
      <li>Täytä sekä englannin- että suomenkieliset versiot:
        <ul>
          <li>Kysymys (EN ja FI)</li>
          <li>Vastaus (EN ja FI) - tukee HTML-muotoilua</li>
        </ul>
      </li>
      <li>Valitse kategoria: "user" (julkinen) tai "admin" (vain ylläpitäjät)</li>
      <li>Aseta näyttöjärjestys (pienemmät numerot näkyvät ensin)</li>
      <li>Klikkaa "Tallenna"</li>
    </ol>
    <h4>UKK-kategoriat:</h4>
    <ul>
      <li><strong>Käyttäjä-UKK:t:</strong> Näkyvät kaikille osoitteessa /faqs</li>
      <li><strong>Ylläpitäjä-UKK:t:</strong> Näkyvät vain ylläpitäjille</li>
    </ul>
    <h4>Vinkkejä:</h4>
    <ul>
      <li>Käytä HTML:ää muotoiluun (listat, lihavointi, linkit)</li>
      <li>Pidä vastaukset ytimekkäinä mutta kattavina</li>
      <li>Päivitä UKK:t kun ominaisuudet muuttuvat</li>
    </ul>
    """,
    display_order: 1030,
    slug: "manage-faqs"
  },
  %{
    category: "admin",
    question_en: "How do I review user feedback?",
    question_fi: "Miten tarkastelen käyttäjäpalautetta?",
    answer_en: """
    <p>User feedback helps improve the platform. To review it:</p>
    <ol>
      <li>Go to Admin → Feedback</li>
      <li>Browse submitted feedback entries</li>
      <li>Filter by date, rating, or testimonial status</li>
    </ol>
    <h4>Feedback information includes:</h4>
    <ul>
      <li>User's happiness rating (1-5 scale)</li>
      <li>Written feedback and suggestions</li>
      <li>Whether it's approved as a testimonial</li>
      <li>Submission date and user info</li>
    </ul>
    <h4>Managing testimonials:</h4>
    <ul>
      <li>Approve high-quality feedback as testimonials</li>
      <li>Approved testimonials may appear on the site</li>
      <li>Users must opt-in for testimonial use</li>
    </ul>
    """,
    answer_fi: """
    <p>Käyttäjäpalaute auttaa parantamaan alustaa. Tarkastellaksesi sitä:</p>
    <ol>
      <li>Mene Ylläpito → Palaute</li>
      <li>Selaa lähetettyjä palautteita</li>
      <li>Suodata päivämäärän, arvosanan tai suositustilan mukaan</li>
    </ol>
    <h4>Palautetiedot sisältävät:</h4>
    <ul>
      <li>Käyttäjän tyytyväisyysarvosana (1-5 asteikko)</li>
      <li>Kirjallinen palaute ja ehdotukset</li>
      <li>Onko hyväksytty suositukseksi</li>
      <li>Lähetyspäivä ja käyttäjätiedot</li>
    </ul>
    <h4>Suositusten hallinta:</h4>
    <ul>
      <li>Hyväksy laadukas palaute suositukseksi</li>
      <li>Hyväksytyt suositukset voivat näkyä sivustolla</li>
      <li>Käyttäjien on annettava suostumus suosituskäyttöön</li>
    </ul>
    """,
    display_order: 1040,
    slug: "review-feedback"
  },
  %{
    category: "admin",
    question_en: "How do I view system analytics?",
    question_fi: "Miten katson järjestelmäanalytiikkaa?",
    answer_en: """
    <p>System analytics provide insights into platform usage:</p>
    <h4>Available metrics:</h4>
    <ul>
      <li><strong>User statistics:</strong> Total users, new registrations, active users</li>
      <li><strong>Content metrics:</strong> Total posts, posts per user, popular tags</li>
      <li><strong>Activity logs:</strong> Recent actions, login history</li>
      <li><strong>Feed statistics:</strong> Active feeds, refresh rates, error rates</li>
      <li><strong>Search analytics:</strong> Popular search terms, search volume</li>
    </ul>
    <h4>Accessing analytics:</h4>
    <ol>
      <li>Go to Admin → Dashboard</li>
      <li>View overview statistics on the main panel</li>
      <li>Click into specific sections for detailed reports</li>
    </ol>
    <p>Analytics help identify popular content, user engagement patterns, and potential issues.</p>
    """,
    answer_fi: """
    <p>Järjestelmäanalytiikka tarjoaa näkemyksiä alustan käytöstä:</p>
    <h4>Saatavilla olevat mittarit:</h4>
    <ul>
      <li><strong>Käyttäjätilastot:</strong> Käyttäjämäärä, uudet rekisteröitymiset, aktiiviset käyttäjät</li>
      <li><strong>Sisältömittarit:</strong> Julkaisumäärä, julkaisut per käyttäjä, suositut tagit</li>
      <li><strong>Toimintalokit:</strong> Viimeaikaiset toiminnot, kirjautumishistoria</li>
      <li><strong>Syötetilastot:</strong> Aktiiviset syötteet, päivitystiheydet, virheprosentit</li>
      <li><strong>Hakuanalytiikka:</strong> Suositut hakutermit, hakumäärät</li>
    </ul>
    <h4>Analytiikan käyttö:</h4>
    <ol>
      <li>Mene Ylläpito → Kojelauta</li>
      <li>Katso yleiskatsaustilastot pääpaneelista</li>
      <li>Klikkaa tiettyihin osioihin yksityiskohtaisiin raportteihin</li>
    </ol>
    <p>Analytiikka auttaa tunnistamaan suosittua sisältöä, käyttäjien sitoutumismalleja ja mahdollisia ongelmia.</p>
    """,
    display_order: 1050,
    slug: "view-analytics"
  }
]

# =============================================================================
# Create all FAQs
# =============================================================================

all_faqs =
  getting_started_faqs ++
    blog_post_faqs ++
    tag_faqs ++
    profile_faqs ++
    rss_faqs ++
    search_faqs ++
    media_faqs ++
    feedback_faqs ++
    security_faqs ++
    admin_faqs

IO.puts("Creating #{length(all_faqs)} FAQs...\n")

results =
  Enum.map(all_faqs, fn faq_attrs ->
    case Faqs.create_faq(admin_scope, faq_attrs) do
      {:ok, faq} ->
        IO.puts("  ✅ #{faq.category}: #{String.slice(faq.question_en, 0, 50)}...")
        {:ok, faq}

      {:error, changeset} ->
        # Check if it already exists (slug conflict)
        if Keyword.has_key?(changeset.errors, :slug) do
          IO.puts("  ⏭️  Skipped (exists): #{String.slice(faq_attrs.question_en, 0, 50)}...")
          {:skipped, faq_attrs}
        else
          IO.puts("  ❌ Failed: #{String.slice(faq_attrs.question_en, 0, 50)}...")
          IO.inspect(changeset.errors, label: "    Errors")
          {:error, changeset}
        end
    end
  end)

created = Enum.count(results, fn {status, _} -> status == :ok end)
skipped = Enum.count(results, fn {status, _} -> status == :skipped end)
failed = Enum.count(results, fn {status, _} -> status == :error end)

IO.puts("\n========================================")
IO.puts("FAQ Creation Summary")
IO.puts("========================================")
IO.puts("  Created: #{created}")
IO.puts("  Skipped: #{skipped} (already exist)")
IO.puts("  Failed:  #{failed}")
IO.puts("========================================\n")

IO.puts("View FAQs at: /faqs")
IO.puts("Admin FAQs visible to admin users only\n")
