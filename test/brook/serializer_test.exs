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

    test "encodes a struct add tracks struct in struct key" do
      input = %TestStruct{name: "john", age: 21, location: "Nashville"}

      expected =
        input
        |> Map.from_struct()
        |> to_string_keys()
        |> Map.put("__brook_struct__", to_string(TestStruct))

      {:ok, result} = Brook.Serializer.serialize(input)

      assert expected == Jason.decode!(result)
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

  defp to_string_keys(map) do
    map
    |> Enum.map(fn {key, value} -> {to_string(key), value} end)
    |> Map.new()
  end
end
