defmodule Wault.Repo.Migrations.CreateFsObjectTags do
  use Ecto.Migration

  def change do
    create table(:fs_object_tags, primary_key: false) do
      add :fs_object_id, references(:fs_objects, on_delete: :delete_all), null: false, primary_key: true
      add :tag_id, references(:tags, on_delete: :delete_all), null: false, primary_key: true
    end

    create index(:fs_object_tags, [:fs_object_id])
    create index(:fs_object_tags, [:tag_id])

    create unique_index(:fs_object_tags, [:fs_object_id, :tag_id])
  end
end
