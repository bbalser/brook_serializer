defprotocol Brook.Serializer do
  @moduledoc """
  The protocol for standard serialization of Elixir structs to
  an in-transit encoding format before sending on the Brook event stream.

  Brook drivers are expected to implement a default serializer for
  converting to the given encoding, leaving the client the option to
  implement a custom serializer for specific struct types.
  """

  @type type :: atom()
  @type reason :: term()
  @fallback_to_any true

  @doc """
  Convert the supplied Elixir term to an encoded term wrapped in an `:ok` tuple.
  """
  @spec serialize(term()) :: {:ok, term()} | {:error, reason()}
  def serialize(data)
end

defimpl Brook.Serializer, for: Any do
  @moduledoc """
  Provide a default implementation for the `Brook.Event.Serializer`
  protocol that will encode the supplied term to json.
  """

  def serialize(data) do
    Jason.encode(data)
  end
end
