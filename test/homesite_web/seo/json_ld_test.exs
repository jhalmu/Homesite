defmodule HomesiteWeb.SEO.JsonLDTest do
  use ExUnit.Case, async: true

  alias HomesiteWeb.SEO.JsonLD

  describe "website/1" do
    test "generates valid WebSite schema" do
      url = "https://example.com"
      result = JsonLD.website(url)

      assert result["@context"] == "https://schema.org"
      assert result["@type"] == "WebSite"
      assert result["name"] == "Juha Halmun kotisivu ja blogi"
      assert result["alternateName"] == "Orangedinos"
      assert result["url"] == url
      assert result["potentialAction"]["@type"] == "SearchAction"
      assert result["potentialAction"]["target"] =~ url
    end
  end

  describe "organization/1" do
    test "generates valid Organization schema" do
      url = "https://example.com"
      result = JsonLD.organization(url)

      assert result["@context"] == "https://schema.org"
      assert result["@type"] == "Organization"
      assert result["name"] == "Juha Halmun kotisivu"
      assert result["url"] == url
      assert result["logo"] =~ url
    end
  end

  describe "faq_page/1" do
    test "generates valid FAQPage schema" do
      faqs = [
        %{question: "What is this?", answer: "A test."},
        %{question: "How does it work?", answer: "Like magic."}
      ]

      result = JsonLD.faq_page(faqs)

      assert result["@context"] == "https://schema.org"
      assert result["@type"] == "FAQPage"
      assert length(result["mainEntity"]) == 2

      [first_q, second_q] = result["mainEntity"]
      assert first_q["@type"] == "Question"
      assert first_q["name"] == "What is this?"
      assert first_q["acceptedAnswer"]["@type"] == "Answer"
      assert first_q["acceptedAnswer"]["text"] == "A test."

      assert second_q["name"] == "How does it work?"
    end

    test "handles empty FAQ list" do
      result = JsonLD.faq_page([])

      assert result["@type"] == "FAQPage"
      assert result["mainEntity"] == []
    end
  end

  describe "article/3" do
    test "generates valid BlogPosting schema" do
      post = %{
        title: "Test Post",
        body: "<p>This is the body</p>",
        published_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now(),
        inserted_at: DateTime.utc_now(),
        featured_image_url: nil
      }

      author = %{
        display_name: "Test Author",
        email: "test@example.com"
      }

      url = "https://example.com/posts/1"

      result = JsonLD.article(post, author, url)

      assert result["@context"] == "https://schema.org"
      assert result["@type"] == "BlogPosting"
      assert result["headline"] == "Test Post"
      assert result["articleBody"] == "This is the body"
      assert result["author"]["name"] == "Test Author"
      assert result["url"] == url
    end

    test "includes image when featured_image_url is set" do
      post = %{
        title: "Test Post",
        body: "Body",
        published_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now(),
        inserted_at: DateTime.utc_now(),
        featured_image_url: "https://example.com/image.jpg"
      }

      author = %{display_name: "Author", email: "test@example.com"}
      url = "https://example.com/posts/1"

      result = JsonLD.article(post, author, url)

      assert result["image"] == "https://example.com/image.jpg"
    end

    test "uses email when display_name is nil" do
      post = %{
        title: "Test",
        body: "Body",
        published_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now(),
        inserted_at: DateTime.utc_now(),
        featured_image_url: nil
      }

      author = %{display_name: nil, email: "test@example.com"}
      url = "https://example.com/posts/1"

      result = JsonLD.article(post, author, url)

      assert result["author"]["name"] == "test@example.com"
    end
  end

  describe "breadcrumbs/2" do
    test "generates valid BreadcrumbList schema" do
      items = [
        {"Home", "/"},
        {"Posts", "/posts"},
        {"My Post", "/posts/1"}
      ]

      result = JsonLD.breadcrumbs(items, "https://example.com")

      assert result["@context"] == "https://schema.org"
      assert result["@type"] == "BreadcrumbList"
      assert length(result["itemListElement"]) == 3

      [first, second, third] = result["itemListElement"]

      assert first["position"] == 1
      assert first["name"] == "Home"
      assert first["item"] == "https://example.com/"

      assert second["position"] == 2
      assert second["name"] == "Posts"

      assert third["position"] == 3
      assert third["name"] == "My Post"
    end
  end

  describe "to_script_tag/1" do
    test "encodes JSON-LD to raw HTML" do
      json_ld = %{"@type" => "WebSite", "name" => "Test"}

      result = JsonLD.to_script_tag(json_ld)

      assert is_struct(result, Phoenix.HTML.Safe) or is_tuple(result)
    end
  end
end
