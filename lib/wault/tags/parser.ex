defmodule Wault.Tags.Parser do
  @doc """
  Parses a string into a tuple of two lists: the first list contains the tags to include, and the second list contains the tags to exclude.
  """
  def parse(input) do
    input
    |> String.split(" ")
    |> parse_tag()
  end

  # {[string], [string]} -> {[string], [string]}
  def parse_tag([first_elem | rest]) do
    case first_elem do
      "-" <> tag ->
        next_tag = parse_tag(rest)
        {elem(next_tag, 0), [tag | elem(next_tag, 1)]}
      tag ->
        next_tag = parse_tag(rest)
        {[tag | elem(next_tag, 0)], elem(next_tag, 1)}
    end
  end

  def parse_tag([]) do
    {[], []}
  end
end
