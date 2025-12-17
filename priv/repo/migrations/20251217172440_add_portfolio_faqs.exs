defmodule Homesite.Repo.Migrations.AddPortfolioFaqs do
  use Ecto.Migration

  def up do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    faqs = [
      %{
        category: "user",
        slug: "how-to-create-portfolio-project",
        display_order: 20,
        question_en: "How do I create a portfolio project?",
        question_fi: "Miten luon portfolioprojektin?",
        answer_en: """
        To create a portfolio project:

        1. Go to **Projects** in the navigation menu
        2. Click **New Project**
        3. Follow the 5-step wizard:
           - **Basics**: Name, description, and project type
           - **Metadata**: Category, date, and tags
           - **Team & Links**: Add collaborators and related links
           - **Settings**: Set visibility (public/private, portfolio)
           - **Content**: Add cover image and gallery photos

        Enable "Portfolio" in Settings to include the project in your public portfolio gallery.
        """,
        answer_fi: """
        Portfolioprojektin luominen:

        1. Siirry **Projektit**-sivulle navigaatiovalikosta
        2. Klikkaa **Uusi projekti**
        3. Seuraa 5-vaiheista ohjattua toimintoa:
           - **Perustiedot**: Nimi, kuvaus ja projektityyppi
           - **Metatiedot**: Kategoria, päivämäärä ja tagit
           - **Tiimi & linkit**: Lisää yhteistyökumppanit ja linkit
           - **Asetukset**: Aseta näkyvyys (julkinen/yksityinen, portfolio)
           - **Sisältö**: Lisää kansikuva ja galleriakuvat

        Ota "Portfolio" käyttöön asetuksissa sisällyttääksesi projektin julkiseen portfoliogalleriaan.
        """
      },
      %{
        category: "user",
        slug: "how-to-manage-project-photos",
        display_order: 21,
        question_en: "How do I add, reorder, or remove photos in a project?",
        question_fi: "Miten lisään, järjestän tai poistan kuvia projektista?",
        answer_en: """
        **Adding photos:**
        1. Edit your project and go to Step 5 (Content), or click "Skip to Content"
        2. Use the media picker to select images from your library

        **Reordering photos:**
        1. Go to your project view page (/projects/:id)
        2. Hover over any image to reveal control buttons
        3. Click **↑** to move up or **↓** to move down

        **Removing photos:**
        1. Hover over the image
        2. Click the **X** button
        3. Confirm the removal

        Note: Removing only removes the association - the image stays in your media library.
        """,
        answer_fi: """
        **Kuvien lisääminen:**
        1. Muokkaa projektia ja siirry vaiheeseen 5 (Sisältö) tai klikkaa "Siirry sisältöön"
        2. Valitse kuvat mediakirjastostasi

        **Kuvien järjestäminen:**
        1. Siirry projektin näkymään (/projects/:id)
        2. Vie hiiri kuvan päälle nähdäksesi painikkeet
        3. Klikkaa **↑** siirtääksesi ylös tai **↓** siirtääksesi alas

        **Kuvien poistaminen:**
        1. Vie hiiri kuvan päälle
        2. Klikkaa **X**-painiketta
        3. Vahvista poisto

        Huom: Poistaminen poistaa vain yhteyden - kuva säilyy mediakirjastossasi.
        """
      },
      %{
        category: "user",
        slug: "what-is-portfolio-vs-project",
        display_order: 22,
        question_en: "What is the difference between a project and a portfolio item?",
        question_fi: "Mikä ero on projektilla ja portfoliokohteella?",
        answer_en: """
        All portfolio items are projects, but not all projects are in your portfolio.

        - **Project**: A private workspace for organizing your work with media, collaborators, and metadata
        - **Portfolio item**: A project marked as "Portfolio" that appears in your public portfolio gallery

        To add a project to your portfolio:
        1. Edit the project
        2. Go to Settings (Step 4)
        3. Enable both "Public" and "Portfolio"

        This way you can have work-in-progress projects that aren't yet visible to the public.
        """,
        answer_fi: """
        Kaikki portfoliokohteet ovat projekteja, mutta kaikki projektit eivät ole portfoliossa.

        - **Projekti**: Yksityinen työtila töidesi järjestämiseen medialla, yhteistyökumppaneilla ja metatiedoilla
        - **Portfoliokohde**: Projekti, joka on merkitty "Portfolio"-tilaan ja näkyy julkisessa portfoliogalleriassasi

        Projektin lisääminen portfolioon:
        1. Muokkaa projektia
        2. Siirry asetuksiin (vaihe 4)
        3. Ota käyttöön sekä "Julkinen" että "Portfolio"

        Näin voit pitää keskeneräisiä projekteja, jotka eivät vielä näy julkisesti.
        """
      },
      %{
        category: "user",
        slug: "project-tags-shared-with-posts",
        display_order: 23,
        question_en: "Are project tags the same as blog post tags?",
        question_fi: "Ovatko projektien tagit samat kuin blogikirjoitusten tagit?",
        answer_en: """
        Yes! Projects and blog posts share the same tag system.

        - Tags you create for blog posts can be used in projects
        - Tags you create for projects can be used in blog posts
        - This helps organize all your content consistently

        When adding tags to a project, you can:
        - Search existing tags
        - Create new tags inline
        - Use public or private tags
        """,
        answer_fi: """
        Kyllä! Projektit ja blogikirjoitukset käyttävät samaa tagijärjestelmää.

        - Blogikirjoituksille luomasi tagit toimivat projekteissa
        - Projekteille luomasi tagit toimivat blogikirjoituksissa
        - Tämä auttaa järjestämään kaiken sisältösi johdonmukaisesti

        Tageja lisätessäsi projektiin voit:
        - Etsiä olemassa olevia tageja
        - Luoda uusia tageja suoraan lomakkeella
        - Käyttää julkisia tai yksityisiä tageja
        """
      }
    ]

    for faq <- faqs do
      execute("""
        INSERT INTO faqs (category, slug, display_order, question_en, question_fi, answer_en, answer_fi, is_active, metadata, inserted_at, updated_at)
        VALUES ('#{faq.category}', '#{faq.slug}', #{faq.display_order},
                '#{escape_sql(faq.question_en)}', '#{escape_sql(faq.question_fi)}',
                '#{escape_sql(faq.answer_en)}', '#{escape_sql(faq.answer_fi)}',
                true, '{}', '#{now}', '#{now}')
        ON CONFLICT (slug) DO NOTHING
      """)
    end
  end

  def down do
    execute("""
      DELETE FROM faqs WHERE slug IN (
        'how-to-create-portfolio-project',
        'how-to-manage-project-photos',
        'what-is-portfolio-vs-project',
        'project-tags-shared-with-posts'
      )
    """)
  end

  defp escape_sql(string) do
    string
    |> String.replace("'", "''")
    |> String.trim()
  end
end
