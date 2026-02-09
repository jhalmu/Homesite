defmodule Homesite.Media.ImageProcessorTest do
  use ExUnit.Case, async: true

  alias Homesite.Media.ImageProcessor

  describe "extract_exif/1" do
    import Homesite.MediaFixtures, only: [create_test_image: 1]

    test "should return empty map for PNG without EXIF" do
      # Create a minimal valid PNG file (1x1 pixel, blue)
      temp_path =
        Path.join(System.tmp_dir!(), "test-exif-#{System.unique_integer([:positive])}.png")

      # Minimal 1x1 blue PNG (valid binary)
      png_header = <<137, 80, 78, 71, 13, 10, 26, 10>>

      ihdr_data = <<0, 0, 0, 1, 0, 0, 0, 1, 8, 2, 0, 0, 0>>
      ihdr_crc = :erlang.crc32(<<"IHDR", ihdr_data::binary>>)
      ihdr = <<13::32, "IHDR", ihdr_data::binary, ihdr_crc::32>>

      raw_data = <<0, 0, 0, 255>>
      compressed = :zlib.compress(raw_data)
      idat_crc = :erlang.crc32(<<"IDAT", compressed::binary>>)
      idat = <<byte_size(compressed)::32, "IDAT", compressed::binary, idat_crc::32>>

      iend_crc = :erlang.crc32("IEND")
      iend = <<0::32, "IEND", iend_crc::32>>

      File.write!(temp_path, png_header <> ihdr <> idat <> iend)

      result = ImageProcessor.extract_exif(temp_path)
      assert result == %{}

      File.rm(temp_path)
    end

    test "should return empty map for non-existent file" do
      result =
        ImageProcessor.extract_exif(
          "/tmp/nonexistent-file-#{System.unique_integer([:positive])}.jpg"
        )

      assert result == %{}
    end

    test "should return empty map for test JPEG without EXIF" do
      temp_path = create_test_image("exif-test-noexif.jpg")
      result = ImageProcessor.extract_exif(temp_path)
      # Simple ImageMagick-generated images have no EXIF
      assert result == %{}
      File.rm(temp_path)
    end

    @tag :exiftool
    test "should extract EXIF from JPEG with embedded EXIF data" do
      temp_path =
        Path.join(System.tmp_dir!(), "test-with-exif-#{System.unique_integer([:positive])}.jpg")

      # Create a JPEG
      {_, 0} = System.cmd("magick", ["-size", "100x100", "xc:green", temp_path])

      # Inject EXIF data using exiftool
      {_, 0} =
        System.cmd("exiftool", [
          "-overwrite_original",
          "-Make=FUJIFILM",
          "-Model=X-T5",
          "-FocalLength=25",
          "-ISO=3200",
          "-FNumber=2.8",
          "-ExposureTime=1/125",
          "-DateTimeOriginal=2025:11:09 17:38:53",
          temp_path
        ])

      result = ImageProcessor.extract_exif(temp_path)

      assert result["camera_make"] == "FUJIFILM"
      assert result["camera_model"] == "X-T5"
      assert result["focal_length"] == 25
      assert result["iso"] == 3200
      assert result["aperture"] == 2.8
      assert result["shutter_speed"] == "1/125"
      assert result["date_taken"] == "2025-11-09T17:38:53"

      File.rm(temp_path)
    end
  end

  describe "parse_exif_rational/1" do
    test "should parse simple fraction" do
      assert ImageProcessor.parse_exif_rational("25/1") == 25
    end

    test "should parse decimal fraction" do
      assert ImageProcessor.parse_exif_rational("28/10") == 2.8
    end

    test "should parse single number" do
      assert ImageProcessor.parse_exif_rational("50") == 50
    end

    test "should return nil for nil" do
      assert ImageProcessor.parse_exif_rational(nil) == nil
    end

    test "should return nil for empty string" do
      assert ImageProcessor.parse_exif_rational("") == nil
    end

    test "should handle zero denominator" do
      assert ImageProcessor.parse_exif_rational("10/0") == nil
    end
  end

  describe "parse_exif_datetime/1" do
    test "should parse EXIF datetime format" do
      assert ImageProcessor.parse_exif_datetime("2025:11:09 17:38:53") ==
               "2025-11-09T17:38:53"
    end

    test "should return nil for nil" do
      assert ImageProcessor.parse_exif_datetime(nil) == nil
    end

    test "should return nil for empty string" do
      assert ImageProcessor.parse_exif_datetime("") == nil
    end

    test "should return nil for invalid format" do
      assert ImageProcessor.parse_exif_datetime("not a date") == nil
    end
  end
end
