defmodule Homesite.ExternalFeeds.OPMLTest do
  use Homesite.DataCase, async: true

  import Homesite.AccountsFixtures

  alias Homesite.ExternalFeeds
  alias Homesite.ExternalFeeds.OPML

  setup do
    # Each test gets its own user with unique email (via user_fixture default)
    user = user_fixture()
    scope = Homesite.Accounts.Scope.for_user(user)

    %{scope: scope, user: user}
  end

  describe "export_to_opml/1" do
    test "exports empty OPML when no feeds exist", %{scope: scope, user: user} do
      {:ok, opml} = OPML.export_to_opml(scope)

      assert opml =~ ~s[<opml version="2.0">]
      assert opml =~ ~s[<title>Homesite Feed Subscriptions</title>]
      assert opml =~ ~s[<ownerEmail>#{user.email}</ownerEmail>]
      assert opml =~ ~s[<body>]
      assert opml =~ ~s[</body>]
    end

    test "exports single feed without folder", %{scope: scope} do
      {:ok, _feed} =
        ExternalFeeds.create_feed_source(scope, %{
          name: "Tech Blog",
          url: "https://example.com/feed.xml",
          feed_type: "rss",
          enabled: true
        })

      {:ok, opml} = OPML.export_to_opml(scope)

      assert opml =~ ~s[<outline type="rss"]
      assert opml =~ ~s[text="Tech Blog"]
      assert opml =~ ~s[title="Tech Blog"]
      assert opml =~ ~s[xmlUrl="https://example.com/feed.xml"]
    end

    test "exports multiple feeds without folders", %{scope: scope} do
      {:ok, _feed1} =
        ExternalFeeds.create_feed_source(scope, %{
          name: "Feed 1",
          url: "https://example1.com/feed.xml",
          feed_type: "rss",
          enabled: true
        })

      {:ok, _feed2} =
        ExternalFeeds.create_feed_source(scope, %{
          name: "Feed 2",
          url: "https://example2.com/feed.atom",
          feed_type: "atom",
          enabled: true
        })

      {:ok, opml} = OPML.export_to_opml(scope)

      assert opml =~ ~s[text="Feed 1"]
      assert opml =~ ~s[xmlUrl="https://example1.com/feed.xml"]
      assert opml =~ ~s[text="Feed 2"]
      assert opml =~ ~s[xmlUrl="https://example2.com/feed.atom"]
    end

    test "exports feeds organized in folders", %{scope: scope} do
      {:ok, folder} =
        ExternalFeeds.create_feed_folder(scope, %{
          name: "Tech News"
        })

      {:ok, _feed} =
        ExternalFeeds.create_feed_source(scope, %{
          name: "TechCrunch",
          url: "https://techcrunch.com/feed",
          feed_type: "rss",
          enabled: true,
          folder_id: folder.id
        })

      {:ok, opml} = OPML.export_to_opml(scope)

      assert opml =~ ~s[<outline text="Tech News" title="Tech News">]
      assert opml =~ ~s[text="TechCrunch"]
      assert opml =~ ~s[xmlUrl="https://techcrunch.com/feed"]
    end

    test "exports mixed feeds (with and without folders)", %{scope: scope} do
      {:ok, folder} =
        ExternalFeeds.create_feed_folder(scope, %{
          name: "Tech"
        })

      {:ok, _feed_in_folder} =
        ExternalFeeds.create_feed_source(scope, %{
          name: "Feed in Folder",
          url: "https://infolder.com/feed",
          feed_type: "rss",
          enabled: true,
          folder_id: folder.id
        })

      {:ok, _feed_top_level} =
        ExternalFeeds.create_feed_source(scope, %{
          name: "Top Level Feed",
          url: "https://toplevel.com/feed",
          feed_type: "rss",
          enabled: true
        })

      {:ok, opml} = OPML.export_to_opml(scope)

      assert opml =~ ~s[<outline text="Tech" title="Tech">]
      assert opml =~ ~s[text="Feed in Folder"]
      assert opml =~ ~s[text="Top Level Feed"]
    end

    test "escapes XML special characters in feed names", %{scope: scope} do
      {:ok, _feed} =
        ExternalFeeds.create_feed_source(scope, %{
          name: "AT&T Blog <Official>",
          url: "https://example.com/feed",
          feed_type: "rss",
          enabled: true
        })

      {:ok, opml} = OPML.export_to_opml(scope)

      assert opml =~ ~s[text="AT&amp;T Blog &lt;Official&gt;"]
      refute opml =~ "AT&T Blog <Official>"
    end

    test "exports feeds in display order within folders", %{scope: scope} do
      {:ok, folder} =
        ExternalFeeds.create_feed_folder(scope, %{
          name: "News",
          display_order: 0
        })

      {:ok, _feed1} =
        ExternalFeeds.create_feed_source(scope, %{
          name: "Feed A",
          url: "https://a.com/feed",
          feed_type: "rss",
          enabled: true,
          folder_id: folder.id,
          display_order: 1
        })

      {:ok, _feed2} =
        ExternalFeeds.create_feed_source(scope, %{
          name: "Feed B",
          url: "https://b.com/feed",
          feed_type: "rss",
          enabled: true,
          folder_id: folder.id,
          display_order: 0
        })

      {:ok, opml} = OPML.export_to_opml(scope)

      # Feed B (order 0) should appear before Feed A (order 1)
      b_index = :binary.match(opml, "Feed B") |> elem(0)
      a_index = :binary.match(opml, "Feed A") |> elem(0)

      assert b_index < a_index
    end

    test "exports valid OPML 2.0 structure", %{scope: scope} do
      {:ok, _feed} =
        ExternalFeeds.create_feed_source(scope, %{
          name: "Test Feed",
          url: "https://example.com/feed",
          feed_type: "rss",
          enabled: true
        })

      {:ok, opml} = OPML.export_to_opml(scope)

      # Verify OPML structure
      assert opml =~ ~r/<\?xml version="1.0" encoding="UTF-8"\?>/
      assert opml =~ ~r/<opml version="2.0">/
      assert opml =~ ~r/<head>/
      assert opml =~ ~r/<\/head>/
      assert opml =~ ~r/<body>/
      assert opml =~ ~r/<\/body>/
      assert opml =~ ~r/<\/opml>/
      assert opml =~ ~r/<dateCreated>.*<\/dateCreated>/
    end
  end

  describe "import_from_opml/2" do
    test "imports single feed from OPML", %{scope: scope} do
      opml = """
      <?xml version="1.0" encoding="UTF-8"?>
      <opml version="2.0">
        <head>
          <title>Test Subscriptions</title>
        </head>
        <body>
          <outline type="rss" text="Tech Blog" title="Tech Blog" xmlUrl="https://example.com/feed.xml"/>
        </body>
      </opml>
      """

      {:ok, result} = OPML.import_from_opml(scope, opml)

      assert result.imported == 1
      assert result.skipped == 0
      assert result.errors == []

      feeds = ExternalFeeds.list_feed_sources(scope)
      assert length(feeds) == 1
      assert hd(feeds).name == "Tech Blog"
      assert hd(feeds).url == "https://example.com/feed.xml"
    end

    test "imports multiple feeds from OPML", %{scope: scope} do
      opml = """
      <?xml version="1.0" encoding="UTF-8"?>
      <opml version="2.0">
        <body>
          <outline type="rss" text="Feed 1" xmlUrl="https://feed1.com/rss"/>
          <outline type="rss" text="Feed 2" xmlUrl="https://feed2.com/rss"/>
          <outline type="rss" text="Feed 3" xmlUrl="https://feed3.com/rss"/>
        </body>
      </opml>
      """

      {:ok, result} = OPML.import_from_opml(scope, opml)

      assert result.imported == 3
      assert result.skipped == 0

      feeds = ExternalFeeds.list_feed_sources(scope)
      assert length(feeds) == 3
    end

    test "creates folders from OPML categories", %{scope: scope} do
      opml = """
      <?xml version="1.0" encoding="UTF-8"?>
      <opml version="2.0">
        <body>
          <outline text="Tech News" title="Tech News">
            <outline type="rss" text="TechCrunch" xmlUrl="https://techcrunch.com/feed"/>
            <outline type="rss" text="Ars Technica" xmlUrl="https://arstechnica.com/feed"/>
          </outline>
        </body>
      </opml>
      """

      {:ok, result} = OPML.import_from_opml(scope, opml, create_folders: true)

      assert result.imported == 2

      folders = ExternalFeeds.list_feed_folders(scope)
      assert length(folders) == 1
      assert hd(folders).name == "Tech News"

      feeds = ExternalFeeds.list_feed_sources(scope)
      assert Enum.all?(feeds, fn f -> f.folder_id == hd(folders).id end)
    end

    test "skips folder creation when create_folders: false", %{scope: scope} do
      opml = """
      <?xml version="1.0" encoding="UTF-8"?>
      <opml version="2.0">
        <body>
          <outline text="Tech News" title="Tech News">
            <outline type="rss" text="Feed" xmlUrl="https://example.com/feed"/>
          </outline>
        </body>
      </opml>
      """

      {:ok, result} = OPML.import_from_opml(scope, opml, create_folders: false)

      assert result.imported == 1

      folders = ExternalFeeds.list_feed_folders(scope)
      assert Enum.empty?(folders)

      feeds = ExternalFeeds.list_feed_sources(scope)
      assert is_nil(hd(feeds).folder_id)
    end

    test "skips duplicate feeds when skip_duplicates: true", %{scope: scope} do
      # Create existing feed
      {:ok, _existing} =
        ExternalFeeds.create_feed_source(scope, %{
          name: "Existing Feed",
          url: "https://example.com/feed.xml",
          feed_type: "rss",
          enabled: true
        })

      opml = """
      <?xml version="1.0" encoding="UTF-8"?>
      <opml version="2.0">
        <body>
          <outline type="rss" text="Duplicate Feed" xmlUrl="https://example.com/feed.xml"/>
          <outline type="rss" text="New Feed" xmlUrl="https://newsite.com/feed.xml"/>
        </body>
      </opml>
      """

      {:ok, result} = OPML.import_from_opml(scope, opml, skip_duplicates: true)

      assert result.imported == 1
      assert result.skipped == 1

      feeds = ExternalFeeds.list_feed_sources(scope)
      assert length(feeds) == 2
    end

    test "imports duplicates when skip_duplicates: false", %{scope: scope} do
      {:ok, _existing} =
        ExternalFeeds.create_feed_source(scope, %{
          name: "Existing Feed",
          url: "https://example.com/feed.xml",
          feed_type: "rss",
          enabled: true
        })

      opml = """
      <?xml version="1.0" encoding="UTF-8"?>
      <opml version="2.0">
        <body>
          <outline type="rss" text="Duplicate Feed" xmlUrl="https://example.com/feed.xml"/>
        </body>
      </opml>
      """

      # When skip_duplicates is false, import proceeds (no unique constraint on URL)
      {:ok, result} = OPML.import_from_opml(scope, opml, skip_duplicates: false)

      # Should import the duplicate (database allows multiple feeds with same URL)
      assert result.imported == 1
      assert result.skipped == 0

      # Now we have 2 feeds with the same URL
      feeds = ExternalFeeds.list_feed_sources(scope)
      assert length(feeds) == 2
    end

    test "uses title if text is missing", %{scope: scope} do
      opml = """
      <?xml version="1.0" encoding="UTF-8"?>
      <opml version="2.0">
        <body>
          <outline type="rss" title="Only Title" xmlUrl="https://example.com/feed"/>
        </body>
      </opml>
      """

      {:ok, result} = OPML.import_from_opml(scope, opml)

      assert result.imported == 1

      feeds = ExternalFeeds.list_feed_sources(scope)
      assert hd(feeds).name == "Only Title"
    end

    test "uses 'Untitled Feed' if both title and text are missing", %{scope: scope} do
      opml = """
      <?xml version="1.0" encoding="UTF-8"?>
      <opml version="2.0">
        <body>
          <outline type="rss" xmlUrl="https://example.com/feed"/>
        </body>
      </opml>
      """

      {:ok, result} = OPML.import_from_opml(scope, opml)

      assert result.imported == 1

      feeds = ExternalFeeds.list_feed_sources(scope)
      assert hd(feeds).name == "Untitled Feed"
    end

    test "skips outlines without xmlUrl", %{scope: scope} do
      opml = """
      <?xml version="1.0" encoding="UTF-8"?>
      <opml version="2.0">
        <body>
          <outline text="Category Only" title="Category Only">
            <outline type="rss" text="Valid Feed" xmlUrl="https://example.com/feed"/>
          </outline>
        </body>
      </opml>
      """

      {:ok, result} = OPML.import_from_opml(scope, opml, create_folders: false)

      assert result.imported == 1

      feeds = ExternalFeeds.list_feed_sources(scope)
      assert length(feeds) == 1
      assert hd(feeds).name == "Valid Feed"
    end

    test "imports platform feeds as RSS type (specialized types require extra fields)", %{
      scope: scope
    } do
      # OPML imports always use RSS type because specialized types (youtube, reddit, bluesky)
      # require additional fields like `username` that aren't available in OPML format.
      # Users can manually change feed types after import if needed.
      opml = """
      <?xml version="1.0" encoding="UTF-8"?>
      <opml version="2.0">
        <body>
          <outline text="YouTube Channel" xmlUrl="https://www.youtube.com/feeds/videos.xml?channel_id=UC123"/>
          <outline text="Reddit" xmlUrl="https://www.reddit.com/r/elixir/.rss"/>
          <outline text="Bluesky" xmlUrl="https://bsky.app/profile/user.bsky.social/rss"/>
          <outline text="Atom Feed" xmlUrl="https://example.com/atom.xml"/>
        </body>
      </opml>
      """

      {:ok, result} = OPML.import_from_opml(scope, opml)

      assert result.imported == 4

      feeds = ExternalFeeds.list_feed_sources(scope)
      youtube_feed = Enum.find(feeds, &(&1.name == "YouTube Channel"))
      reddit_feed = Enum.find(feeds, &(&1.name == "Reddit"))
      bluesky_feed = Enum.find(feeds, &(&1.name == "Bluesky"))
      atom_feed = Enum.find(feeds, &(&1.name == "Atom Feed"))

      # All platform-specific feeds imported as RSS (they work as RSS feeds)
      assert youtube_feed.feed_type == "rss"
      assert reddit_feed.feed_type == "rss"
      assert bluesky_feed.feed_type == "rss"
      # Atom is detected when URL contains "atom"
      assert atom_feed.feed_type == "atom"
    end

    test "returns error for invalid XML", %{scope: scope} do
      invalid_opml = "<invalid xml here"

      {:error, reason} = OPML.import_from_opml(scope, invalid_opml)

      assert reason =~ "Failed to parse OPML"
    end

    test "reuses existing folders instead of creating duplicates", %{scope: scope} do
      # Create existing folder
      {:ok, existing_folder} =
        ExternalFeeds.create_feed_folder(scope, %{
          name: "Tech News"
        })

      opml = """
      <?xml version="1.0" encoding="UTF-8"?>
      <opml version="2.0">
        <body>
          <outline text="Tech News" title="Tech News">
            <outline type="rss" text="Feed 1" xmlUrl="https://feed1.com/rss"/>
            <outline type="rss" text="Feed 2" xmlUrl="https://feed2.com/rss"/>
          </outline>
        </body>
      </opml>
      """

      {:ok, result} = OPML.import_from_opml(scope, opml, create_folders: true)

      assert result.imported == 2

      # Should still have only 1 folder
      folders = ExternalFeeds.list_feed_folders(scope)
      assert length(folders) == 1

      # Both feeds should be in the existing folder
      feeds = ExternalFeeds.list_feed_sources(scope)
      assert Enum.all?(feeds, fn f -> f.folder_id == existing_folder.id end)
    end

    test "respects scope isolation - user A cannot import into user B's scope", %{scope: scope_a} do
      # Create user B
      user_b = user_fixture(%{email: "userb@example.com"})
      scope_b = Homesite.Accounts.Scope.for_user(user_b)

      # Create feed for user B
      {:ok, _feed_b} =
        ExternalFeeds.create_feed_source(scope_b, %{
          name: "User B Feed",
          url: "https://userb.com/feed",
          feed_type: "rss",
          enabled: true
        })

      # Import OPML into user A's scope
      opml = """
      <?xml version="1.0" encoding="UTF-8"?>
      <opml version="2.0">
        <body>
          <outline type="rss" text="User A Feed" xmlUrl="https://usera.com/feed"/>
        </body>
      </opml>
      """

      {:ok, result} = OPML.import_from_opml(scope_a, opml)

      assert result.imported == 1

      # User A should only see their own feed
      feeds_a = ExternalFeeds.list_feed_sources(scope_a)
      assert length(feeds_a) == 1
      assert hd(feeds_a).name == "User A Feed"

      # User B should only see their own feed
      feeds_b = ExternalFeeds.list_feed_sources(scope_b)
      assert length(feeds_b) == 1
      assert hd(feeds_b).name == "User B Feed"
    end
  end

  describe "export and import roundtrip" do
    test "exported OPML can be reimported successfully", %{scope: scope} do
      # Create original feed structure
      {:ok, folder1} =
        ExternalFeeds.create_feed_folder(scope, %{
          name: "Tech",
          display_order: 0
        })

      {:ok, folder2} =
        ExternalFeeds.create_feed_folder(scope, %{
          name: "News",
          display_order: 1
        })

      {:ok, _feed1} =
        ExternalFeeds.create_feed_source(scope, %{
          name: "TechCrunch",
          url: "https://techcrunch.com/feed",
          feed_type: "rss",
          enabled: true,
          folder_id: folder1.id
        })

      {:ok, _feed2} =
        ExternalFeeds.create_feed_source(scope, %{
          name: "Hacker News",
          url: "https://news.ycombinator.com/rss",
          feed_type: "rss",
          enabled: true,
          folder_id: folder1.id
        })

      {:ok, _feed3} =
        ExternalFeeds.create_feed_source(scope, %{
          name: "BBC News",
          url: "https://feeds.bbci.co.uk/news/rss.xml",
          feed_type: "rss",
          enabled: true,
          folder_id: folder2.id
        })

      {:ok, _feed4} =
        ExternalFeeds.create_feed_source(scope, %{
          name: "Top Level Feed",
          url: "https://toplevel.com/feed",
          feed_type: "rss",
          enabled: true
        })

      # Export
      {:ok, opml} = OPML.export_to_opml(scope)

      # Delete all feeds and folders
      ExternalFeeds.list_feed_sources(scope)
      |> Enum.each(fn feed -> ExternalFeeds.delete_feed_source(scope, feed) end)

      ExternalFeeds.list_feed_folders(scope)
      |> Enum.each(fn folder -> ExternalFeeds.delete_feed_folder(scope, folder) end)

      assert ExternalFeeds.list_feed_sources(scope) == []
      assert ExternalFeeds.list_feed_folders(scope) == []

      # Import
      {:ok, result} = OPML.import_from_opml(scope, opml, create_folders: true)

      assert result.imported == 4
      assert result.skipped == 0
      assert result.errors == []

      # Verify structure matches
      feeds = ExternalFeeds.list_feed_sources(scope)
      folders = ExternalFeeds.list_feed_folders(scope)

      assert length(feeds) == 4
      assert length(folders) == 2

      folder_names = Enum.map(folders, & &1.name) |> Enum.sort()
      assert folder_names == ["News", "Tech"]

      feed_names = Enum.map(feeds, & &1.name) |> Enum.sort()
      assert feed_names == ["BBC News", "Hacker News", "TechCrunch", "Top Level Feed"]
    end
  end
end
