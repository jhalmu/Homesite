# Comprehensive FAQs - Admin, User, and Public Visitor
# Run with: mix run priv/repo/seeds/comprehensive_user_admin_faqs.exs
#
# Created: 2026-02-04
# Covers three audiences:
# - Admin FAQs (category: "admin") - Permission system, user management
# - User FAQs (category: "user") - Getting started, content, feeds
# - Public FAQs (category: "user", but basic questions) - About site, subscribing

import Ecto.Query

alias Homesite.Repo
alias Homesite.Accounts
alias Homesite.Faqs

# Get existing admin user
admin_user =
  Repo.one(from u in Accounts.User, where: u.role == "admin", limit: 1) ||
    raise "No admin user found. Run seeds.exs first."

admin_scope = Accounts.Scope.for_user(admin_user)

IO.puts("\n=== Creating Comprehensive FAQs ===\n")

# =============================================================================
# ADMIN FAQs - Permission System & User Management
# =============================================================================

admin_faqs = [
  # Permission System
  %{
    category: "admin",
    question_en: "How does the admin permission system work?",
    question_fi: "Miten ylläpitäjän käyttöoikeusjärjestelmä toimii?",
    answer_en: """
    The system uses two levels: **Role** (user/admin) controls access to admin sections, while **Flowers** (🌸) determine what actions an admin can perform.

    Regular users have no admin access. Admins with 1 flower can view the dashboard. Higher flower counts unlock more powerful actions like user management (3+ flowers) and system settings (5 flowers).

    This two-tier approach allows flexible permission delegation without creating complex role hierarchies.
    """,
    answer_fi: """
    Järjestelmä käyttää kahta tasoa: **Rooli** (käyttäjä/ylläpitäjä) ohjaa pääsyä ylläpito-osioihin, kun taas **Kukat** (🌸) määrittävät, mitä toimintoja ylläpitäjä voi suorittaa.

    Tavallisilla käyttäjillä ei ole ylläpito-oikeuksia. Yhden kukan ylläpitäjät voivat tarkastella hallintapaneelia. Korkeammat kukkamäärät avaavat tehokkaampia toimintoja, kuten käyttäjähallinnan (3+ kukkaa) ja järjestelmäasetukset (5 kukkaa).

    Tämä kaksitasoinen lähestymistapa mahdollistaa joustavan oikeuksien delegoinnin ilman monimutkaisia roolihierarkioita.
    """,
    display_order: 2000,
    slug: "admin-permission-system"
  },
  %{
    category: "admin",
    question_en: "What can each flower level do?",
    question_fi: "Mitä kukin kukkataso voi tehdä?",
    answer_en: """
    Flower levels grant progressively more permissions:

    - 🌸 (1 flower): View admin dashboard and site statistics
    - 🌸🌸 (2 flowers): Manage FAQs and basic content moderation
    - 🌸🌸🌸 (3 flowers): User management - suspend, ban, and delete users
    - 🌸🌸🌸🌸 (4 flowers): Promote users to admin, assign flower levels
    - 🌸🌸🌸🌸🌸 (5 flowers): Full access - system settings, can modify other 5-flower admins

    You can only assign flower levels equal to or lower than your own level.
    """,
    answer_fi: """
    Kukkatasot myöntävät asteittain enemmän oikeuksia:

    - 🌸 (1 kukka): Tarkastele hallintapaneelia ja sivuston tilastoja
    - 🌸🌸 (2 kukkaa): Hallitse UKK:ta ja perusmoderointi
    - 🌸🌸🌸 (3 kukkaa): Käyttäjähallinta - keskeytä, estä ja poista käyttäjiä
    - 🌸🌸🌸🌸 (4 kukkaa): Ylennä käyttäjiä ylläpitäjiksi, määritä kukkatasot
    - 🌸🌸🌸🌸🌸 (5 kukkaa): Täysi pääsy - järjestelmäasetukset, voi muokata muita 5-kukan ylläpitäjiä

    Voit määrittää vain oman tasosi verran tai vähemmän kukkia.
    """,
    display_order: 2010,
    slug: "admin-flower-levels"
  },
  %{
    category: "admin",
    question_en: "How do I promote someone to admin?",
    question_fi: "Miten ylennän jonkun ylläpitäjäksi?",
    answer_en: """
    1. Go to **Admin → User Management** (/admin/users)
    2. Find the user using search or filters
    3. Click the **"Promote to Admin"** button in their row
    4. Select the initial flower level (1-5)
    5. Confirm the promotion

    The user immediately gains admin access. You can only assign flower levels equal to or lower than your own. A 3-flower admin cannot create a 4-flower admin.

    All promotions are logged for audit purposes.
    """,
    answer_fi: """
    1. Siirry kohtaan **Ylläpito → Käyttäjähallinta** (/admin/users)
    2. Etsi käyttäjä haun tai suodattimien avulla
    3. Klikkaa **"Ylennä ylläpitäjäksi"** -painiketta hänen riviltään
    4. Valitse alkuperäinen kukkataso (1-5)
    5. Vahvista ylennys

    Käyttäjä saa välittömästi ylläpito-oikeudet. Voit määrittää vain oman tasosi verran tai vähemmän kukkia. 3-kukan ylläpitäjä ei voi luoda 4-kukan ylläpitäjää.

    Kaikki ylennykset kirjataan tarkastusta varten.
    """,
    display_order: 2020,
    slug: "admin-promote-user"
  },
  # User Management
  %{
    category: "admin",
    question_en: "How do I ban a user?",
    question_fi: "Miten estän käyttäjän?",
    answer_en: """
    1. Go to **Admin → User Management** (/admin/users)
    2. Find the user and click the **"Ban"** button
    3. Enter a reason (required) - this is shown to the user
    4. Optionally set an expiry date for temporary bans
    5. Confirm the action

    Banned users:
    - Cannot log in
    - See a message explaining they're banned with the reason
    - Remain banned until manually unbanned (unless expiry set)

    You need 3+ flowers to ban users. All bans are logged with timestamp, reason, and who issued them.
    """,
    answer_fi: """
    1. Siirry kohtaan **Ylläpito → Käyttäjähallinta** (/admin/users)
    2. Etsi käyttäjä ja klikkaa **"Estä"** -painiketta
    3. Syötä syy (pakollinen) - tämä näytetään käyttäjälle
    4. Valinnaisesti aseta vanhenemispäivä väliaikaisille estoille
    5. Vahvista toiminto

    Estetyt käyttäjät:
    - Eivät voi kirjautua sisään
    - Näkevät viestin, jossa kerrotaan esto ja syy
    - Pysyvät estettyinä, kunnes esto poistetaan manuaalisesti (ellei vanhenemista asetettu)

    Tarvitset 3+ kukkaa käyttäjien estämiseen. Kaikki estot kirjataan aikaleimalla, syyllä ja tekijällä.
    """,
    display_order: 2030,
    slug: "admin-ban-user"
  },
  %{
    category: "admin",
    question_en: "What's the difference between banning and suspending?",
    question_fi: "Mikä on ero estämisen ja keskeyttämisen välillä?",
    answer_en: """
    **Suspension** is temporary and automatic:
    - User regains access after the expiry date
    - Good for cooling-off periods or warnings
    - Self-resolving - no admin action needed to lift

    **Banning** is permanent:
    - User cannot log in until manually unbanned
    - Good for serious or repeated violations
    - Requires admin action to remove

    Both prevent login and are logged. Choose suspension for first offenses or minor issues. Choose banning for serious violations or repeat offenders.
    """,
    answer_fi: """
    **Keskeytys** on väliaikainen ja automaattinen:
    - Käyttäjä saa pääsyn takaisin vanhenemispäivän jälkeen
    - Hyvä rauhoittumisjaksoille tai varoituksille
    - Itsestään ratkeava - ylläpitotoimia ei tarvita poistamiseen

    **Esto** on pysyvä:
    - Käyttäjä ei voi kirjautua ennen kuin esto poistetaan manuaalisesti
    - Hyvä vakaviin tai toistuviin rikkomuksiin
    - Vaatii ylläpitotoimia poistamiseen

    Molemmat estävät kirjautumisen ja kirjataan. Valitse keskeytys ensimmäisiin rikkomuksiin tai pieniin ongelmiin. Valitse esto vakaviin rikkomuksiin tai toistuviin rikkojiin.
    """,
    display_order: 2040,
    slug: "admin-ban-vs-suspend"
  },
  %{
    category: "admin",
    question_en: "How do I delete a user account?",
    question_fi: "Miten poistan käyttäjätilin?",
    answer_en: """
    1. Go to **Admin → User Management** (/admin/users)
    2. Find the user and click **"Delete"**
    3. Choose the deletion type:

    **Full delete**: Removes the user AND all their content (posts, comments). Use when content should not remain. Cannot be undone.

    **Keep content**: Removes the user account but preserves their posts, attributed to "Deleted User". Use when content has community value.

    Both options require password confirmation and are logged for audit purposes. You need 3+ flowers to delete users.
    """,
    answer_fi: """
    1. Siirry kohtaan **Ylläpito → Käyttäjähallinta** (/admin/users)
    2. Etsi käyttäjä ja klikkaa **"Poista"**
    3. Valitse poiston tyyppi:

    **Täysi poisto**: Poistaa käyttäjän JA kaiken hänen sisältönsä (artikkelit, kommentit). Käytä kun sisältöä ei pitäisi säilyttää. Ei voi peruuttaa.

    **Säilytä sisältö**: Poistaa käyttäjätilin mutta säilyttää artikkelit "Poistettu käyttäjä" -nimellä. Käytä kun sisällöllä on yhteisöllistä arvoa.

    Molemmat vaihtoehdot vaativat salasanan vahvistuksen ja kirjataan tarkastusta varten. Tarvitset 3+ kukkaa käyttäjien poistamiseen.
    """,
    display_order: 2050,
    slug: "admin-delete-user"
  },
  %{
    category: "admin",
    question_en: "How do I reactivate a suspended or banned user?",
    question_fi: "Miten palautan keskeytetyn tai estetyn käyttäjän?",
    answer_en: """
    1. Go to **Admin → User Management** (/admin/users)
    2. Use the status filter to show "Suspended" or "Banned" users
    3. Find the user - their status badge shows yellow (suspended) or red (banned)
    4. Click **"Reactivate"** or **"Unban"**
    5. Confirm the action

    The user can immediately log in again. All status changes are logged with who made the change and when.

    You can also view suspension/ban history in the user's detail page.
    """,
    answer_fi: """
    1. Siirry kohtaan **Ylläpito → Käyttäjähallinta** (/admin/users)
    2. Käytä tilasuodatinta näyttämään "Keskeytetyt" tai "Estetyt" käyttäjät
    3. Etsi käyttäjä - heidän tilamerkkinsä näyttää keltaista (keskeytetty) tai punaista (estetty)
    4. Klikkaa **"Palauta"** tai **"Poista esto"**
    5. Vahvista toiminto

    Käyttäjä voi kirjautua sisään välittömästi. Kaikki tilamuutokset kirjataan: kuka teki muutoksen ja milloin.

    Voit myös tarkastella keskeytys-/estohistoriaa käyttäjän tietosivulla.
    """,
    display_order: 2060,
    slug: "admin-reactivate-user"
  }
]

