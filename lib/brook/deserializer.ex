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
    {:ok, struct(struct_module, data)}
  end
end

defmodule Brook.Deserializer do

  @struct_key "__brook_struct__"

  def deserialize(data) when is_binary(data) do
    decode(data, &deserialize/1)
  end

  def deserialize(%{@struct_key => struct} = data) do
    struct_module = struct |> String.to_atom()
    Code.ensure_loaded(struct_module)

    case function_exported?(struct_module, :__struct__, 0) do
      true ->
        struct_module
        |> struct()
        |> deserialize(Map.delete(data, @struct_key))
      false ->
        {:error, :invalid_struct}
    end
  end

  def deserialize(data) do
    {:ok, data}
  end

  def deserialize(struct, data) when is_binary(data) do
    decode(data, &deserialize(struct, &1))
  end

  def deserialize(:undefined, data) do
    {:ok, data}
  end

  def deserialize(struct, data) do
    Brook.Deserializer.Protocol.deserialize(struct, to_atom_keys(data))
  end

  defp to_atom_keys(map) do
    map
    |> Enum.map(fn {key, value} -> {String.to_atom(key), value} end)
    |> Map.new()
  end

  defp decode(json, success_callback) do
    case Jason.decode(json) do
      {:ok, decoded_json} when is_map(decoded_json) -> success_callback.(decoded_json)
      {:ok, decoded_json} -> {:ok, decoded_json}
      error_result -> error_result
    end
  end
end
