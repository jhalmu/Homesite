defmodule Homesite.Accounts.AvatarGenerator do
  @moduledoc """
  Generates SVG avatars for users who haven't uploaded a custom avatar.

  Creates circular avatars with user initials and deterministic colors
  based on the user's ID, ensuring consistency across sessions.
  """

  @doc """
  Generates an SVG avatar for a user.

  Returns a data URL that can be used directly in img src attributes.

  ## Examples

      iex> generate_avatar(%User{id: 1, display_name: "John Doe"})
      "data:image/svg+xml;charset=utf-8,<svg>...</svg>"

      iex> generate_avatar(%User{id: 1, email: "jane@example.com"})
      "data:image/svg+xml;charset=utf-8,<svg>...</svg>"
  """
  def generate_avatar(user) do
    initials = get_initials(user)
    {bg_color, text_color} = get_colors(user.id)

    svg =
      """
      <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100">
        <circle cx="50" cy="50" r="50" fill="#{bg_color}"/>
        <text
          x="50"
          y="50"
          font-family="sans-serif"
          font-size="40"
          font-weight="600"
          fill="#{text_color}"
          text-anchor="middle"
          dominant-baseline="central"
        >#{initials}</text>
      </svg>
      """
      |> String.replace("\n", "")
      |> String.replace("  ", "")

    "data:image/svg+xml;charset=utf-8,#{URI.encode(svg)}"
  end

  defp get_initials(%{display_name: name}) when is_binary(name) and name != "" do
    name
    |> String.split()
    |> Enum.take(2)
    |> Enum.map_join("", &String.first/1)
    |> String.upcase()
  end

  defp get_initials(%{email: email}) do
    email
    |> String.split("@")
    |> List.first()
    |> String.first()
    |> String.upcase()
  end

  defp get_colors(user_id) do
    # DaisyUI-inspired color palette (HSL for consistency)
    # Each user gets a deterministic color based on their ID
    colors = [
      # Purple
      {"hsl(259 94% 51%)", "#ffffff"},
      # Sky blue
      {"hsl(198 93% 60%)", "#ffffff"},
      # Teal
      {"hsl(158 64% 52%)", "#ffffff"},
      # Green
      {"hsl(141 50% 58%)", "#ffffff"},
      # Yellow
      {"hsl(48 95% 53%)", "#1f2937"},
      # Orange
      {"hsl(31 92% 62%)", "#ffffff"},
      # Pink
      {"hsl(351 95% 71%)", "#ffffff"},
      # Red
      {"hsl(0 72% 51%)", "#ffffff"}
    ]

    index = rem(user_id, length(colors))
    Enum.at(colors, index)
  end
end