# =============================================================================
# USER FAQs - Getting Started & Features
# =============================================================================

user_faqs = [
  # Getting Started
  %{
    category: "user",
    question_en: "How do I write a blog post?",
    question_fi: "Miten kirjoitan blogiartikkelin?",
    answer_en: """
    1. Click **"New Post"** from your dashboard or go to /posts/new
    2. Enter a title - the URL slug is generated automatically
    3. Write your content using **Markdown**:
       - Use `#` for headings, `**bold**`, `*italic*`
       - Add code blocks with triple backticks
       - Insert images with `![alt text](url)`
    4. Add **tags** to help readers find your post
    5. Choose to **Save as draft** or **Publish** immediately

    Published posts appear on the home page and in your RSS feed. You can edit posts anytime.
    """,
    answer_fi: """
    1. Klikkaa **"Uusi artikkeli"** hallintapaneelista tai siirry osoitteeseen /posts/new
    2. Syötä otsikko - URL-tunnus luodaan automaattisesti
    3. Kirjoita sisältösi käyttäen **Markdownia**:
       - Käytä `#` otsikoille, `**lihavoitu**`, `*kursiivi*`
       - Lisää koodilohkoja kolmella heittomerkillä
       - Lisää kuvia muodossa `![vaihtoehtoinen teksti](url)`
    4. Lisää **tunnisteita** auttamaan lukijoita löytämään artikkelisi
    5. Valitse **Tallenna luonnokseksi** tai **Julkaise** heti

    Julkaistut artikkelit näkyvät etusivulla ja RSS-syötteessäsi. Voit muokata artikkeleita milloin tahansa.
    """,
    display_order: 1200,
    slug: "how-to-write-post"
  },
  %{
    category: "user",
    question_en: "How do I set up my profile?",
    question_fi: "Miten määritän profiilini?",
    answer_en: """
    Go to **Settings** (click your avatar → Settings) to customize:

    - **Display name**: Your public name shown on posts and comments
    - **Username**: Creates a memorable URL like /users/@yourname
    - **Bio**: A short description about yourself (max 500 characters)
    - **Avatar**: Upload an image (JPG/PNG, max 5MB) or use the auto-generated one
    - **Website URL**: Link to your personal website
    - **Social links**: Your Bluesky and Mastodon handles

    Changes save automatically when you click "Save Changes".
    """,
    answer_fi: """
    Siirry **Asetuksiin** (klikkaa avatariasi → Asetukset) mukauttaaksesi:

    - **Näyttönimi**: Julkinen nimesi artikkeleissa ja kommenteissa
    - **Käyttäjätunnus**: Luo muistettavan URL:n kuten /users/@nimesi
    - **Kuvaus**: Lyhyt kuvaus itsestäsi (max 500 merkkiä)
    - **Avatar**: Lataa kuva (JPG/PNG, max 5MB) tai käytä automaattisesti luotua
    - **Verkkosivun URL**: Linkki henkilökohtaiselle verkkosivullesi
    - **Sosiaalisen median linkit**: Bluesky- ja Mastodon-tunnuksesi

    Muutokset tallentuvat kun klikkaat "Tallenna muutokset".
    """,
    display_order: 1210,
    slug: "how-to-setup-profile"
  },
  %{
    category: "user",
    question_en: "What is a username and do I need one?",
    question_fi: "Mikä on käyttäjätunnus ja tarvitsenko sellaisen?",
    answer_en: """
    A **username** gives you a memorable profile URL:
    - With username: `/users/@johndoe`
    - Without username: `/users/123`

    **It's optional** but recommended if you share your profile or want a professional presence.

    **Requirements:**
    - 3-30 characters long
    - Must start with a lowercase letter
    - Only lowercase letters, numbers, and underscores
    - Some names are reserved (admin, api, help, etc.)

    Set your username in Settings. You can change it later, but old URLs will stop working.
    """,
    answer_fi: """
    **Käyttäjätunnus** antaa sinulle muistettavan profiilin URL:n:
    - Käyttäjätunnuksella: `/users/@johndoe`
    - Ilman käyttäjätunnusta: `/users/123`

    **Se on valinnainen**, mutta suositeltava jos jaat profiiliasi tai haluat ammattimaisen läsnäolon.

    **Vaatimukset:**
    - 3-30 merkkiä pitkä
    - Täytyy alkaa pienellä kirjaimella
    - Vain pienet kirjaimet, numerot ja alaviivat
    - Jotkut nimet on varattu (admin, api, help, jne.)

    Aseta käyttäjätunnuksesi Asetuksissa. Voit vaihtaa sen myöhemmin, mutta vanhat URL:t lakkaavat toimimasta.
    """,
    display_order: 1220,
    slug: "what-is-username"
  },
  %{
    category: "user",
    question_en: "How do I subscribe to other authors?",
    question_fi: "Miten tilaan muiden kirjoittajien sisältöä?",
    answer_en: """
    Each author has **RSS/Atom/JSON feeds** you can subscribe to:

    1. Visit the author's profile page
    2. Look for the **"Subscribe"** section with feed links
    3. Copy the feed URL you prefer:
       - RSS: `/users/@username/rss.xml`
       - Atom: `/users/@username/feed.xml`
       - JSON: `/users/@username/feed.json`
    4. Paste into your feed reader

    **Popular feed readers:** Feedly, NetNewsWire, Inoreader, Feedbin, Miniflux

    You'll receive new posts automatically in your reader.
    """,
    answer_fi: """
    Jokaisella kirjoittajalla on **RSS/Atom/JSON-syötteet**, joita voit tilata:

    1. Käy kirjoittajan profiilisivulla
    2. Etsi **"Tilaa"** -osio syötelinkeillä
    3. Kopioi haluamasi syötteen URL:
       - RSS: `/users/@käyttäjätunnus/rss.xml`
       - Atom: `/users/@käyttäjätunnus/feed.xml`
       - JSON: `/users/@käyttäjätunnus/feed.json`
    4. Liitä syötteenlukijaasi

    **Suosittuja syötteenlukijoita:** Feedly, NetNewsWire, Inoreader, Feedbin, Miniflux

    Saat uudet artikkelit automaattisesti lukijaasi.
    """,
    display_order: 1230,
    slug: "how-to-subscribe-authors"
  },
  # Content & Feeds
  %{
    category: "user",
    question_en: "How do tags work?",
    question_fi: "Miten tunnisteet toimivat?",
    answer_en: """
    **Tags** help organize and discover content:

    - Add relevant tags when creating a post (e.g., "elixir", "tutorial", "photography")
    - Readers can click tags to find all related posts
    - You can create new tags or use existing ones
    - Each post can have multiple tags

    **Best practices:**
    - Keep tags lowercase and descriptive
    - Use existing tags when possible for better discoverability
    - Don't over-tag - 3-5 relevant tags is usually enough
    """,
    answer_fi: """
    **Tunnisteet** auttavat järjestämään ja löytämään sisältöä:

    - Lisää asiaankuuluvat tunnisteet artikkelia luodessasi (esim. "elixir", "opas", "valokuvaus")
    - Lukijat voivat klikata tunnisteita löytääkseen kaikki liittyvät artikkelit
    - Voit luoda uusia tunnisteita tai käyttää olemassa olevia
    - Jokaisella artikkelilla voi olla useita tunnisteita

    **Parhaat käytännöt:**
    - Pidä tunnisteet pieninä kirjaimina ja kuvaavina
    - Käytä olemassa olevia tunnisteita mahdollisuuksien mukaan paremman löydettävyyden vuoksi
    - Älä käytä liikaa tunnisteita - 3-5 asiaankuuluvaa tunnistetta riittää yleensä
    """,
    display_order: 1240,
    slug: "how-tags-work"
  },
  %{
    category: "user",
    question_en: "How do I save a post as draft?",
    question_fi: "Miten tallennan artikkelin luonnokseksi?",
    answer_en: """
    When creating or editing a post:

    1. Leave the **"Published"** checkbox unchecked, OR
    2. Set no publication date

    **Drafts are:**
    - Only visible to you
    - Shown in your post list with a "Draft" badge
    - Not included in RSS feeds or search results

    **To publish a draft:**
    1. Edit the post
    2. Check "Published" or set a publication date
    3. Save changes

    **Tip:** Setting a future publication date schedules automatic publishing.
    """,
    answer_fi: """
    Artikkelia luodessasi tai muokatessasi:

    1. Jätä **"Julkaistu"** -valintaruutu tyhjäksi, TAI
    2. Älä aseta julkaisupäivää

    **Luonnokset ovat:**
    - Vain sinulle näkyviä
    - Näkyvät artikkeliluettelossasi "Luonnos"-merkinnällä
    - Eivät sisälly RSS-syötteisiin tai hakutuloksiin

    **Luonnoksen julkaiseminen:**
    1. Muokkaa artikkelia
    2. Valitse "Julkaistu" tai aseta julkaisupäivä
    3. Tallenna muutokset

    **Vinkki:** Tulevan julkaisupäivän asettaminen ajastaa automaattisen julkaisun.
    """,
    display_order: 1250,
    slug: "how-to-save-draft"
  },
  %{
    category: "user",
    question_en: "How do I add external feeds to my reading list?",
    question_fi: "Miten lisään ulkoisia syötteitä lukulistalleni?",
    answer_en: """
    1. Go to **/feeds** and click **"New Feed Source"**
    2. Choose the feed type:
       - **RSS/Atom**: Enter the feed URL directly
       - **Mastodon**: Enter username like `@user@instance.social`
       - **Bluesky**: Enter handle like `user.bsky.social`
       - **YouTube**: Enter channel URL
    3. Give it a name and set refresh interval (30-60 min recommended)
    4. Click **Save**

    New items appear in your unified feed at /feed. The system fetches content automatically based on your refresh interval.
    """,
    answer_fi: """
    1. Siirry osoitteeseen **/feeds** ja klikkaa **"Uusi syötelähde"**
    2. Valitse syötetyyppi:
       - **RSS/Atom**: Syötä syötteen URL suoraan
       - **Mastodon**: Syötä käyttäjätunnus muodossa `@user@instance.social`
       - **Bluesky**: Syötä tunnus muodossa `user.bsky.social`
       - **YouTube**: Syötä kanavan URL
    3. Anna sille nimi ja aseta päivitysväli (30-60 min suositeltava)
    4. Klikkaa **Tallenna**

    Uudet kohteet näkyvät yhdistetyssä syötteessäsi osoitteessa /feed. Järjestelmä hakee sisältöä automaattisesti päivitysvälin mukaan.
    """,
    display_order: 1260,
    slug: "how-to-add-external-feeds"
  },
  %{
    category: "user",
    question_en: "How do I organize my feeds into folders?",
    question_fi: "Miten järjestän syötteeni kansioihin?",
    answer_en: """
    1. In **/feeds**, click **"New Folder"**
    2. Give the folder a name (e.g., "Tech News", "Friends", "Work")
    3. Optionally choose an icon and color
    4. Save the folder

    **To assign feeds to folders:**
    - When adding a new feed, select the folder
    - Or edit an existing feed and change its folder

    **Using folders:**
    - Click a folder name to filter and view only feeds from that category
    - Use "All" to see everything
    - Folders help manage many subscriptions without overwhelm
    """,
    answer_fi: """
    1. Osoitteessa **/feeds**, klikkaa **"Uusi kansio"**
    2. Anna kansiolle nimi (esim. "Teknologiauutiset", "Ystävät", "Työ")
    3. Valinnaisesti valitse kuvake ja väri
    4. Tallenna kansio

    **Syötteiden lisääminen kansioihin:**
    - Uutta syötettä lisätessäsi valitse kansio
    - Tai muokkaa olemassa olevaa syötettä ja vaihda sen kansiota

    **Kansioiden käyttö:**
    - Klikkaa kansion nimeä suodattaaksesi ja nähdäksesi vain sen kategorian syötteet
    - Käytä "Kaikki" nähdäksesi kaiken
    - Kansiot auttavat hallitsemaan monia tilauksia ilman ylikuormitusta
    """,
    display_order: 1270,
    slug: "how-to-organize-feeds-folders"
  }
]

