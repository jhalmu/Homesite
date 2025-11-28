defmodule Homesite.Repo.Migrations.CreateSampleFaqs do
  use Ecto.Migration
  import Ecto.Query

  def up do
    # Get the first admin user to set as creator
    admin_id =
      repo().one(
        from(u in "users",
          where: u.role == "admin",
          select: u.id,
          limit: 1
        )
      )

    # Only insert if we have an admin user
    if admin_id do
      now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

      # Sample user FAQs
      repo().insert_all("faqs", [
        # Getting Started
        %{
          category: "user",
          question_en: "How do I create my first blog post?",
          question_fi: "Miten luon ensimmäisen blogikirjoitukseni?",
          answer_en: """
          <p>After logging in, click on "Posts" in the navigation menu, then click the "New Post" button.
          Fill in your post title and content using the markdown editor. You can save as draft or publish immediately.</p>
          <p>Remember to add tags to help readers find your content!</p>
          """,
          answer_fi: """
          <p>Kirjautumisen jälkeen klikkaa "Kirjoitukset" navigointivalikossa ja sitten "Uusi kirjoitus" -nappia.
          Täytä kirjoituksen otsikko ja sisältö markdown-editorilla. Voit tallentaa luonnoksena tai julkaista heti.</p>
          <p>Muista lisätä tagit, jotta lukijat löytävät sisältösi!</p>
          """,
          display_order: 1,
          is_active: true,
          slug: "how-to-create-first-post",
          created_by_id: admin_id,
          updated_by_id: admin_id,
          inserted_at: now,
          updated_at: now
        },

        # Markdown Support
        %{
          category: "user",
          question_en: "What formatting options are available for my posts?",
          question_fi: "Mitä muotoiluvaihtoehtoja kirjoituksilleni on saatavilla?",
          answer_en: """
          <p>Posts support full Markdown formatting including:</p>
          <ul>
            <li><strong>Bold</strong> and <em>italic</em> text</li>
            <li>Headers (H1-H6)</li>
            <li>Links and images</li>
            <li>Code blocks with syntax highlighting</li>
            <li>Lists (ordered and unordered)</li>
            <li>Blockquotes</li>
          </ul>
          <p>Use the markdown syntax or toolbar buttons to format your content.</p>
          """,
          answer_fi: """
          <p>Kirjoitukset tukevat täyttä Markdown-muotoilua, mukaan lukien:</p>
          <ul>
            <li><strong>Lihavoitu</strong> ja <em>kursivoitu</em> teksti</li>
            <li>Otsikot (H1-H6)</li>
            <li>Linkit ja kuvat</li>
            <li>Koodilohkot syntaksikorostuksella</li>
            <li>Listat (numeroidut ja numeroimattomat)</li>
            <li>Lainaukset</li>
          </ul>
          <p>Käytä markdown-syntaksia tai työkalupalkin nappeja muotoillaksesi sisältöä.</p>
          """,
          display_order: 2,
          is_active: true,
          slug: "formatting-options",
          created_by_id: admin_id,
          updated_by_id: admin_id,
          inserted_at: now,
          updated_at: now
        },

        # Tags
        %{
          category: "user",
          question_en: "How do tags work?",
          question_fi: "Miten tagit toimivat?",
          answer_en: """
          <p>Tags help organize and categorize your posts. You can:</p>
          <ul>
            <li>Create tags from the Tags page</li>
            <li>Assign multiple tags to each post</li>
            <li>Use tags to filter and find related posts</li>
            <li>Each tag can have a custom color and description</li>
          </ul>
          <p>Readers can click on tags to see all posts with that tag.</p>
          """,
          answer_fi: """
          <p>Tagit auttavat organisoimaan ja luokittelemaan kirjoituksiasi. Voit:</p>
          <ul>
            <li>Luoda tageja Tagit-sivulta</li>
            <li>Liittää useita tageja jokaiseen kirjoitukseen</li>
            <li>Käyttää tageja suodattamaan ja löytämään liittyviä kirjoituksia</li>
            <li>Jokaisella tagilla voi olla oma väri ja kuvaus</li>
          </ul>
          <p>Lukijat voivat klikata tageja nähdäkseen kaikki kyseisellä tagilla merkityt kirjoitukset.</p>
          """,
          display_order: 3,
          is_active: true,
          slug: "how-tags-work",
          created_by_id: admin_id,
          updated_by_id: admin_id,
          inserted_at: now,
          updated_at: now
        },

        # Privacy
        %{
          category: "user",
          question_en: "Who can see my posts?",
          question_fi: "Kuka voi nähdä kirjoitukseni?",
          answer_en: """
          <p>Published posts are publicly visible to anyone visiting the site. Draft posts are only visible to you.</p>
          <p>You have full control over:</p>
          <ul>
            <li>When to publish (publish immediately or schedule)</li>
            <li>Keeping posts as drafts</li>
            <li>Editing or deleting published posts</li>
          </ul>
          <p>Your profile information (display name, bio, avatar) is also publicly visible.</p>
          """,
          answer_fi: """
          <p>Julkaistut kirjoitukset ovat julkisesti näkyvissä kaikille sivustolla vierailijoille. Luonnokset ovat vain sinun nähtävillä.</p>
          <p>Sinulla on täysi kontrolli:</p>
          <ul>
            <li>Julkaisuajankohta (julkaise heti tai aikatauluta)</li>
            <li>Kirjoitusten pitäminen luonnoksina</li>
            <li>Julkaistujen kirjoitusten muokkaus tai poisto</li>
          </ul>
          <p>Profiilitietosi (näyttönimi, kuvaus, avatar) ovat myös julkisesti näkyvissä.</p>
          """,
          display_order: 4,
          is_active: true,
          slug: "post-privacy",
          created_by_id: admin_id,
          updated_by_id: admin_id,
          inserted_at: now,
          updated_at: now
        },

        # RSS Feeds
        %{
          category: "user",
          question_en: "Can readers subscribe to my blog?",
          question_fi: "Voivatko lukijat tilata blogini?",
          answer_en: """
          <p>Yes! The site provides multiple subscription options:</p>
          <ul>
            <li><strong>RSS Feed</strong> - Traditional RSS format</li>
            <li><strong>Atom Feed</strong> - Alternative XML format</li>
            <li><strong>JSON Feed</strong> - Modern JSON format</li>
          </ul>
          <p>Readers can find these links in the footer and subscribe using their favorite feed reader.</p>
          """,
          answer_fi: """
          <p>Kyllä! Sivusto tarjoaa useita tilausvaihtoehtoja:</p>
          <ul>
            <li><strong>RSS-syöte</strong> - Perinteinen RSS-formaatti</li>
            <li><strong>Atom-syöte</strong> - Vaihtoehtoinen XML-formaatti</li>
            <li><strong>JSON-syöte</strong> - Moderni JSON-formaatti</li>
          </ul>
          <p>Lukijat löytävät nämä linkit sivun alatunnisteesta ja voivat tilata suosikkisyötelukijallaan.</p>
          """,
          display_order: 5,
          is_active: true,
          slug: "rss-subscription",
          created_by_id: admin_id,
          updated_by_id: admin_id,
          inserted_at: now,
          updated_at: now
        },

        # Profile Settings
        %{
          category: "user",
          question_en: "How do I customize my profile?",
          question_fi: "Miten mukautan profiiliani?",
          answer_en: """
          <p>Go to Settings to customize your profile:</p>
          <ul>
            <li><strong>Display Name</strong> - How you appear to readers</li>
            <li><strong>Avatar</strong> - Profile picture (upload an image)</li>
            <li><strong>Bio</strong> - Short description about yourself</li>
            <li><strong>Social Links</strong> - Bluesky and Mastodon handles</li>
            <li><strong>Website URL</strong> - Link to your personal site</li>
          </ul>
          <p>Remember to click "Update Profile" to save your changes!</p>
          """,
          answer_fi: """
          <p>Mene Asetuksiin mukauttaaksesi profiiliasi:</p>
          <ul>
            <li><strong>Näyttönimi</strong> - Miten näyt lukijoille</li>
            <li><strong>Avatar</strong> - Profiilikuva (lataa kuva)</li>
            <li><strong>Kuvaus</strong> - Lyhyt kuvaus itsestäsi</li>
            <li><strong>Some-linkit</strong> - Bluesky- ja Mastodon-käyttäjätunnukset</li>
            <li><strong>Verkkosivun URL</strong> - Linkki henkilökohtaiselle sivustollesi</li>
          </ul>
          <p>Muista klikata "Päivitä profiili" tallentaaksesi muutokset!</p>
          """,
          display_order: 6,
          is_active: true,
          slug: "customize-profile",
          created_by_id: admin_id,
          updated_by_id: admin_id,
          inserted_at: now,
          updated_at: now
        },

        # External Feeds
        %{
          category: "user",
          question_en: "What are External Feeds?",
          question_fi: "Mitä ovat Ulkoiset Syötteet?",
          answer_en: """
          <p>External Feeds let you aggregate content from other sources into your dashboard:</p>
          <ul>
            <li><strong>RSS/Atom Feeds</strong> - Subscribe to any blog or news site</li>
            <li><strong>JSON Feeds</strong> - Modern feed format support</li>
            <li><strong>Bluesky</strong> - Coming soon</li>
            <li><strong>Mastodon</strong> - Coming soon</li>
          </ul>
          <p>View all your feeds in one place and stay updated with content you care about.</p>
          """,
          answer_fi: """
          <p>Ulkoiset Syötteet mahdollistavat sisällön kokoamisen muista lähteistä kojelaudallesi:</p>
          <ul>
            <li><strong>RSS/Atom-syötteet</strong> - Tilaa mikä tahansa blogi tai uutissivusto</li>
            <li><strong>JSON-syötteet</strong> - Modernin syöteformaatin tuki</li>
            <li><strong>Bluesky</strong> - Tulossa pian</li>
            <li><strong>Mastodon</strong> - Tulossa pian</li>
          </ul>
          <p>Katso kaikki syötteesi yhdestä paikasta ja pysy ajan tasalla sinua kiinnostavasta sisällöstä.</p>
          """,
          display_order: 7,
          is_active: true,
          slug: "external-feeds",
          created_by_id: admin_id,
          updated_by_id: admin_id,
          inserted_at: now,
          updated_at: now
        }
      ])
    end
  end

  def down do
    # Remove sample FAQs
    repo().delete_all(
      from(f in "faqs",
        where:
          f.slug in [
            "how-to-create-first-post",
            "formatting-options",
            "how-tags-work",
            "post-privacy",
            "rss-subscription",
            "customize-profile",
            "external-feeds"
          ]
      )
    )
  end
end
