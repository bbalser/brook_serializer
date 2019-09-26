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
  Convert the supplied Elixir term to an encoded term.
  """
  @spec serialize(term()) :: term()
  def serialize(data)
end

defimpl Brook.Serializer.Protocol, for: Any do
  @moduledoc """
  Provide a default implementation for the `Brook.Event.Serializer`
  protocol that will encode the supplied term to json.
  """
  require Logger

  def serialize(%struct{} = data) do
    data
    |> Map.from_struct()
    |> Map.put(Brook.Serializer.struct_key(), struct)
  end

  def serialize(data) do
    data
  end
end

defimpl Brook.Serializer.Protocol, for: Map do
  def serialize(data) do
    data
    |> Enum.map(fn {key, value} ->
      {key, Brook.Serializer.Protocol.serialize(value)}
    end)
    |> Map.new()
  end
end

defimpl Brook.Serializer.Protocol, for: DateTime do
  def serialize(date_time) do
    %{
      Brook.Serializer.struct_key() => DateTime,
      "value" => DateTime.to_iso8601(date_time)
    }
  end
end

defimpl Brook.Serializer.Protocol, for: NaiveDateTime do
  def serialize(naive_date_time) do
    %{
      Brook.Serializer.struct_key() => NaiveDateTime,
      "value" => NaiveDateTime.to_iso8601(naive_date_time)
    }
  end
end

defimpl Brook.Serializer.Protocol, for: Date do
  def serialize(date) do
    %{
      Brook.Serializer.struct_key() => Date,
      "value" => Date.to_iso8601(date)
    }
  end
end

defimpl Brook.Serializer.Protocol, for: Time do
  def serialize(time) do
    %{
      Brook.Serializer.struct_key() => Time,
      "value" => Time.to_iso8601(time)
    }
  end
end

defmodule Brook.Serializer do
  @spec serialize(term()) :: {:ok, term()} | {:error, term()}

  def struct_key(), do: "__brook_struct__"

  def serialize(data) do
    Brook.Serializer.Protocol.serialize(data)
    |> Jason.encode()
  end

end
