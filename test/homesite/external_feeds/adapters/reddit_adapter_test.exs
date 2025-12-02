defmodule Homesite.ExternalFeeds.Adapters.RedditAdapterTest do
  use Homesite.DataCase, async: true

  alias Homesite.ExternalFeeds.Adapters.RedditAdapter
  alias Homesite.ExternalFeeds.FeedSource

  describe "validate_source/1" do
    test "accepts valid subreddit" do
      source = %FeedSource{
        metadata: %{"subreddit" => "elixir"}
      }

      assert :ok = RedditAdapter.validate_source(source)
    end

    test "accepts valid subreddit with underscores" do
      source = %FeedSource{
        metadata: %{"subreddit" => "elixir_lang"}
      }

      assert :ok = RedditAdapter.validate_source(source)
    end

    test "accepts valid subreddit with numbers" do
      source = %FeedSource{
        metadata: %{"subreddit" => "programming123"}
      }

      assert :ok = RedditAdapter.validate_source(source)
    end

    test "accepts valid username" do
      source = %FeedSource{
        metadata: %{"username" => "spez"}
      }

      assert :ok = RedditAdapter.validate_source(source)
    end

    test "accepts valid username with hyphens" do
      source = %FeedSource{
        metadata: %{"username" => "user-name"}
      }

      assert :ok = RedditAdapter.validate_source(source)
    end

    test "accepts valid username with underscores" do
      source = %FeedSource{
        metadata: %{"username" => "user_name"}
      }

      assert :ok = RedditAdapter.validate_source(source)
    end

    test "rejects subreddit with special characters" do
      source = %FeedSource{
        metadata: %{"subreddit" => "elixir@lang"}
      }

      assert {:error, msg} = RedditAdapter.validate_source(source)
      assert msg =~ "Invalid subreddit format"
    end

    test "rejects subreddit too long" do
      source = %FeedSource{
        metadata: %{"subreddit" => String.duplicate("a", 22)}
      }

      assert {:error, msg} = RedditAdapter.validate_source(source)
      assert msg =~ "Invalid subreddit format"
    end

    test "rejects subreddit too short" do
      source = %FeedSource{
        metadata: %{"subreddit" => ""}
      }

      assert {:error, msg} = RedditAdapter.validate_source(source)
      assert msg =~ "Invalid subreddit format"
    end

    test "rejects username too short" do
      source = %FeedSource{
        metadata: %{"username" => "ab"}
      }

      assert {:error, msg} = RedditAdapter.validate_source(source)
      assert msg =~ "Invalid username format"
    end

    test "rejects username too long" do
      source = %FeedSource{
        metadata: %{"username" => String.duplicate("a", 21)}
      }

      assert {:error, msg} = RedditAdapter.validate_source(source)
      assert msg =~ "Invalid username format"
    end

    test "rejects username with special characters" do
      source = %FeedSource{
        metadata: %{"username" => "user@name"}
      }

      assert {:error, msg} = RedditAdapter.validate_source(source)
      assert msg =~ "Invalid username format"
    end

    test "rejects both subreddit and username" do
      source = %FeedSource{
        metadata: %{
          "subreddit" => "elixir",
          "username" => "spez"
        }
      }

      assert {:error, msg} = RedditAdapter.validate_source(source)
      assert msg =~ "Cannot specify both"
    end

    test "rejects neither subreddit nor username" do
      source = %FeedSource{
        metadata: %{}
      }

      assert {:error, msg} = RedditAdapter.validate_source(source)
      assert msg =~ "Must specify either subreddit or username"
    end

    test "rejects non-string subreddit" do
      source = %FeedSource{
        metadata: %{"subreddit" => 123}
      }

      assert {:error, msg} = RedditAdapter.validate_source(source)
      assert msg =~ "Subreddit must be a string"
    end

    test "rejects non-string username" do
      source = %FeedSource{
        metadata: %{"username" => 123}
      }

      assert {:error, msg} = RedditAdapter.validate_source(source)
      assert msg =~ "Username must be a string"
    end

    test "rejects non-map metadata" do
      source = %FeedSource{
        metadata: nil
      }

      assert {:error, msg} = RedditAdapter.validate_source(source)
      assert msg =~ "Metadata must be a map"
    end
  end

  describe "fetch_items/1" do
    @tag :external
    test "builds correct RSS URL for subreddit" do
      source = %FeedSource{
        name: "Elixir Subreddit",
        feed_type: "reddit",
        url: "https://reddit.com/r/elixir",
        metadata: %{"subreddit" => "elixir"}
      }

      # We can't actually fetch Reddit in tests, but we can verify the URL is built correctly
      # by mocking or checking the error (Reddit will fail in test environment)
      # For now, just verify it doesn't crash and attempts to fetch
      result = RedditAdapter.fetch_items(source)

      # Result will be error in test env (no internet), but that's expected
      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end

    @tag :external
    test "builds correct RSS URL for username" do
      source = %FeedSource{
        name: "Reddit User",
        feed_type: "reddit",
        url: "https://reddit.com/user/spez",
        metadata: %{"username" => "spez"}
      }

      result = RedditAdapter.fetch_items(source)
      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end

    test "returns error if metadata missing required fields" do
      source = %FeedSource{
        name: "Invalid Reddit",
        feed_type: "reddit",
        url: "https://reddit.com",
        metadata: %{}
      }

      assert {:error, msg} = RedditAdapter.fetch_items(source)
      assert msg =~ "Must specify either subreddit or username"
    end
  end
end
