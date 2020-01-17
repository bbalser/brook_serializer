defmodule Brook.Serializer.NestedTest do
  use ExUnit.Case

  test "support nested structs" do
    input = %NestedStruct{
      name: %TestStruct{name: "joe", age: 21, location: "NY"},
      map: %{
        "one" => %TestStruct{name: "sally", age: 21, location: "NY"},
        "two" => %TestStruct{name: "sally", age: 37, location: "NY"},
        "three" => %NestedStruct{name: "nick", map: %TestStruct{name: "test"}}
      },
      list: [
        %TestStruct{name: "bob", age: 22, location: "MN"}
      ]
    }

    {:ok, serialized} = Brook.Serializer.serialize(input)
    {:ok, deserialized} = Brook.Deserializer.deserialize(serialized)

    assert deserialized == input
  end
end
