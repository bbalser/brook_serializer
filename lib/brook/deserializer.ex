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
  @struct_key "__brook_struct__"

  def deserialize(data) when is_binary(data) do
    decode(data, &do_deserialize/1)
  end

  def deserialize(:undefined, data) when is_binary(data) do
    decode(data, &do_deserialize/1)
  end

  def deserialize(struct, data) when is_binary(data) do
    decode(data, &Brook.Deserializer.Protocol.deserialize(struct, to_atom_keys(&1)))
  end

  defp do_deserialize(%{@struct_key => struct} = data) do
    struct_module = struct |> String.to_atom()
    Code.ensure_loaded(struct_module)

    case function_exported?(struct_module, :__struct__, 0) do
      true ->
        prepared_data =
          data
          |> Map.delete(@struct_key)
          |> to_atom_keys()

        struct_module
        |> struct()
        |> Brook.Deserializer.Protocol.deserialize(prepared_data)

      false ->
        {:error, :invalid_struct}
    end
  end

  defp do_deserialize(%{} = data) do
    case safe_map(data, &do_deserialize/1) do
      {:ok, new_data} -> {:ok, Map.new(new_data)}
      error_result -> error_result
    end
  end

  defp do_deserialize(data) do
    {:ok, data}
  end

  defp safe_map(%{} = enum, function) when is_function(function, 1) do
    Enum.reduce_while(enum, {:ok, []}, fn {key, value}, {:ok, acc} ->
      case function.(value) do
        {:ok, new_value} -> {:cont, {:ok, [{key, new_value} | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
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
