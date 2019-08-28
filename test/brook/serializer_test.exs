defmodule Brook.SerializerTest do
  use ExUnit.Case

  describe "serialize/1" do
    test "encodes input as json" do
      input = %{
        "one" => 1,
        "two" => 2
      }

      expected = Jason.encode!(input)

      assert {:ok, expected} == Brook.Serializer.serialize(input)
    end

    test "returns error tuple when unable to parse input" do
      input = %{
        "one" => {1, 2},
        "two" => 2
      }

      {:error, reason} = Jason.encode(input)

      assert {:error, reason} == Brook.Serializer.serialize(input)
    end
  end
end
