defmodule TestStruct do
  @derive Jason.Encoder
  defstruct [:name, :age, :location]
end

defmodule TestStructWithNew do
  @derive Jason.Encoder

  defstruct [:name, :age, :location]

  def new(args) when is_list(args) do
    new(Map.new(args))
  end

  def new(%{} = args) do
    map = Map.update(args, :name, "", fn name -> String.upcase(name) end)
    struct(__MODULE__, map)
  end
end
