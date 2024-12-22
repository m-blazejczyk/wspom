defmodule TagsAndCascadesTest do
  use ExUnit.Case

  alias Wspom.TnC

  test "Testing the tests" do
    assert TnC.tags_from_string("") == {:ok, %{tags: MapSet.new([])}}
  end
end
