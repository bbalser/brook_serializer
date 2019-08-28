defprotocol Brook.Deserializer do
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

defimpl Brook.Deserializer, for: Any do
  @moduledoc """
  Provide a default implementation for the `Brook.Event.Deserializer`
  protocol that will decode the supplied json to an instance of
  the provided struct.
  """

  def deserialize(:undefined, data) do
    Jason.decode(data)
  end

  def deserialize(%struct_module{}, data) do
    case Jason.decode(data, keys: :atoms) do
      {:ok, decoded_json} -> {:ok, struct(struct_module, decoded_json)}
      error_result -> error_result
    end
  end
end
