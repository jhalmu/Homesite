defmodule HomesiteWeb.FormComponentsTest do
  use HomesiteWeb.ConnCase, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest
  import HomesiteWeb.FormComponents

  describe "tag_input/1" do
    test "renders with empty selected tags" do
      assigns = %{
        selected_tags: [],
        tag_search_query: "",
        tag_suggestions: [],
        similar_tags_warning: [],
        on_search: "search-tags",
        on_add: "add-tag",
        on_remove: "remove-tag",
        on_create: "create-and-add-tag"
      }

      html = rendered_to_string(~H"<.tag_input {assigns} />")

      assert html =~ "form-control"
      assert html =~ ~s(placeholder="Search or create tags...")
      assert html =~ ~s(type="hidden")
      assert html =~ ~s(value="")
    end

    test "renders with selected tags" do
      assigns = %{
        selected_tags: [
          %{id: 1, name: "Elixir"},
          %{id: 2, name: "Phoenix"}
        ],
        tag_search_query: "",
        tag_suggestions: [],
        similar_tags_warning: [],
        on_search: "search-tags",
        on_add: "add-tag",
        on_remove: "remove-tag",
        on_create: "create-and-add-tag"
      }

      html = rendered_to_string(~H"<.tag_input {assigns} />")

      assert html =~ "Elixir"
      assert html =~ "Phoenix"
      assert html =~ "badge-primary"
      assert html =~ "phx-click=\"remove-tag\""
      assert html =~ ~s(value="1")
      assert html =~ ~s(value="2")
    end

    test "renders tag suggestions with post counts" do
      assigns = %{
        selected_tags: [],
        tag_search_query: "eli",
        tag_suggestions: [
          {%{id: 1, name: "Elixir"}, 5},
          {%{id: 2, name: "Elasticsearch"}, 2}
        ],
        similar_tags_warning: [],
        on_search: "search-tags",
        on_add: "add-tag",
        on_remove: "remove-tag",
        on_create: "create-and-add-tag"
      }

      html = rendered_to_string(~H"<.tag_input {assigns} />")

      assert html =~ "Elixir"
      assert html =~ "5 posts"
      assert html =~ "Elasticsearch"
      assert html =~ "2 posts"
      assert html =~ ~s(role="listbox")
      assert html =~ ~s(role="option")
    end

    test "renders exact match add button when query matches exactly" do
      assigns = %{
        selected_tags: [],
        tag_search_query: "elixir",
        tag_suggestions: [
          {%{id: 1, name: "Elixir"}, 5}
        ],
        similar_tags_warning: [],
        on_search: "search-tags",
        on_add: "add-tag",
        on_remove: "remove-tag",
        on_create: "create-and-add-tag"
      }

      html = rendered_to_string(~H"<.tag_input {assigns} />")

      assert html =~ "Add"
      assert html =~ "\"Elixir\""
      assert html =~ "hero-check"
    end

    test "renders create button when query doesn't match exactly" do
      assigns = %{
        selected_tags: [],
        tag_search_query: "NewTag",
        tag_suggestions: [],
        similar_tags_warning: [],
        on_search: "search-tags",
        on_add: "add-tag",
        on_remove: "remove-tag",
        on_create: "create-and-add-tag"
      }

      html = rendered_to_string(~H"<.tag_input {assigns} />")

      assert html =~ "Create"
      assert html =~ "\"NewTag\""
      assert html =~ "hero-plus"
      assert html =~ "phx-click=\"create-and-add-tag\""
    end

    test "renders similar tags warning" do
      assigns = %{
        selected_tags: [],
        tag_search_query: "",
        tag_suggestions: [],
        similar_tags_warning: [
          %{id: 1, name: "Elixir"},
          %{id: 2, name: "Elixr"}
        ],
        on_search: "search-tags",
        on_add: "add-tag",
        on_remove: "remove-tag",
        on_create: "create-and-add-tag"
      }

      html = rendered_to_string(~H"<.tag_input {assigns} />")

      assert html =~ "alert-warning"
      assert html =~ "Similar tags exist:"
      assert html =~ "Elixir"
      assert html =~ "Elixr"
    end

    test "includes accessibility attributes" do
      assigns = %{
        selected_tags: [%{id: 1, name: "Test Tag"}],
        tag_search_query: "",
        tag_suggestions: [],
        similar_tags_warning: [],
        on_search: "search-tags",
        on_add: "add-tag",
        on_remove: "remove-tag",
        on_create: "create-and-add-tag"
      }

      html = rendered_to_string(~H"<.tag_input {assigns} />")

      assert html =~ ~s(aria-label="Remove tag Test Tag")
      assert html =~ ~s(aria-label="Search tags")
    end

    test "handles special characters in tag names" do
      assigns = %{
        selected_tags: [
          %{id: 1, name: "C++"},
          %{id: 2, name: "Node.js"},
          %{id: 3, name: "ASP.NET"}
        ],
        tag_search_query: "",
        tag_suggestions: [],
        similar_tags_warning: [],
        on_search: "search-tags",
        on_add: "add-tag",
        on_remove: "remove-tag",
        on_create: "create-and-add-tag"
      }

      html = rendered_to_string(~H"<.tag_input {assigns} />")

      assert html =~ "C++"
      assert html =~ "Node.js"
      assert html =~ "ASP.NET"
    end

    test "escapes HTML in tag names to prevent XSS" do
      assigns = %{
        selected_tags: [
          %{id: 1, name: "<script>alert('xss')</script>"}
        ],
        tag_search_query: "",
        tag_suggestions: [],
        similar_tags_warning: [],
        on_search: "search-tags",
        on_add: "add-tag",
        on_remove: "remove-tag",
        on_create: "create-and-add-tag"
      }

      html = rendered_to_string(~H"<.tag_input {assigns} />")

      refute html =~ "<script>"
      assert html =~ "&lt;script&gt;"
    end

    test "uses custom field name when provided" do
      assigns = %{
        selected_tags: [%{id: 1, name: "Test"}],
        tag_search_query: "",
        tag_suggestions: [],
        similar_tags_warning: [],
        on_search: "search-tags",
        on_add: "add-tag",
        on_remove: "remove-tag",
        on_create: "create-and-add-tag",
        field_name: "article[tag_ids][]"
      }

      html = rendered_to_string(~H"<.tag_input {assigns} />")

      assert html =~ ~s(name="article[tag_ids][]")
    end

    test "handles empty query with suggestions list" do
      assigns = %{
        selected_tags: [],
        tag_search_query: "",
        tag_suggestions: [{%{id: 1, name: "Popular"}, 10}],
        similar_tags_warning: [],
        on_search: "search-tags",
        on_add: "add-tag",
        on_remove: "remove-tag",
        on_create: "create-and-add-tag"
      }

      html = rendered_to_string(~H"<.tag_input {assigns} />")

      # Should show suggestions but not create button
      assert html =~ "Popular"
      refute html =~ "Create"
    end
  end

  describe "datetime_input/1" do
    test "renders with default values when value is nil" do
      # Create a simple form for testing
      form = Phoenix.Component.to_form(%{}, as: :post)

      assigns = %{
        date_field: form[:publish_date],
        time_field: form[:publish_time],
        value: nil,
        label: "Publication Date",
        on_set_now: "set-time-now"
      }

      html = rendered_to_string(~H"<.datetime_input {assigns} />")

      assert html =~ "Publication Date"
      assert html =~ "type=\"date\""
      assert html =~ "type=\"time\""
      assert html =~ "Now"
      assert html =~ "phx-click=\"set-time-now\""
    end

    test "renders with DateTime value" do
      {:ok, dt} = DateTime.new(~D[2024-01-15], ~T[14:30:00], "Etc/UTC")
      form = Phoenix.Component.to_form(%{}, as: :post)

      assigns = %{
        date_field: form[:publish_date],
        time_field: form[:publish_time],
        value: dt,
        label: "Publication Date",
        on_set_now: "set-time-now"
      }

      html = rendered_to_string(~H"<.datetime_input {assigns} />")

      assert html =~ "2024-01-15"
      assert html =~ "14:30"
    end

    test "includes accessibility attributes" do
      form = Phoenix.Component.to_form(%{}, as: :post)

      assigns = %{
        date_field: form[:publish_date],
        time_field: form[:publish_time],
        value: nil,
        label: "Publication Date",
        on_set_now: "set-time-now"
      }

      html = rendered_to_string(~H"<.datetime_input {assigns} />")

      assert html =~ ~s(aria-label="Date")
      assert html =~ ~s(aria-label="Time")
      assert html =~ ~s(aria-label="Set to current time")
    end

    test "renders custom help text when provided" do
      form = Phoenix.Component.to_form(%{}, as: :post)

      assigns = %{
        date_field: form[:publish_date],
        time_field: form[:publish_time],
        value: nil,
        label: "Schedule For",
        help_text: "Choose when to publish this article",
        on_set_now: "set-time-now"
      }

      html = rendered_to_string(~H"<.datetime_input {assigns} />")

      assert html =~ "Choose when to publish this article"
    end
  end

  describe "similar_items_alert/1" do
    test "renders alert with items" do
      assigns = %{
        items: [
          %{id: 1, name: "Elixir"},
          %{id: 2, name: "Elixr"}
        ],
        type: "tags",
        on_select: "add-tag",
        message: "Similar tags exist:"
      }

      html = rendered_to_string(~H"<.similar_items_alert {assigns} />")

      assert html =~ "alert-warning"
      assert html =~ "Similar tags exist:"
      assert html =~ "Elixir"
      assert html =~ "Elixr"
      assert html =~ "phx-click=\"add-tag\""
    end

    test "renders nothing when items list is empty" do
      assigns = %{
        items: [],
        type: "tags",
        on_select: "add-tag"
      }

      html = rendered_to_string(~H"<.similar_items_alert {assigns} />")

      refute html =~ "alert-warning"
    end

    test "generates default message from type" do
      assigns = %{
        items: [%{id: 1, name: "Test"}],
        type: "posts",
        on_select: "select-post"
      }

      html = rendered_to_string(~H"<.similar_items_alert {assigns} />")

      assert html =~ "Similar posts exist:"
    end

    test "includes phx-value-id attribute" do
      assigns = %{
        items: [%{id: 123, name: "Test"}],
        type: "items",
        on_select: "select-item"
      }

      html = rendered_to_string(~H"<.similar_items_alert {assigns} />")

      assert html =~ "Test"
      assert html =~ ~s(phx-value-id="123")
    end

    test "handles special characters in item names" do
      assigns = %{
        items: [%{id: 1, name: "Test & Co."}],
        type: "companies",
        on_select: "select"
      }

      html = rendered_to_string(~H"<.similar_items_alert {assigns} />")

      assert html =~ "Test &amp; Co."
    end
  end
end
