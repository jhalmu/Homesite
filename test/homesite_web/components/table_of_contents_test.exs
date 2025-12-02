defmodule HomesiteWeb.Components.TableOfContentsTest do
  use ExUnit.Case, async: true

  alias HomesiteWeb.Components.TableOfContents

  describe "extract_headings/1" do
    test "extracts h2 and h3 headings from HTML" do
      html = """
      <article>
        <h2 id="intro">Introduction</h2>
        <p>Some content</p>
        <h3 id="details">Details</h3>
        <p>More content</p>
        <h2 id="conclusion">Conclusion</h2>
      </article>
      """

      headings = TableOfContents.extract_headings(html)

      assert [
               %{level: 2, text: "Introduction", id: "intro", children: children1},
               %{level: 2, text: "Conclusion", id: "conclusion", children: []}
             ] = headings

      assert [%{level: 3, text: "Details", id: "details"}] = children1
    end

    test "generates IDs for headings without them" do
      html = """
      <h2>Getting Started</h2>
      <h3>Installation</h3>
      """

      headings = TableOfContents.extract_headings(html)

      assert [
               %{
                 level: 2,
                 text: "Getting Started",
                 id: "getting-started",
                 children: children
               }
             ] = headings

      assert [%{level: 3, text: "Installation", id: "installation"}] = children
    end

    test "handles special characters in heading text" do
      html = """
      <h2>FAQ: What's New?</h2>
      <h3>Phoenix 1.8 & LiveView</h3>
      """

      headings = TableOfContents.extract_headings(html)

      assert [
               %{
                 level: 2,
                 text: "FAQ: What's New?",
                 id: "faq-whats-new",
                 children: children
               }
             ] = headings

      assert [%{level: 3, text: "Phoenix 1.8 & LiveView", id: "phoenix-18-liveview"}] = children
    end

    test "returns empty list for HTML with no headings" do
      html = """
      <article>
        <p>Just some text</p>
        <div>No headings here</div>
      </article>
      """

      assert TableOfContents.extract_headings(html) == []
    end

    test "returns empty list for invalid HTML" do
      assert TableOfContents.extract_headings("invalid<html") == []
      assert TableOfContents.extract_headings(nil) == []
      assert TableOfContents.extract_headings("") == []
    end

    test "handles orphan h3 (no parent h2)" do
      html = """
      <h3 id="orphan">Orphan H3</h3>
      <h2 id="section">Section</h2>
      """

      headings = TableOfContents.extract_headings(html)

      # Orphan h3 should be treated as top-level
      assert [
               %{level: 3, text: "Orphan H3", id: "orphan"},
               %{level: 2, text: "Section", id: "section", children: []}
             ] = headings
    end

    test "handles multiple h3s under one h2" do
      html = """
      <h2 id="main">Main Section</h2>
      <h3 id="sub1">Subsection 1</h3>
      <h3 id="sub2">Subsection 2</h3>
      <h3 id="sub3">Subsection 3</h3>
      """

      headings = TableOfContents.extract_headings(html)

      assert [
               %{level: 2, text: "Main Section", id: "main", children: children}
             ] = headings

      assert length(children) == 3
      assert Enum.map(children, & &1.text) == ["Subsection 1", "Subsection 2", "Subsection 3"]
    end

    test "ignores h1, h4, h5, h6 headings" do
      html = """
      <h1>Page Title</h1>
      <h2 id="section">Section</h2>
      <h4>Ignored H4</h4>
      <h5>Ignored H5</h5>
      <h6>Ignored H6</h6>
      """

      headings = TableOfContents.extract_headings(html)

      assert [%{level: 2, text: "Section", id: "section", children: []}] = headings
    end

    test "handles nested HTML in headings" do
      html = """
      <h2 id="code">Using <code>Phoenix</code></h2>
      <h3>With <em>emphasis</em></h3>
      """

      headings = TableOfContents.extract_headings(html)

      assert [
               %{level: 2, text: "Using Phoenix", id: "code", children: children}
             ] = headings

      assert [%{level: 3, text: "With emphasis"}] = children
    end
  end

  describe "add_heading_ids/1" do
    test "adds IDs to headings without them" do
      html = """
      <h2>Introduction</h2>
      <p>Content</p>
      <h3>Details</h3>
      """

      result = TableOfContents.add_heading_ids(html)

      assert result =~ ~s(<h2 id="introduction">Introduction</h2>)
      assert result =~ ~s(<h3 id="details">Details</h3>)
    end

    test "preserves existing IDs" do
      html = """
      <h2 id="custom-id">Section</h2>
      <h3>Subsection</h3>
      """

      result = TableOfContents.add_heading_ids(html)

      assert result =~ ~s(<h2 id="custom-id">Section</h2>)
      assert result =~ ~s(<h3 id="subsection">Subsection</h3>)
    end

    test "handles non-string input" do
      assert TableOfContents.add_heading_ids(nil) == nil
      assert TableOfContents.add_heading_ids(123) == 123
    end

    test "handles invalid HTML gracefully" do
      invalid_html = "<h2>Broken<h2"
      result = TableOfContents.add_heading_ids(invalid_html)

      # Floki repairs broken HTML and adds IDs
      assert result =~ ~s(id="broken")
    end

    test "adds IDs to all heading levels" do
      html = """
      <h1>Main Title</h1>
      <h2>Section</h2>
      <h3>Subsection</h3>
      <h4>Detail</h4>
      <h5>Note</h5>
      <h6>Fine Print</h6>
      """

      result = TableOfContents.add_heading_ids(html)

      assert result =~ ~s(id="main-title")
      assert result =~ ~s(id="section")
      assert result =~ ~s(id="subsection")
      assert result =~ ~s(id="detail")
      assert result =~ ~s(id="note")
      assert result =~ ~s(id="fine-print")
    end
  end

  describe "slugify (via generated IDs)" do
    test "converts text to lowercase" do
      html = "<h2>UPPERCASE TEXT</h2>"
      headings = TableOfContents.extract_headings(html)

      assert [%{id: "uppercase-text"}] = headings
    end

    test "replaces spaces with hyphens" do
      html = "<h2>Multiple Word Heading</h2>"
      headings = TableOfContents.extract_headings(html)

      assert [%{id: "multiple-word-heading"}] = headings
    end

    test "removes special characters" do
      html = "<h2>What's New? (2025)</h2>"
      headings = TableOfContents.extract_headings(html)

      assert [%{id: "whats-new-2025"}] = headings
    end

    test "handles emoji and unicode" do
      html = "<h2>🎉 Celebration Time!</h2>"
      headings = TableOfContents.extract_headings(html)

      assert [%{id: "celebration-time"}] = headings
    end

    test "trims leading and trailing hyphens" do
      html = "<h2>---Trimmed---</h2>"
      headings = TableOfContents.extract_headings(html)

      assert [%{id: "trimmed"}] = headings
    end
  end

  describe "edge cases" do
    test "handles very long heading text" do
      long_text = String.duplicate("word ", 50)
      html = "<h2>#{long_text}</h2>"

      headings = TableOfContents.extract_headings(html)

      assert [%{level: 2, text: text, id: id}] = headings
      assert String.length(text) > 200
      assert String.starts_with?(id, "word-word")
    end

    test "handles empty heading text" do
      html = "<h2></h2>"
      headings = TableOfContents.extract_headings(html)

      assert [%{level: 2, text: "", id: ""}] = headings
    end

    test "handles HTML entities" do
      html = "<h2>&lt;Code&gt; Example</h2>"
      headings = TableOfContents.extract_headings(html)

      assert [%{level: 2, text: "<Code> Example"}] = headings
    end

    test "handles complex nested structure" do
      html = """
      <h2 id="s1">Section 1</h2>
      <h3 id="s1-a">Section 1.A</h3>
      <h3 id="s1-b">Section 1.B</h3>
      <h2 id="s2">Section 2</h2>
      <h3 id="s2-a">Section 2.A</h3>
      <h2 id="s3">Section 3</h2>
      """

      headings = TableOfContents.extract_headings(html)

      assert length(headings) == 3

      assert %{id: "s1", children: [%{id: "s1-a"}, %{id: "s1-b"}]} = Enum.at(headings, 0)
      assert %{id: "s2", children: [%{id: "s2-a"}]} = Enum.at(headings, 1)
      assert %{id: "s3", children: []} = Enum.at(headings, 2)
    end

    test "handles consecutive h3s without parent h2" do
      html = """
      <h3 id="orphan1">Orphan 1</h3>
      <h3 id="orphan2">Orphan 2</h3>
      <h2 id="section">Section</h2>
      """

      headings = TableOfContents.extract_headings(html)

      assert [
               %{level: 3, id: "orphan1"},
               %{level: 3, id: "orphan2"},
               %{level: 2, id: "section", children: []}
             ] = headings
    end
  end
end
