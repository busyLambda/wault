defmodule Wault.Tags.Context do
  import Ecto.Query

  alias Wault.Tags.Tag
  alias Wault.Repo

  def create_non_existing_tags(tags) do
    tags
    |> Enum.map(&check_existance(&1))
    |> Enum.filter(&(not is_nil(&1)))
    |> Enum.map(
      &case create_tag(%{name: &1}) do
        {:ok, tag} -> tag
        {:error, _} -> nil
      end
    )
  end

  def check_existance(name) do
    case Repo.get_by(Tag, name: name) do
      nil -> name
      _tag -> nil
    end
  end

  def create_tag(attrs) do
    %Tag{}
    |> Tag.changeset(attrs)
    |> Repo.insert()
  end

  def search_tags(query) do
    from(t in Tag, where: like(t.name, ^"%#{query}%"))
    |> Repo.all()
  end

  def get_tags_by_name(names) do
    from(t in Tag)
    |> where([t], t.name in ^names)
    |> Repo.all()
  end
end
