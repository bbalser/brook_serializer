defprotocol Brook.Deserializer.Protocol do
  @moduledoc """
  The protocol for standard de-serialization of Elixir structs passed
  through the Brook event stream for decoding from the in-transit format.

  Brook drivers are expected to implement a default de-serializer for
  converting from a given encoding to an Elixir struct, leaving the client
  the option to implement a custom de-serializer for specific struct types.
  """
  @type t :: term()
  @type reason :: term()
  @fallback_to_any true

  @doc """
  Convert the given encoded term to an instance of the supplied struct
  type.
  """
  @spec deserialize(t(), term()) :: {:ok, term()} | {:error, reason()}
  def deserialize(struct, data)
end

defimpl Brook.Deserializer.Protocol, for: Any do
  @moduledoc """
  Provide a default implementation for the `Brook.Event.Deserializer`
  protocol that will decode the supplied json to an instance of
  the provided struct.
  """

  def deserialize(%struct_module{}, data) do
    case function_exported?(struct_module, :new, 1) do
      true -> struct_module.new(data) |> wrap()
      false -> {:ok, struct(struct_module, data)}
    end
  end

  defp wrap({:ok, _} = ok), do: ok
  defp wrap({:error, _} = error), do: error
  defp wrap(value), do: {:ok, value}
end

defimpl Brook.Deserializer.Protocol, for: MapSet do
  def deserialize(_, %{values: values}) do
    {:ok, MapSet.new(values)}
  end
end

defimpl Brook.Deserializer.Protocol, for: DateTime do
  def deserialize(_, %{value: value}) do
    {:ok, date_time, _} = DateTime.from_iso8601(value)
    {:ok, date_time}
  end
end

defimpl Brook.Deserializer.Protocol, for: NaiveDateTime do
  def deserialize(_, %{value: value}) do
    NaiveDateTime.from_iso8601(value)
  end
end

defimpl Brook.Deserializer.Protocol, for: Date do
  def deserialize(_, %{value: value}) do
    Date.from_iso8601(value)
  end
end

defimpl Brook.Deserializer.Protocol, for: Time do
  def deserialize(_, %{value: value}) do
    Time.from_iso8601(value)
  end
end

defmodule Brook.Deserializer do
  import Brook.Serializer.Util

  defmodule Internal do
    @struct_key "__brook_struct__"
    def do_deserialize(%{@struct_key => struct} = data) do
      struct_module = struct |> String.to_atom()
      Code.ensure_loaded(struct_module)

      case function_exported?(struct_module, :__struct__, 0) do
        true ->
          struct = struct(struct_module)

          data
          |> Map.delete(@struct_key)
          |> to_atom_keys()
          |> safe_transform(fn {key, value} ->
            Brook.Deserializer.Internal.do_deserialize(value)
            |> safe_map(fn new_value -> {key, new_value} end)
          end)
          |> safe_map(&Map.new/1)
          |> safe_map(&Brook.Deserializer.Protocol.deserialize(struct, &1))

        false ->
          {:error, :invalid_struct}
      end
    end

    def do_deserialize(%{"keyword" => true, "list" => list}) do
      {:ok, list} = do_deserialize(list)

      keyword_list =
        Enum.map(list, fn [key, val] ->
          {String.to_atom(key), val}
        end)

      {:ok, keyword_list}
    end

    def do_deserialize(%{} = data) do
      data
      |> safe_transform(fn {key, value} ->
        do_deserialize(value)
        |> safe_map(fn new_value -> {key, new_value} end)
      end)
      |> safe_map(&Map.new/1)
    end

    def do_deserialize(list) when is_list(list) do
      list
      |> safe_transform(&do_deserialize/1)
    end

    def do_deserialize(data) do
      {:ok, data}
    end
  end

  def deserialize(data) when is_binary(data) do
    decode(data, &Internal.do_deserialize/1)
  end

  def deserialize(:undefined, data) when is_binary(data) do
    decode(data, &Internal.do_deserialize/1)
  end

  def deserialize(struct, data) when is_binary(data) do
    decode(data, &Brook.Deserializer.Protocol.deserialize(struct, to_atom_keys(&1)))
  end

  defp decode(json, success_callback) do
    case Jason.decode(json) do
      {:ok, decoded_json} when is_map(decoded_json) -> success_callback.(decoded_json)
      {:ok, decoded_json} -> {:ok, decoded_json}
      error_result -> error_result
    end
  end
end
