defprotocol Brook.Serializer.Protocol do
  @moduledoc """
  The protocol for standard serialization of Elixir structs to
  an in-transit encoding format before sending on the Brook event stream.

  Brook drivers are expected to implement a default serializer for
  converting to the given encoding, leaving the client the option to
  implement a custom serializer for specific struct types.
  """

  @fallback_to_any true

  @doc """
  Convert the supplied Elixir term to an encoded term wrapped in an `:ok` tuple.
  """
  @spec serialize(term()) :: {:ok, term()} | {:error, term()}
  def serialize(data)
end

defimpl Brook.Serializer.Protocol, for: Any do
  @moduledoc """
  Provide a default implementation for the `Brook.Event.Serializer`
  protocol that will encode the supplied term to json.
  """
  require Logger

  @struct_key "__brook_struct__"
  @custom_transforms %{
    DateTime => &DateTime.to_iso8601/1,
    NaiveDateTime => &NaiveDateTime.to_iso8601/1
  }

  @custom_structs Map.keys(@custom_transforms)

  def serialize(data) do
    do_serialize(data)
    |> Jason.encode()
  end

  defp do_serialize(%struct{} = data) when struct in @custom_structs do
    %{
      @struct_key => struct,
      "value" => Map.get(@custom_transforms, struct).(data)
    }
  end

  defp do_serialize(%struct{} = data) do
    data
    |> Map.from_struct()
    |> Map.put(@struct_key, struct)
  end

  defp do_serialize(%{} = data) do
    data
    |> Enum.map(fn {key, value} -> {key, do_serialize(value)} end)
    |> Map.new()
  end

  defp do_serialize(data) do
    data
  end
end

defmodule Brook.Serializer do
  @spec serialize(term()) :: {:ok, term()} | {:error, term()}
  def serialize(data) do
    Brook.Serializer.Protocol.serialize(data)
  end
end
