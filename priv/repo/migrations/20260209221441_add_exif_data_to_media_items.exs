defmodule Homesite.Repo.Migrations.AddExifDataToMediaItems do
  use Ecto.Migration

  def change do
    alter table(:media_items) do
      add :exif_data, :map, default: %{}
    end
  end
end
