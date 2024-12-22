defmodule TagsAndCascadesTest do
  use ExUnit.Case

  alias Wspom.TnC

  test "Tags from string" do
    assert TnC.tags_from_string("") == {:ok, %{tags: MapSet.new([])}}
    assert TnC.tags_from_string("t1 t4") == {:ok, %{tags: MapSet.new(["t1", "t4"])}}
    assert TnC.tags_from_string("t1 c") == {:ok, %{tags: MapSet.new(["t1", "t2", "c"])}}
    assert TnC.tags_from_string("c") == {:ok, %{tags: MapSet.new(["t1", "t2", "c"])}}
    assert TnC.tags_from_string("t4 c") == {:ok, %{tags: MapSet.new(["t1", "t2", "c", "t4"])}}
  end
end
