defmodule Brook.Serializer.Util do
  def safe_reduce(enum, initial, function) do
    Enum.reduce_while(enum, {:ok, initial}, fn item, {:ok, acc} ->
      case function.(item, acc) do
        {:ok, new_acc} -> {:cont, {:ok, new_acc}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  def safe_transform(enum, function) when is_function(function, 1) do
    safe_reduce(enum, [], fn item, acc ->
      function.(item)
      |> safe_map(fn result -> [result | acc] end)
    end)
    |> safe_map(&Enum.reverse/1)
  end

  def safe_map({:ok, value}, function) when is_function(function, 1) do
    case function.(value) do
      {:ok, _} = ok -> ok
      {:error, _} = error -> error
      x -> {:ok, x}
    end
  end

  def safe_map({:error, _reason} = error, _function), do: error

  def to_atom_keys(map) do
    map
    |> Enum.map(fn {key, value} -> {String.to_atom(key), value} end)
    |> Map.new()
  end
end
