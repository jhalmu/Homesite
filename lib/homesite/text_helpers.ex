defmodule Homesite.TextHelpers do
  @moduledoc """
  Text processing utilities for spelling, grammar, and readability.

  Provides functions to analyze text for common issues without
  external service dependencies.
  """

  @doc """
  Checks text for common spelling and grammar issues.

  Returns a list of issues found with their positions and suggestions.

  ## Examples

      iex> TextHelpers.check_text("This is teh quick brown fox.")
      [%{type: :misspelling, word: "teh", position: 8, suggestions: ["the"]}]

  """
  def check_text(text) when is_binary(text) do
    text
    |> String.downcase()
    |> then(&find_issues(&1, text))
  end

  def check_text(nil), do: []

  @doc """
  Returns word count statistics for the given text.

  ## Examples

      iex> TextHelpers.word_stats("Hello world")
      %{word_count: 2, char_count: 11, sentence_count: 0}

  """
  def word_stats(text) when is_binary(text) do
    words =
      text
      |> String.split(~r/\s+/, trim: true)
      |> length()

    sentences =
      text
      |> String.split(~r/[.!?]+/, trim: true)
      |> length()

    %{
      word_count: words,
      char_count: String.length(text),
      sentence_count: sentences
    }
  end

  def word_stats(nil), do: %{word_count: 0, char_count: 0, sentence_count: 0}

  @doc """
  Calculates readability metrics for the given text.

  Returns Flesch Reading Ease score and grade level approximation.

  ## Examples

      iex> TextHelpers.readability("The cat sat on the mat.")
      %{flesch_ease: 116.14, grade_level: "5th grade or below"}

  """
  def readability(text) when is_binary(text) and byte_size(text) > 0 do
    words = String.split(text, ~r/\s+/, trim: true)
    sentences = String.split(text, ~r/[.!?]+/, trim: true)

    word_count = max(length(words), 1)
    sentence_count = max(length(sentences), 1)
    syllable_count = words |> Enum.map(&count_syllables/1) |> Enum.sum() |> max(1)

    # Flesch Reading Ease formula
    flesch_ease =
      206.835 - 1.015 * (word_count / sentence_count) - 84.6 * (syllable_count / word_count)

    %{
      flesch_ease: Float.round(flesch_ease, 2),
      grade_level: flesch_grade_level(flesch_ease)
    }
  end

  def readability(_), do: %{flesch_ease: 0.0, grade_level: "N/A"}

  @doc """
  Checks for repeated words in the text.

  ## Examples

      iex> TextHelpers.find_repeated_words("The the cat sat on on the mat.")
      ["the", "on"]

  """
  def find_repeated_words(text) when is_binary(text) do
    words = String.split(text, ~r/\s+/, trim: true)

    words
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.filter(fn [a, b] -> String.downcase(a) == String.downcase(b) end)
    |> Enum.map(fn [word, _] -> String.downcase(word) end)
    |> Enum.uniq()
  end

  def find_repeated_words(_), do: []

  @doc """
  Finds passive voice constructions in the text.

  Returns a list of phrases that appear to use passive voice.

  ## Examples

      iex> TextHelpers.find_passive_voice("The ball was thrown by John.")
      ["was thrown"]

  """
  def find_passive_voice(text) when is_binary(text) do
    # Simple pattern matching for common passive constructions
    # Match "was/were/is/are/been/being/be" followed by past participle (words ending in -ed, -en, or irregular forms)
    passive_patterns = ~r/(was|were|is|are|been|being|be)\s+(\w+(?:ed|en|wn|nt|t))\b/i

    Regex.scan(passive_patterns, text)
    |> Enum.map(&Enum.at(&1, 0))
  end

  def find_passive_voice(_), do: []

  @doc """
  Finds potentially overused words in the text.

  Returns words that appear more than the threshold percentage of total words.

  ## Examples

      iex> TextHelpers.find_overused_words("very very very very important", threshold: 0.2)
      [%{word: "very", count: 4, percentage: 80.0}]

  """
  def find_overused_words(text, opts \\ [])

  def find_overused_words(nil, _opts), do: []

  def find_overused_words(text, opts) when is_binary(text) do
    threshold = Keyword.get(opts, :threshold, 0.1)
    min_length = Keyword.get(opts, :min_length, 4)

    words =
      text
      |> String.downcase()
      |> String.split(~r/\s+/, trim: true)
      |> Enum.filter(&(String.length(&1) >= min_length))

    total = length(words)

    if total == 0 do
      []
    else
      words
      |> Enum.frequencies()
      |> Enum.filter(fn {_word, count} -> count / total >= threshold end)
      |> Enum.reject(fn {word, _} -> word in common_words() end)
      |> Enum.map(fn {word, count} ->
        %{word: word, count: count, percentage: Float.round(count / total * 100, 1)}
      end)
      |> Enum.sort_by(& &1.count, :desc)
    end
  end

  @doc """
  Suggests improvements for the given text.

  Returns a summary of all issues found.

  ## Examples

      iex> TextHelpers.analyze("This is teh quick brown fox. It was thrown by John.")
      %{
        misspellings: 1,
        repeated_words: 0,
        passive_voice: 1,
        readability: %{flesch_ease: 92.3, grade_level: "5th grade"}
      }

  """
  def analyze(text) when is_binary(text) do
    %{
      issues: check_text(text),
      repeated_words: find_repeated_words(text),
      passive_voice: find_passive_voice(text),
      overused_words: find_overused_words(text),
      readability: readability(text),
      stats: word_stats(text)
    }
  end

  def analyze(_),
    do: %{
      issues: [],
      repeated_words: [],
      passive_voice: [],
      overused_words: [],
      readability: %{},
      stats: %{}
    }

  # Private functions

  defp find_issues(_lowercase_text, original_text) do
    words = String.split(original_text, ~r/\s+/, trim: true)

    words
    |> Enum.with_index()
    |> Enum.flat_map(fn {word, idx} ->
      clean_word = word |> String.downcase() |> String.replace(~r/[^\w]/, "")

      cond do
        clean_word in common_misspellings() ->
          [
            %{
              type: :misspelling,
              word: word,
              index: idx,
              suggestions: get_suggestions(clean_word)
            }
          ]

        is_double_word?(words, idx) ->
          [%{type: :repeated_word, word: word, index: idx, suggestions: ["Remove duplicate"]}]

        true ->
          []
      end
    end)
  end

  defp is_double_word?(words, idx) when idx > 0 do
    current = Enum.at(words, idx) |> String.downcase() |> String.replace(~r/[^\w]/, "")
    prev = Enum.at(words, idx - 1) |> String.downcase() |> String.replace(~r/[^\w]/, "")
    current == prev and String.length(current) > 2
  end

  defp is_double_word?(_, _), do: false

  defp count_syllables(word) do
    word
    |> String.downcase()
    |> String.replace(~r/[^a-z]/, "")
    |> count_vowel_groups()
    |> max(1)
  end

  defp count_vowel_groups(word) do
    word
    |> String.split(~r/[^aeiouy]+/, trim: true)
    |> length()
  end

  defp flesch_grade_level(score) do
    cond do
      score >= 90 -> "5th grade or below"
      score >= 80 -> "6th grade"
      score >= 70 -> "7th grade"
      score >= 60 -> "8th-9th grade"
      score >= 50 -> "10th-12th grade"
      score >= 30 -> "College level"
      true -> "Professional/Graduate level"
    end
  end

  # Common misspellings and their corrections
  defp common_misspellings do
    ~w(
      teh hte adn nad thnig thign wiht wtih becuase beacuse
      recieve recive definately definitly seperate seperete
      occured occassion accomodate accross acheive arguement
      beleive buisness calender catagory cemetry collegue
      comming commitee completly concious definatly desparate
      dissapear dissapoint embarass enviroment existance experiance
      familar finaly foriegn fourty freind generaly goverment
      grammer guarentee harass heighth independant interupt
      knowlege liason libary lisence maintenence millenium
      miniscule mispell neccessary noticable occassionaly occurence
      oppurtunity paralel parliment perseverence personel posession
      potatos preceed predjudice privelege professer progam
      pronounciation publically questionaire realy refered relevent
      religous rember rythm scedule seize sentance sieze similer
      successfull supercede suprise thier tommorow truely untill
      vaccuum wellfare wierd writting yeild
    )
  end

  defp get_suggestions(word) do
    corrections = %{
      "teh" => ["the"],
      "hte" => ["the"],
      "adn" => ["and"],
      "nad" => ["and"],
      "thnig" => ["thing"],
      "thign" => ["thing"],
      "wiht" => ["with"],
      "wtih" => ["with"],
      "becuase" => ["because"],
      "beacuse" => ["because"],
      "recieve" => ["receive"],
      "recive" => ["receive"],
      "definately" => ["definitely"],
      "definitly" => ["definitely"],
      "seperate" => ["separate"],
      "seperete" => ["separate"],
      "occured" => ["occurred"],
      "occassion" => ["occasion"],
      "accomodate" => ["accommodate"],
      "accross" => ["across"],
      "acheive" => ["achieve"],
      "arguement" => ["argument"],
      "beleive" => ["believe"],
      "buisness" => ["business"],
      "calender" => ["calendar"],
      "catagory" => ["category"],
      "cemetry" => ["cemetery"],
      "collegue" => ["colleague"],
      "comming" => ["coming"],
      "commitee" => ["committee"],
      "completly" => ["completely"],
      "concious" => ["conscious"],
      "definatly" => ["definitely"],
      "desparate" => ["desperate"],
      "dissapear" => ["disappear"],
      "dissapoint" => ["disappoint"],
      "embarass" => ["embarrass"],
      "enviroment" => ["environment"],
      "existance" => ["existence"],
      "experiance" => ["experience"],
      "familar" => ["familiar"],
      "finaly" => ["finally"],
      "foriegn" => ["foreign"],
      "fourty" => ["forty"],
      "freind" => ["friend"],
      "generaly" => ["generally"],
      "goverment" => ["government"],
      "grammer" => ["grammar"],
      "guarentee" => ["guarantee"],
      "harass" => ["harass"],
      "heighth" => ["height"],
      "independant" => ["independent"],
      "interupt" => ["interrupt"],
      "knowlege" => ["knowledge"],
      "liason" => ["liaison"],
      "libary" => ["library"],
      "lisence" => ["license"],
      "maintenence" => ["maintenance"],
      "millenium" => ["millennium"],
      "miniscule" => ["minuscule"],
      "mispell" => ["misspell"],
      "neccessary" => ["necessary"],
      "noticable" => ["noticeable"],
      "occassionaly" => ["occasionally"],
      "occurence" => ["occurrence"],
      "oppurtunity" => ["opportunity"],
      "paralel" => ["parallel"],
      "parliment" => ["parliament"],
      "perseverence" => ["perseverance"],
      "personel" => ["personnel"],
      "posession" => ["possession"],
      "potatos" => ["potatoes"],
      "preceed" => ["precede"],
      "predjudice" => ["prejudice"],
      "privelege" => ["privilege"],
      "professer" => ["professor"],
      "progam" => ["program"],
      "pronounciation" => ["pronunciation"],
      "publically" => ["publicly"],
      "questionaire" => ["questionnaire"],
      "realy" => ["really"],
      "refered" => ["referred"],
      "relevent" => ["relevant"],
      "religous" => ["religious"],
      "rember" => ["remember"],
      "rythm" => ["rhythm"],
      "scedule" => ["schedule"],
      "seize" => ["seize"],
      "sentance" => ["sentence"],
      "sieze" => ["seize"],
      "similer" => ["similar"],
      "successfull" => ["successful"],
      "supercede" => ["supersede"],
      "suprise" => ["surprise"],
      "thier" => ["their"],
      "tommorow" => ["tomorrow"],
      "truely" => ["truly"],
      "untill" => ["until"],
      "vaccuum" => ["vacuum"],
      "wellfare" => ["welfare"],
      "wierd" => ["weird"],
      "writting" => ["writing"],
      "yeild" => ["yield"]
    }

    Map.get(corrections, word, [])
  end

  defp common_words do
    ~w(
      that this with have from they will been more when
      what there their which would about into could some
      than like time just over such make only also your
      come take most know want give back them very then
      think well look only come made find here many
      through where much before after first work three
      good even those after these however down during
    )
  end
end
