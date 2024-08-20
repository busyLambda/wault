defmodule Wault.Repo.Migrations.CreateFsObjects do
  use Ecto.Migration

  def change do
    create table(:fs_objects) do
      add :name, :string
      add :type, :string
      add :parent_id, references(:fs_objects, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:fs_objects, [:parent_id])
    create index(:fs_objects, [:name])

    create unique_index(:fs_objects, [:name, :parent_id])
  end
end
