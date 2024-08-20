defmodule Wault.Repo.Migrations.AddFileFieldToFsObjects do
  use Ecto.Migration

  def change do
    alter table(:fs_objects) do
      add :file, :string
    end
  end
end
