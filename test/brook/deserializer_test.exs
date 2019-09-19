defmodule Brook.DeserializerTest do
  use ExUnit.Case

  describe "deserialize/1" do
    test "decodes map back into map" do
      input = %{
        "foo" => "bar"
      }

      {:ok, input_as_json} = Brook.Serializer.serialize(input)
      assert {:ok, input} == Brook.Deserializer.deserialize(input_as_json)
    end

    test "decodes strings back into strings" do
      input = "foobar"

      {:ok, input_as_string} = Brook.Serializer.serialize(input)
      assert {:ok, input} == Brook.Deserializer.deserialize(input_as_string)
    end

    test "returns error tuple when unable to deserialize json" do
      input = "{\"one\": 1)"

      {:error, reason} = Jason.decode(input)

      assert {:error, reason} == Brook.Deserializer.deserialize(input)
    end

    test "decodes input into a struct" do
      input = %TestStruct{
        name: "Matt",
        age: 23,
        location: "Phoenix AZ"
      }

      {:ok, input_as_json} = Brook.Serializer.serialize(input)
      assert {:ok, input} == Brook.Deserializer.deserialize(input_as_json)
    end
  end

  describe "deserialize/2" do
    test "decodes input into map" do
      input = %{
        "foo" => "bar"
      }

      {:ok, input_as_json} = Brook.Serializer.serialize(input)
      assert {:ok, input} == Brook.Deserializer.deserialize(:undefined, input_as_json)
    end

    test "returns error tuple when unable to deserialize json" do
      input = "{\"one\": 1)"

      {:error, reason} = Jason.decode(input)

      assert {:error, reason} == Brook.Deserializer.deserialize(:undefined, input)
    end

    test "decodes input into a struct" do
      input = %TestStruct{
        name: "Matt",
        age: 23,
        location: "Phoenix AZ"
      }

      input_as_json = Jason.encode!(input)
      assert {:ok, input} == Brook.Deserializer.deserialize(%TestStruct{}, input_as_json)
    end

    test "returns error tuple when unable to deserialize struct" do
      input = "{\"one\": 1)"

      {:error, reason} = Jason.decode(input)
      assert {:error, reason} == Brook.Deserializer.deserialize(%TestStruct{}, input)
    end
  end
end