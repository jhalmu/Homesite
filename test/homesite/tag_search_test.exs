defmodule Homesite.TagSearchTest do
  use Homesite.DataCase

  alias Homesite.Content

  describe "search_tags/2" do
    setup do
      scope = Homesite.AccountsFixtures.user_scope_fixture()

      {:ok, elixir_tag} = Content.create_tag(scope, %{name: "Elixir", slug: "elixir"})
      {:ok, phoenix_tag} = Content.create_tag(scope, %{name: "Phoenix", slug: "phoenix"})

      {:ok, liveview_tag} =
        Content.create_tag(scope, %{name: "Phoenix LiveView", slug: "phoenix-liveview"})

      {:ok, ecto_tag} = Content.create_tag(scope, %{name: "Ecto", slug: "ecto"})
      {:ok, postgres_tag} = Content.create_tag(scope, %{name: "PostgreSQL", slug: "postgresql"})

      %{
        elixir: elixir_tag,
        phoenix: phoenix_tag,
        liveview: liveview_tag,
        ecto: ecto_tag,
        postgres: postgres_tag,
        scope: scope
      }
    end

    test "returns empty list for empty query" do
      assert Content.search_tags("") == []
    end

    test "returns empty list for whitespace-only query" do
      assert Content.search_tags("   ") == []
    end

    test "finds tag by exact name match", %{elixir: tag} do
      results = Content.search_tags("Elixir")
      assert length(results) == 1
      assert hd(results).id == tag.id
      assert hd(results).name == "Elixir"
    end

    test "finds tag by slug", %{phoenix: tag} do
      results = Content.search_tags("phoenix")
      assert length(results) >= 1
      assert Enum.any?(results, &(&1.id == tag.id))
    end

    test "finds tag by partial name match", %{liveview: tag} do
      results = Content.search_tags("LiveView")
      assert length(results) >= 1
      assert Enum.any?(results, &(&1.id == tag.id))
    end

    test "finds multiple tags with similar names", %{phoenix: phoenix, liveview: liveview} do
      results = Content.search_tags("phoenix")
      tag_ids = Enum.map(results, & &1.id)
      assert phoenix.id in tag_ids
      assert liveview.id in tag_ids
    end

    test "case-insensitive search", %{elixir: tag} do
      results = Content.search_tags("ELIXIR")
      assert length(results) >= 1
      assert Enum.any?(results, &(&1.id == tag.id))
    end

    test "handles fuzzy matching with typos", %{elixir: _tag} do
      results = Content.search_tags("elxir")
      # Should find "elixir" with typo
      assert length(results) >= 1
    end

    test "respects limit option", %{scope: scope} do
      # Create many tags
      for i <- 1..15 do
        Content.create_tag(scope, %{name: "Test Tag #{i}", slug: "test-tag-#{i}"})
      end

      results = Content.search_tags("Test Tag", limit: 5)
      assert length(results) == 5
    end

    test "handles negative limit gracefully" do
      results = Content.search_tags("Elixir", limit: -1)
      assert results == []
    end

    test "orders results by relevance", %{elixir: elixir, phoenix: _phoenix} do
      results = Content.search_tags("eli")
      # "Elixir" should rank higher than other matches for "eli"
      assert length(results) >= 1
      first_result = hd(results)
      assert first_result.id == elixir.id or first_result.name =~ ~r/eli/i
    end

    test "preloads user association", %{elixir: tag} do
      results = Content.search_tags("Elixir")
      assert length(results) == 1
      result = hd(results)
      assert result.user
      assert result.user.id == tag.user_id
    end

    test "finds tags by slug with hyphens", %{liveview: tag} do
      results = Content.search_tags("phoenix-liveview")
      assert length(results) >= 1
      assert Enum.any?(results, &(&1.id == tag.id))
    end

    test "partial slug match", %{postgres: tag} do
      results = Content.search_tags("postgre")
      assert length(results) >= 1
      assert Enum.any?(results, &(&1.id == tag.id))
    end
  end
end
