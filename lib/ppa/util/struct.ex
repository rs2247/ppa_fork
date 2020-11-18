defmodule Util.Struct do
  @moduledoc false

  def get_in(struct=%{}, [key]) do
    Map.get(struct, key)
  end

  def get_in(struct=%{}, [key|tail]) do
    Util.Struct.get_in(Map.get(struct, key), tail)
  end

  def get_in(struct=%{}, key) do
    Map.get(struct, key)
  end

  def get_in(val, _) do val end
end
