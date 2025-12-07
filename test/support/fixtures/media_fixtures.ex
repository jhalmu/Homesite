defmodule Homesite.MediaFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Homesite.Media` context.
  """

  @doc """
  Generate a unique gallery name.
  """
  def unique_gallery_name, do: "gallery #{System.unique_integer([:positive])}"

  @doc """
  Generate a unique media item filename.
  """
  def unique_filename, do: "image-#{System.unique_integer([:positive])}.jpg"

  @doc """
  Creates a minimal valid test image using ImageMagick.
  Returns the path to the temp file (caller must clean up).
  Requires ImageMagick to be installed.
  """
  def create_test_image(filename \\ nil) do
    filename = filename || "test-#{System.unique_integer([:positive])}.jpg"
    temp_path = Path.join(System.tmp_dir!(), filename)

    # Check if ImageMagick is available
    case System.find_executable("convert") do
      nil ->
        raise "ImageMagick 'convert' command not found. Install ImageMagick to run image tests."

      convert_path ->
        # Create a simple 100x100 red square using ImageMagick
        {_output, 0} =
          System.cmd(convert_path, [
            "-size",
            "100x100",
            "xc:red",
            temp_path
          ])

        temp_path
    end
  end

  @doc """
  Checks if ImageMagick is available for image processing tests.
  """
  def imagemagick_available? do
    System.find_executable("convert") != nil
  end

  @doc """
  Generate a gallery.
  """
  def gallery_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        name: unique_gallery_name(),
        description: "Test gallery description",
        slug: "will-be-generated",
        is_public: true
      })

    {:ok, gallery} = Homesite.Media.create_gallery(scope, attrs)
    gallery
  end

  @doc """
  Generate a media item with processed image data.
  Creates a real image file, processes it, and creates the media item.
  """
  def media_item_fixture(scope, attrs \\ %{}) do
    # Create a temporary test image
    temp_path = create_test_image()

    attrs =
      Enum.into(attrs, %{
        original_filename: unique_filename(),
        alt_text: "Test image",
        title: "Test Image #{System.unique_integer([:positive])}",
        content_type: "image/jpeg"
      })

    # Upload and process the image
    {:ok, media_item} =
      Homesite.Media.upload_media(scope, temp_path, "image/jpeg", attrs)

    # Clean up temp file
    File.rm(temp_path)

    media_item
  end

  @doc """
  Generate a media item with minimal attributes (no title/caption).
  """
  def minimal_media_item_fixture(scope, attrs \\ %{}) do
    temp_path = create_test_image()

    attrs =
      Enum.into(attrs, %{
        original_filename: unique_filename(),
        alt_text: "Test image",
        content_type: "image/jpeg"
      })

    {:ok, media_item} =
      Homesite.Media.upload_media(scope, temp_path, "image/jpeg", attrs)

    File.rm(temp_path)
    media_item
  end
end
