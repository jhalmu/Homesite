defmodule Homesite.TextHelpersTest do
  use ExUnit.Case, async: true

  alias Homesite.TextHelpers

  describe "check_text/1" do
    test "detects common misspellings" do
      issues = TextHelpers.check_text("This is teh quick brown fox.")
      assert length(issues) > 0

      misspelling = Enum.find(issues, &(&1.type == :misspelling))
      assert misspelling.word == "teh"
      assert "the" in misspelling.suggestions
    end

    test "detects multiple misspellings" do
      issues = TextHelpers.check_text("Teh quick brown fox wiht big ears.")

      misspellings = Enum.filter(issues, &(&1.type == :misspelling))
      words = Enum.map(misspellings, & &1.word) |> Enum.map(&String.downcase/1)

      assert "teh" in words
      assert "wiht" in words
    end

    test "returns empty list for correct text" do
      issues = TextHelpers.check_text("This is correct text.")
      misspellings = Enum.filter(issues, &(&1.type == :misspelling))
      assert misspellings == []
    end

    test "handles nil input" do
      assert TextHelpers.check_text(nil) == []
    end

    test "handles empty string" do
      assert TextHelpers.check_text("") == []
    end
  end

  describe "word_stats/1" do
    test "counts words correctly" do
      stats = TextHelpers.word_stats("Hello world, how are you?")
      assert stats.word_count == 5
    end

    test "counts characters correctly" do
      stats = TextHelpers.word_stats("Hello")
      assert stats.char_count == 5
    end

    test "counts sentences correctly" do
      stats = TextHelpers.word_stats("Hello world. How are you? I am fine!")
      assert stats.sentence_count == 3
    end

    test "handles nil input" do
      stats = TextHelpers.word_stats(nil)
      assert stats.word_count == 0
      assert stats.char_count == 0
      assert stats.sentence_count == 0
    end

    test "handles empty string" do
      stats = TextHelpers.word_stats("")
      assert stats.word_count == 0
    end
  end

  describe "readability/1" do
    test "returns flesch ease score" do
      result = TextHelpers.readability("The cat sat on the mat.")
      assert is_float(result.flesch_ease)
    end

    test "returns grade level" do
      result = TextHelpers.readability("The cat sat on the mat.")
      assert is_binary(result.grade_level)
    end

    test "simple text has high flesch ease" do
      result = TextHelpers.readability("The cat sat on the mat. The dog ran in the park.")
      assert result.flesch_ease > 60
    end

    test "handles nil input" do
      result = TextHelpers.readability(nil)
      assert result.grade_level == "N/A"
    end

    test "handles empty string" do
      result = TextHelpers.readability("")
      assert result.grade_level == "N/A"
    end
  end

  describe "find_repeated_words/1" do
    test "finds repeated consecutive words" do
      repeated = TextHelpers.find_repeated_words("The the cat sat on on the mat.")
      assert "the" in repeated
      assert "on" in repeated
    end

    test "returns empty list when no repetition" do
      repeated = TextHelpers.find_repeated_words("The quick brown fox jumps.")
      assert repeated == []
    end

    test "handles nil input" do
      assert TextHelpers.find_repeated_words(nil) == []
    end

    test "handles case insensitivity" do
      repeated = TextHelpers.find_repeated_words("The THE cat")
      assert "the" in repeated
    end
  end

  describe "find_passive_voice/1" do
    test "detects was + past participle ending in -wn" do
      passive = TextHelpers.find_passive_voice("The ball was thrown by John.")
      assert length(passive) > 0
      assert Enum.any?(passive, &(&1 =~ "was thrown"))
    end

    test "detects is + past participle ending in -en" do
      passive = TextHelpers.find_passive_voice("The report is written by the team.")
      assert length(passive) > 0
    end

    test "detects was + past participle ending in -ed" do
      passive = TextHelpers.find_passive_voice("The letter was delivered yesterday.")
      assert length(passive) > 0
      assert Enum.any?(passive, &(&1 =~ "was delivered"))
    end

    test "returns empty list for active voice" do
      passive = TextHelpers.find_passive_voice("John threw the ball.")
      assert passive == []
    end

    test "handles nil input" do
      assert TextHelpers.find_passive_voice(nil) == []
    end
  end

  describe "find_overused_words/2" do
    test "finds words used more than threshold" do
      # Using 5-letter word to pass min_length check
      overused =
        TextHelpers.find_overused_words(
          "great great great great great thing",
          threshold: 0.2
        )

      assert length(overused) > 0
      assert Enum.any?(overused, &(&1.word == "great"))
    end

    test "returns percentage" do
      overused =
        TextHelpers.find_overused_words(
          "great great great great thing",
          threshold: 0.2
        )

      word = Enum.find(overused, &(&1.word == "great"))
      assert word.percentage == 80.0
    end

    test "respects min_length option" do
      # "the" is 3 letters, should be ignored with min_length: 4
      overused =
        TextHelpers.find_overused_words("the the the the important",
          threshold: 0.2,
          min_length: 4
        )

      refute Enum.any?(overused, &(&1.word == "the"))
    end

    test "excludes common words" do
      overused = TextHelpers.find_overused_words("that that that that important", threshold: 0.2)
      refute Enum.any?(overused, &(&1.word == "that"))
    end

    test "handles nil input" do
      assert TextHelpers.find_overused_words(nil) == []
    end
  end

  describe "analyze/1" do
    test "returns comprehensive analysis" do
      result = TextHelpers.analyze("This is teh quick brown fox. It was thrown by John.")

      assert Map.has_key?(result, :issues)
      assert Map.has_key?(result, :repeated_words)
      assert Map.has_key?(result, :passive_voice)
      assert Map.has_key?(result, :overused_words)
      assert Map.has_key?(result, :readability)
      assert Map.has_key?(result, :stats)
    end

    test "includes misspellings in issues" do
      result = TextHelpers.analyze("This is teh quick brown fox.")
      assert Enum.any?(result.issues, &(&1.type == :misspelling))
    end

    test "includes passive voice" do
      result = TextHelpers.analyze("The ball was thrown by John.")
      assert length(result.passive_voice) > 0
    end

    test "includes stats" do
      result = TextHelpers.analyze("Hello world.")
      assert result.stats.word_count == 2
    end

    test "handles nil input" do
      result = TextHelpers.analyze(nil)
      assert result.issues == []
      assert result.repeated_words == []
    end
  end

  describe "specific misspelling corrections" do
    test "suggests 'because' for 'becuase'" do
      issues = TextHelpers.check_text("I did it becuase I wanted to.")
      misspelling = Enum.find(issues, &(&1.type == :misspelling && &1.word == "becuase"))
      assert "because" in misspelling.suggestions
    end

    test "suggests 'definitely' for 'definately'" do
      issues = TextHelpers.check_text("I will definately do it.")
      misspelling = Enum.find(issues, &(&1.type == :misspelling && &1.word == "definately"))
      assert "definitely" in misspelling.suggestions
    end

    test "suggests 'separate' for 'seperate'" do
      issues = TextHelpers.check_text("We need to seperate these items.")
      misspelling = Enum.find(issues, &(&1.type == :misspelling && &1.word == "seperate"))
      assert "separate" in misspelling.suggestions
    end

    test "suggests 'receive' for 'recieve'" do
      issues = TextHelpers.check_text("I will recieve the package tomorrow.")
      misspelling = Enum.find(issues, &(&1.type == :misspelling && &1.word == "recieve"))
      assert "receive" in misspelling.suggestions
    end

    test "suggests 'their' for 'thier'" do
      issues = TextHelpers.check_text("It is thier responsibility.")
      misspelling = Enum.find(issues, &(&1.type == :misspelling && &1.word == "thier"))
      assert "their" in misspelling.suggestions
    end
  end
end
