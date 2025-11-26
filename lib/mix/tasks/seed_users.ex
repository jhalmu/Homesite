defmodule Mix.Tasks.SeedUsers do
  @moduledoc """
  Seeds the database with users, articles, and tags for testing.

  Creates 10 users (5 English, 5 Finnish), each with:
  - 30 long public articles
  - 10 tags (5 unique to the user, 5 common across all users)
  - 3-5 random tags per article

  ## Usage

      mix seed.users

  ## Options

      --clean  Delete all existing users, posts, and tags before seeding (DESTRUCTIVE!)

  ## Examples

      # Seed with test data
      mix seed.users

      # Clean database and reseed
      mix seed.users --clean

  ## Warning

  This task creates a significant amount of data (300 total posts, 100+ tags).
  Use the --clean flag carefully as it will DELETE ALL existing data!
  """

  use Mix.Task
  import Ecto.Query
  alias Homesite.{Accounts, Content, Repo}
  alias Homesite.Accounts.{User, Scope}
  alias Homesite.Content.{Post, Tag, PostTag}

  @shortdoc "Seeds users with articles and tags for testing"

  # Common tags shared across all users
  @common_tags_en [
    "Technology",
    "Lifestyle",
    "Tutorial",
    "Opinion",
    "News"
  ]

  @common_tags_fi [
    "Teknologia",
    "Elämäntapa",
    "Opas",
    "Mielipide",
    "Uutiset"
  ]

  # User-specific unique tags (will be combined with user number)
  @unique_tag_templates_en [
    "Personal",
    "Journey",
    "Thoughts",
    "Experience",
    "Project"
  ]

  @unique_tag_templates_fi [
    "Henkilökohtainen",
    "Matka",
    "Ajatuksia",
    "Kokemus",
    "Projekti"
  ]

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _, _} = OptionParser.parse(args, strict: [clean: :boolean])

    if Keyword.get(opts, :clean, false) do
      clean_database()
    end

    Mix.shell().info("\n🌱 Starting seed process...\n")

    # Create English users
    english_users = create_users(5, "en")
    Mix.shell().info("✅ Created 5 English users")

    # Create Finnish users
    finnish_users = create_users(5, "fi")
    Mix.shell().info("✅ Created 5 Finnish users")

    all_users = english_users ++ finnish_users

    # Create tags and posts for each user
    Enum.each(all_users, fn user ->
      create_tags_and_posts(user)
      Mix.shell().info("✅ Created tags and posts for #{user.display_name}")
    end)

    Mix.shell().info("\n🎉 Seeding complete!")
    Mix.shell().info("  - Users created: 10")
    Mix.shell().info("  - Total posts: #{10 * 30}")
    Mix.shell().info("  - Total tags: ~#{10 * 10 + 5}")

    Mix.shell().info(
      "\nYou can now log in with any of these users using password: 'password123'\n"
    )
  end

  defp clean_database do
    Mix.shell().info("\n⚠️  WARNING: Cleaning database (this is DESTRUCTIVE!)...")

    Repo.delete_all(PostTag)
    Repo.delete_all(Post)
    Repo.delete_all(Tag)

    # Only delete non-admin users to preserve admin accounts
    from(u in User, where: u.role != "admin")
    |> Repo.delete_all()

    Mix.shell().info("✅ Database cleaned (admin users preserved)\n")
  end

  defp create_users(count, locale) when locale in ["en", "fi"] do
    names = if locale == "en", do: english_names(), else: finnish_names()

    Enum.map(1..count, fn i ->
      {first_name, last_name} = Enum.at(names, i - 1)
      email = "#{String.downcase(first_name)}.#{String.downcase(last_name)}@example.com"

      # First create user with email and password
      case Accounts.register_user(%{email: email, password: "password123"}) do
        {:ok, user} ->
          # Then update profile fields
          profile_attrs = %{
            display_name: "#{first_name} #{last_name}",
            bio: generate_bio(first_name, locale),
            preferred_language: locale,
            website_url: "https://#{String.downcase(first_name)}.example.com"
          }

          case Accounts.update_user_profile(user, profile_attrs) do
            {:ok, updated_user} -> updated_user
            {:error, _changeset} -> user
          end

        {:error, changeset} ->
          Mix.shell().error("Failed to create user #{email}: #{inspect(changeset.errors)}")
          nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp create_tags_and_posts(user) do
    scope = Scope.for_user(user)
    locale = user.preferred_language

    # Create common tags (shared across users)
    common_tags = if locale == "en", do: @common_tags_en, else: @common_tags_fi

    common_tag_records =
      Enum.map(common_tags, fn tag_name ->
        # Try to find existing tag or create new one
        case Content.get_tag_by_name(scope, tag_name) do
          nil ->
            case Content.create_tag(scope, %{name: tag_name, is_public: true}) do
              {:ok, tag} -> tag
              _ -> nil
            end

          tag ->
            tag
        end
      end)
      |> Enum.reject(&is_nil/1)

    # Create unique tags for this user
    unique_templates =
      if locale == "en", do: @unique_tag_templates_en, else: @unique_tag_templates_fi

    unique_tag_records =
      Enum.map(unique_templates, fn template ->
        tag_name = "#{template} #{user.id}"

        case Content.create_tag(scope, %{name: tag_name, is_public: true}) do
          {:ok, tag} -> tag
          _ -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    all_user_tags = common_tag_records ++ unique_tag_records

    # Create 30 posts for this user
    Enum.each(1..30, fn post_num ->
      post_attrs = %{
        title: generate_title(post_num, locale),
        body: generate_long_article(locale),
        is_public: true,
        published_at: random_published_date()
      }

      case Content.create_post(scope, post_attrs) do
        {:ok, post} ->
          # Assign 3-5 random tags to this post
          num_tags = Enum.random(3..5)
          selected_tags = Enum.take_random(all_user_tags, num_tags)

          Enum.each(selected_tags, fn tag ->
            %PostTag{}
            |> PostTag.changeset(%{post_id: post.id, tag_id: tag.id}, scope)
            |> Repo.insert()
          end)

        {:error, _changeset} ->
          Mix.shell().error("Failed to create post #{post_num} for user #{user.email}")
      end
    end)
  end

  defp english_names do
    [
      {"Emma", "Johnson"},
      {"Liam", "Williams"},
      {"Olivia", "Brown"},
      {"Noah", "Davis"},
      {"Ava", "Miller"}
    ]
  end

  defp finnish_names do
    [
      {"Aino", "Virtanen"},
      {"Eero", "Korhonen"},
      {"Liisa", "Mäkinen"},
      {"Mikko", "Nieminen"},
      {"Sofia", "Laine"}
    ]
  end

  defp generate_bio(first_name, "en") do
    "Hi, I'm #{first_name}! I'm a passionate writer and blogger sharing my thoughts and experiences with the world. I love exploring new ideas and connecting with readers."
  end

  defp generate_bio(first_name, "fi") do
    "Hei, olen #{first_name}! Olen intohimoinen kirjoittaja ja bloggaaja, joka jakaa ajatuksiaan ja kokemuksiaan maailman kanssa. Rakastan uusien ideoiden tutkimista ja lukijoiden kanssa yhteydenpitoa."
  end

  defp generate_title(num, "en") do
    titles = [
      "Understanding the Fundamentals of #{topic_en()}",
      "My Journey with #{topic_en()}: Lessons Learned",
      "Deep Dive: #{topic_en()} Best Practices",
      "#{topic_en()}: What Everyone Should Know",
      "The Complete Guide to #{topic_en()}",
      "Exploring #{topic_en()} in Modern Times",
      "#{topic_en()}: A Personal Perspective",
      "Why #{topic_en()} Matters Now More Than Ever",
      "The Future of #{topic_en()}: Trends and Predictions",
      "#{topic_en()}: Common Mistakes to Avoid"
    ]

    Enum.random(titles) <> " (Part #{num})"
  end

  defp generate_title(num, "fi") do
    titles = [
      "Ymmärtämään #{topic_fi()}n perusteet",
      "Matkani #{topic_fi()}n kanssa: Opittuja oppeja",
      "Syväsukellus: #{topic_fi()}n parhaat käytännöt",
      "#{topic_fi()}: Mitä jokaisen tulisi tietää",
      "Täydellinen opas #{topic_fi()}n",
      "#{topic_fi()}n tutkiminen nykyaikana",
      "#{topic_fi()}: Henkilökohtainen näkökulma",
      "Miksi #{topic_fi()} on tärkeämpi kuin koskaan",
      "#{topic_fi()}n tulevaisuus: Trendit ja ennusteet",
      "#{topic_fi()}: Yleisiä virheitä, joita tulee välttää"
    ]

    Enum.random(titles) <> " (Osa #{num})"
  end

  defp topic_en do
    Enum.random([
      "Web Development",
      "Digital Marketing",
      "Product Design",
      "Remote Work",
      "Productivity",
      "Sustainability",
      "Innovation",
      "Leadership",
      "Creativity",
      "Technology"
    ])
  end

  defp topic_fi do
    Enum.random([
      "Verkkokehitys",
      "Digitaalinen markkinointi",
      "Tuotesuunnittelu",
      "Etätyö",
      "Tuottavuus",
      "Kestävyys",
      "Innovaatio",
      "Johtajuus",
      "Luovuus",
      "Teknologia"
    ])
  end

  defp generate_long_article("en") do
    paragraphs = [
      "In today's rapidly evolving digital landscape, it's more important than ever to stay informed and adaptable. This article explores the key concepts and practical applications that can help you navigate the complexities of modern technology and business.",
      "Throughout my experience in this field, I've encountered numerous challenges and opportunities. Each one has taught me valuable lessons about innovation, perseverance, and the importance of continuous learning. Let me share some of these insights with you.",
      "The fundamental principles that guide successful approaches in this domain are rooted in understanding both the technical aspects and the human elements. It's not just about the tools we use, but how we use them to create meaningful impact and solve real-world problems.",
      "One of the most critical factors for success is maintaining a balance between theoretical knowledge and practical application. While it's essential to understand the underlying concepts, the true value comes from implementing these ideas in real-world scenarios and learning from the outcomes.",
      "As we look toward the future, several emerging trends are shaping the landscape. These developments present both opportunities and challenges for practitioners and enthusiasts alike. Staying ahead requires not just awareness, but active engagement and experimentation.",
      "The community surrounding this field is incredibly diverse and passionate. Collaboration and knowledge sharing have been instrumental in driving innovation and pushing boundaries. I've been fortunate to learn from many talented individuals who generously share their expertise.",
      "In conclusion, the journey of exploration and growth in this area is ongoing. There's always something new to discover, another perspective to consider, or a better way to approach familiar problems. I encourage you to stay curious, keep learning, and share your own experiences with others."
    ]

    Enum.join(paragraphs, "\n\n")
  end

  defp generate_long_article("fi") do
    paragraphs = [
      "Nykypäivän nopeasti kehittyvässä digitaalisessa ympäristössä on tärkeämpää kuin koskaan pysyä ajan tasalla ja mukautua muutoksiin. Tämä artikkeli tutkii keskeisiä käsitteitä ja käytännön sovelluksia, jotka voivat auttaa sinua navigoimaan nykyaikaisen teknologian ja liiketoiminnan monimutkaisuuksissa.",
      "Kokemukseni tällä alalla on tuonut mukanaan lukuisia haasteita ja mahdollisuuksia. Jokainen niistä on opettanut minulle arvokkaita oppeja innovaatiosta, sinnikkyydestä ja jatkuvan oppimisen tärkeydestä. Haluan jakaa joitakin näitä oivalluksia kanssanne.",
      "Menestyksekkäitä lähestymistapoja ohjaavat perusperiaatteet juontavat juurensa sekä teknisten että inhimillisten elementtien ymmärtämiseen. Kyse ei ole vain käyttämistämme työkaluista, vaan siitä, miten käytämme niitä merkityksellisen vaikutuksen luomiseen ja todellisten ongelmien ratkaisemiseen.",
      "Yksi kriittisimmistä menestystekijöistä on tasapainon ylläpitäminen teoreettisen tiedon ja käytännön soveltamisen välillä. Vaikka on olennaista ymmärtää taustalla olevat käsitteet, todellinen arvo tulee näiden ajatusten toteuttamisesta käytännön skenaarioissa ja tulosten oppimisesta.",
      "Kun katsomme tulevaisuuteen, useat nousevat trendit muokkaavat maisemaa. Nämä kehityskulut tarjoavat sekä mahdollisuuksia että haasteita harjoittajille ja harrastajille. Eturintamassa pysyminen vaatii ei vain tietoisuutta, vaan aktiivista osallistumista ja kokeilua.",
      "Tätä alaa ympäröivä yhteisö on uskomattoman monimuotoinen ja intohimoinen. Yhteistyö ja tiedon jakaminen ovat olleet keskeisiä innovaation edistämisessä ja rajojen ylittämisessä. Olen ollut onnekas saadessani oppia monilta lahjakkaita yksilöiltä, jotka ovat anteliaasti jakaneet asiantuntemustaan.",
      "Lopuksi, tutkimisen ja kasvun matka tällä alueella on jatkuvaa. On aina jotain uutta löydettävää, toinen näkökulma harkittavana tai parempi tapa lähestyä tuttuja ongelmia. Kannustan sinua pysymään uteliaana, jatkamaan oppimista ja jakamaan omia kokemuksiasi muiden kanssa."
    ]

    Enum.join(paragraphs, "\n\n")
  end

  defp random_published_date do
    # Generate random date within the last 90 days
    days_ago = Enum.random(1..90)
    DateTime.utc_now() |> DateTime.add(-days_ago * 24 * 60 * 60, :second)
  end
end
