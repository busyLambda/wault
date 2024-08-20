defmodule Wault.FsObjects.Context do
  import Ecto.Query

  alias Wault.FsObjects.FsObject
  alias Wault.Repo

  import Wault.FsObjectsTags.Context, only: [create_fs_object_tag: 1], warn: false
  import Wault.Tags.Context, only: [create_non_existing_tags: 1, get_tags_by_name: 1], warn: false

  def create_fs_object(attrs, tags) do
    {:ok, fs_object} =
      %FsObject{}
      |> FsObject.changeset(attrs)
      |> Repo.insert()

    create_non_existing_tags(tags)

    tags = get_tags_by_name(tags)

    Enum.each(tags, fn tag ->
      assoc = %{tag_id: tag.id, fs_object_id: fs_object.id}
      create_fs_object_tag(assoc)
    end)
  end

  def get_fs_object_by_id(id) do
    Repo.get(FsObject, id)
  end

  def get_fs_object_children(%{type: "dir", id: id}, filters) do
    query =
      from(f in FsObject)
      |> where([f], f.parent_id == ^id)
      |> apply_filters(filters)

    Repo.all(query)
  end

  def get_fs_object_children(%{type: "file"}, _filters) do
    {:error, "Attempted to get children of a file object"}
  end

  def apply_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {"name", name}, query -> where(query, [f], like(f.name, ^"%#{name}%"))
      {"type", type}, query -> where(query, [f], f.type == ^type)
      {"order", "newest"}, query -> order_by(query, [f], desc: f.inserted_at)
      {"order", "oldest"}, query -> order_by(query, [f], asc: f.inserted_at)
      {:tags, {[], []}}, query -> query
      {:tags, {include, exclude}}, query -> apply_tag_filters(query, include, exclude)
      {_key, _value}, query -> query
    end)
  end

  @doc """
  Find all fs_objects that have all of the included tags and none of the excluded tags
  """
  def apply_tag_filters(query, include, exclude) do
    query
    |> join(:inner, [f], ta in assoc(f, :tags))
    |> group_by([f], f.id)
    |> having([f, ta], fragment("array_agg(?) @> ?", ta.name, ^include))
    |> having([f, ta], fragment("array_agg(?) && ? = false", ta.name, ^exclude))
  end

  def go_back(%{parent_id: parent_id}) when not is_nil(parent_id) do
    case Repo.get(FsObject, parent_id) do
      nil -> {:error, "Parent not found"}
      parent -> {:ok, parent}
    end
  end

  def go_back(%{parent_id: nil}) do
    {:error, "Attempted to go back from root"}
  end

  def get_root() do
    Repo.one(from(f in FsObject, where: is_nil(f.parent_id)))
  end

  def get_object_via_path(nil, []) do
    case get_root() do
      nil -> {:error, "Root not found"}
      root -> {:ok, root}
    end
  end

  def get_object_via_path(nil, path) do
    case get_root() do
      nil -> {:error, "Root not found"}
      root -> get_object_via_path(root, path)
    end
  end

  def get_object_via_path(from, [name | []]) do
    case get_child_by_name(from, name) do
      nil -> {:error, "Path not found"}
      child -> {:ok, child}
    end
  end

  def get_object_via_path(from, [name | rest]) do
    case get_child_by_name(from, name) do
      nil -> {:error, "Path not found"}
      child -> get_object_via_path(child, rest)
    end
  end

  def get_child_by_name(parent, name) do
    query =
      from(f in FsObject)
      |> where([f], f.parent_id == ^parent.id and f.name == ^name)
      |> preload(:tags)

    Repo.one(query)
  end

  def delete_fs_object(%{type: "dir", id: id, parent_id: parent_id})
      when not is_nil(parent_id) do
    query = from(f in FsObject, where: f.id == ^id)
    Repo.delete_all(query)
  end

  def delete_fs_object(%{type: "dir", parent_id: nil}) do
    {:error, "Attempted to delete root"}
  end

  def delete_fs_object(%{type: "file"} = fs_object) do
    fs_object |> Repo.delete()
  end

  # walk the tree from object to root, producting => [{name, id}]
  def get_nav_stack_from_object(%{parent_id: nil}) do
    []
  end

  def get_nav_stack_from_object(%{parent_id: parent_id} = fs_object) do
    case get_fs_object_by_id(parent_id) do
      nil -> {:error, "Parent not found"}
      parent -> [{fs_object.name, fs_object.id} | get_nav_stack_from_object(parent)]
    end
  end

  def short_dest(["live_view_upload" | file]) do
    file
  end
end
