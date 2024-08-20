defmodule Wault.FsObjects.FsObject do
  use Ecto.Schema

  import Ecto.Changeset

  schema "fs_objects" do
    field :name, :string
    field :type, :string
    field :parent_id, :id
    field :file, :string

    many_to_many :tags, Wault.Tags.Tag, join_through: "fs_object_tags"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(fs_object, attrs) do
    fs_object
    |> cast(attrs, [:name, :type, :parent_id, :file])
    |> validate_required([:name, :type])
    |> foreign_key_constraint(:parent_id)
  end
end
