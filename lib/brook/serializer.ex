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
  @spec serialize(term()) :: {:ok, term()} | {:error, term()}
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
    |> ok()
  end

  def serialize(data) do
    ok(data)
  end

  defp ok(value), do: {:ok, value}
end

defimpl Brook.Serializer.Protocol, for: Map do
  def serialize(data) do
    case safe_map(data, &Brook.Serializer.Protocol.serialize/1) do
      {:ok, list} -> {:ok, Map.new(list)}
      error_result -> error_result
    end
  end

  defp safe_map(enum, function) when is_function(function, 1) do
    Enum.reduce_while(enum, {:ok, []}, fn {key, value}, {:ok, acc} ->
      case function.(value) do
        {:ok, new_value} -> {:cont, {:ok, [{key, new_value} | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end
end

defimpl Brook.Serializer.Protocol, for: DateTime do
  def serialize(date_time) do
    {:ok,
     %{
       Brook.Serializer.struct_key() => DateTime,
       "value" => DateTime.to_iso8601(date_time)
     }}
  end
end

defimpl Brook.Serializer.Protocol, for: NaiveDateTime do
  def serialize(naive_date_time) do
    {:ok, %{
      Brook.Serializer.struct_key() => NaiveDateTime,
      "value" => NaiveDateTime.to_iso8601(naive_date_time)
    }}
  end
end

defimpl Brook.Serializer.Protocol, for: Date do
  def serialize(date) do
    {:ok, %{
      Brook.Serializer.struct_key() => Date,
      "value" => Date.to_iso8601(date)
    }}
  end
end

defimpl Brook.Serializer.Protocol, for: Time do
  def serialize(time) do
    {:ok, %{
      Brook.Serializer.struct_key() => Time,
      "value" => Time.to_iso8601(time)
    }}
  end
end

defmodule Brook.Serializer do
  def struct_key(), do: "__brook_struct__"

  @spec serialize(term()) :: {:ok, term()} | {:error, term()}
  def serialize(data) do
    case Brook.Serializer.Protocol.serialize(data) do
      {:ok, serialized_data} -> Jason.encode(serialized_data)
      error_result -> error_result
    end
  end
end