# =============================================================================
# PUBLIC VISITOR FAQs - About Site & Subscribing
# =============================================================================

public_faqs = [
  %{
    category: "user",
    question_en: "What is this site?",
    question_fi: "Mikä tämä sivusto on?",
    answer_en: """
    This is **Juha Halmu's personal blog and portfolio**. Here you'll find:

    - **Blog posts** on various topics including technology, photography, and life
    - **Portfolio** showcasing projects and creative work
    - **Curated content** from around the web via integrated feeds

    The site is built with **Phoenix LiveView** and **Elixir**, and is open source. It supports multiple languages (Finnish and English) and offers RSS feeds for easy subscription.
    """,
    answer_fi: """
    Tämä on **Juha Halmun henkilökohtainen blogi ja portfolio**. Täältä löydät:

    - **Blogiartikkeleita** eri aiheista, mukaan lukien teknologia, valokuvaus ja elämä
    - **Portfolion** joka esittelee projekteja ja luovaa työtä
    - **Kuratoitua sisältöä** ympäri verkkoa integroitujen syötteiden kautta

    Sivusto on rakennettu **Phoenix LiveView**:llä ja **Elixirillä**, ja se on avointa lähdekoodia. Se tukee useita kieliä (suomi ja englanti) ja tarjoaa RSS-syötteet helppoon tilaamiseen.
    """,
    display_order: 1000,
    slug: "what-is-this-site"
  },
  %{
    category: "user",
    question_en: "Do I need an account to read content?",
    question_fi: "Tarvitsenko tilin sisällön lukemiseen?",
    answer_en: """
    **No, you don't need an account to read.**

    All published content is freely accessible:
    - Blog posts and articles
    - Portfolio and project galleries
    - Public FAQs and help pages

    **An account is only needed if you want to:**
    - Write and publish your own posts
    - Subscribe to external feeds (RSS aggregation)
    - Use the real-time chat feature
    - Customize your reading experience
    """,
    answer_fi: """
    **Ei, et tarvitse tiliä lukemiseen.**

    Kaikki julkaistu sisältö on vapaasti saatavilla:
    - Blogiartikkelit ja kirjoitukset
    - Portfolio ja projektit
    - Julkiset UKK:t ja ohjeet

    **Tiliä tarvitaan vain jos haluat:**
    - Kirjoittaa ja julkaista omia artikkeleita
    - Tilata ulkoisia syötteitä (RSS-aggregointi)
    - Käyttää reaaliaikaista chat-toimintoa
    - Mukauttaa lukukokemustasi
    """,
    display_order: 1010,
    slug: "do-i-need-account"
  },
  %{
    category: "user",
    question_en: "How do I subscribe to new posts without an account?",
    question_fi: "Miten tilaan uudet artikkelit ilman tiliä?",
    answer_en: """
    Use **RSS, Atom, or JSON feeds** with any feed reader app:

    1. Find feed links in the **footer** or on author profile pages
    2. Copy the feed URL:
       - RSS: `/users/@username/rss.xml`
       - Atom: `/users/@username/feed.xml`
       - JSON: `/users/@username/feed.json`
    3. Paste into your feed reader

    **Popular free feed readers:**
    - **Feedly** (web, iOS, Android)
    - **NetNewsWire** (macOS, iOS - free & open source)
    - **Inoreader** (web, mobile)
    - **Feedbin** (web, paid)

    You'll receive new posts automatically - no account needed!
    """,
    answer_fi: """
    Käytä **RSS-, Atom- tai JSON-syötteitä** millä tahansa syötteenlukijasovelluksella:

    1. Löydä syötelinkit **alatunnisteesta** tai kirjoittajien profiilisivuilta
    2. Kopioi syötteen URL:
       - RSS: `/users/@käyttäjätunnus/rss.xml`
       - Atom: `/users/@käyttäjätunnus/feed.xml`
       - JSON: `/users/@käyttäjätunnus/feed.json`
    3. Liitä syötteenlukijaasi

    **Suosittuja ilmaisia syötteenlukijoita:**
    - **Feedly** (web, iOS, Android)
    - **NetNewsWire** (macOS, iOS - ilmainen ja avointa lähdekoodia)
    - **Inoreader** (web, mobiili)
    - **Feedbin** (web, maksullinen)

    Saat uudet artikkelit automaattisesti - tiliä ei tarvita!
    """,
    display_order: 1020,
    slug: "how-to-subscribe-without-account"
  },
  %{
    category: "user",
    question_en: "How do I contact the site owner?",
    question_fi: "Miten otan yhteyttä sivuston omistajaan?",
    answer_en: """
    You can reach the site owner through several channels:

    1. **Check the footer** for contact links and social media profiles
    2. **Visit author profile pages** for individual social links:
       - Bluesky
       - Mastodon
       - Personal website
    3. **Email** - look for the email link in the footer or about page

    Response times vary, but social media (Bluesky/Mastodon) often gets the quickest response.
    """,
    answer_fi: """
    Voit tavoittaa sivuston omistajan useilla tavoilla:

    1. **Tarkista alatunniste** yhteystiedoille ja sosiaalisen median profiileille
    2. **Käy kirjoittajien profiilisivuilla** yksittäisille sosiaalisen median linkeille:
       - Bluesky
       - Mastodon
       - Henkilökohtainen verkkosivusto
    3. **Sähköposti** - etsi sähköpostilinkki alatunnisteesta tai tietoja-sivulta

    Vastausajat vaihtelevat, mutta sosiaalinen media (Bluesky/Mastodon) saa usein nopeimman vastauksen.
    """,
    display_order: 1030,
    slug: "how-to-contact-owner"
  },
  %{
    category: "user",
    question_en: "How do I get an account?",
    question_fi: "Miten saan tilin?",
    answer_en: """
    **Registration is invitation-only** to keep the community intentional and spam-free.

    **To get an account:**
    1. Ask someone who already has an account for an invitation code
    2. Go to **/users/register**
    3. Enter the invitation code (format: `XXXX-XXXX-XXXX`)
    4. Complete registration with your email and password

    **Why invitation-only?**
    - Prevents spam and bot accounts
    - Builds a trusted community
    - Each member can vouch for who they invite

    If you don't know anyone with an account, check the contact options to reach out to the site owner.
    """,
    answer_fi: """
    **Rekisteröityminen on vain kutsulla** pitääksemme yhteisön tarkoituksellisena ja roskapostittomana.

    **Tilin saaminen:**
    1. Pyydä kutsukoodia joltakulta, jolla on jo tili
    2. Siirry osoitteeseen **/users/register**
    3. Syötä kutsukoodi (muoto: `XXXX-XXXX-XXXX`)
    4. Täytä rekisteröityminen sähköpostillasi ja salasanallasi

    **Miksi vain kutsulla?**
    - Estää roskapostia ja bottitilien
    - Rakentaa luotetun yhteisön
    - Jokainen jäsen voi taata kutsumansa henkilön

    Jos et tunne ketään, jolla on tili, tarkista yhteystiedot ottaaksesi yhteyttä sivuston omistajaan.
    """,
    display_order: 1040,
    slug: "how-to-get-account"
  }
]

