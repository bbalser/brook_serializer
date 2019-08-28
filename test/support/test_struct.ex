defmodule TestStruct do
  @derive Jason.Encoder
  defstruct [:name, :age, :location]
end
