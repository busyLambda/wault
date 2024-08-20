defmodule Wault.FsObjectsTags.FsObjectTag do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "fs_object_tags" do
    field :fs_object_id, :id
    field :tag_id, :id
  end

  @doc false
  def changeset(fs_object_tag, attrs) do
    fs_object_tag
    |> cast(attrs, [:fs_object_id, :tag_id])
    |> validate_required([:fs_object_id, :tag_id])
  end
end
