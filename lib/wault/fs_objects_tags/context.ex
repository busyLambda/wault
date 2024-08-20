defmodule Wault.FsObjectsTags.Context do
  import Ecto.Query, warn: false

  alias Wault.FsObjectsTags.FsObjectTag
  # alias Wault.FsObjectsTags
  alias Wault.Repo

  def create_fs_object_tag(attrs) do
    %FsObjectTag{}
    |> FsObjectTag.changeset(attrs)
    |> Repo.insert()
  end
end
