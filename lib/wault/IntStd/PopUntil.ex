defmodule Wault.IntStd.PopUntil do
  # ([value], fn value -> bool) -> [value]
  def pop_until([], _predicate) do
    []
  end

  def pop_until([head | []], predicate) do
    case predicate.(head) do
      true ->
        [head]

      false ->
        []
    end
  end

  def pop_until([head | rem], predicate) do
    case predicate.(head) do
      true -> [head | rem]
      false -> pop_until(rem, predicate)
    end
  end
end
