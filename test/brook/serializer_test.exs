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

    test "encodes a struct and tracks struct in struct key" do
      input = %TestStruct{name: "john", age: 21, location: "Nashville"}

      expected =
        input
        |> Map.from_struct()
        |> to_string_keys()
        |> Map.put("__brook_struct__", to_string(TestStruct))

      {:ok, result} = Brook.Serializer.serialize(input)

      assert expected == Jason.decode!(result)
    end

    test "encodes/decodes nested structs" do
      input = %{
        "one" => %TestStruct{name: "john", age: 21, location: "Columbus"},
        "two" => %TestStruct{name: "tom", age: 72, location: "Detroit"}
      }

      {:ok, serialized} = Brook.Serializer.serialize(input)
      {:ok, deserialized} = Brook.Deserializer.deserialize(serialized)

      assert input == deserialized
    end

    test "encodes regular lists" do
      input = [:foo, "bar", :baz, "qux", [:bleep, "bloop"]]

      {:ok, serialized} = Brook.Serializer.serialize(input)

      assert serialized == ~s|["foo","bar","baz","qux",["bleep","bloop"]]|
    end

    test "encodes keyword lists wrapped in a map" do
      input = [foo: "bar", baz: "qux"]

      {:ok, serialized} = Brook.Serializer.serialize(input)

      assert serialized == ~s|{"keyword":true,"list":[["foo","bar"],["baz","qux"]]}|
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

  test "serializes property with and field is named :error" do
    {:ok, json} = Brook.Serializer.serialize(%{error: "Balser", dataset: "BAsler"})

    assert {:ok, %{"error" => "Balser", "dataset" => "BAsler"}} ==
             Brook.Deserializer.deserialize(json)
  end

  defp to_string_keys(map) do
    map
    |> Enum.map(fn {key, value} -> {to_string(key), value} end)
    |> Map.new()
  end
end