# =============================================================================
# CREATE ALL FAQs
# =============================================================================

create_faq_if_not_exists = fn faq_attrs, scope ->
  case Faqs.create_faq(scope, faq_attrs) do
    {:ok, faq} ->
      IO.puts("  ✅ Created: #{String.slice(faq_attrs.question_en, 0, 50)}...")
      :created

    {:error, changeset} ->
      if Keyword.has_key?(changeset.errors, :slug) do
        IO.puts("  ⏭️  Exists: #{String.slice(faq_attrs.question_en, 0, 50)}...")
        :skipped
      else
        IO.puts("  ❌ Failed: #{String.slice(faq_attrs.question_en, 0, 50)}...")
        IO.inspect(changeset.errors, label: "    Errors")
        :failed
      end
  end
end

IO.puts("Creating Admin FAQs...")
admin_results = Enum.map(admin_faqs, &create_faq_if_not_exists.(&1, admin_scope))

IO.puts("\nCreating User FAQs...")
user_results = Enum.map(user_faqs, &create_faq_if_not_exists.(&1, admin_scope))

IO.puts("\nCreating Public Visitor FAQs...")
public_results = Enum.map(public_faqs, &create_faq_if_not_exists.(&1, admin_scope))

all_results = admin_results ++ user_results ++ public_results
created = Enum.count(all_results, &(&1 == :created))
skipped = Enum.count(all_results, &(&1 == :skipped))
failed = Enum.count(all_results, &(&1 == :failed))

IO.puts("\n=== FAQ Creation Summary ===")
IO.puts("  Admin FAQs:  #{length(admin_faqs)}")
IO.puts("  User FAQs:   #{length(user_faqs)}")
IO.puts("  Public FAQs: #{length(public_faqs)}")
IO.puts("  ─────────────────────")
IO.puts("  Created: #{created}")
IO.puts("  Skipped: #{skipped} (already exist)")
IO.puts("  Failed:  #{failed}")
IO.puts("")
