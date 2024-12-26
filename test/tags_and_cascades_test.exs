defmodule TagsAndCascadesTest do
  use ExUnit.Case

  alias Wspom.TnC

  test "Tags from string" do
    {:ok, %{tags_applied: tags_applied}} = TnC.tags_from_string("")
    assert tags_applied == MapSet.new([])

    {:ok, %{tags_applied: tags_applied}} = TnC.tags_from_string("t1 t4")
    assert tags_applied == MapSet.new(["t1", "t4"])

    {:ok, %{tags_applied: tags_applied}} = TnC.tags_from_string("t1 c")
    assert tags_applied == MapSet.new(["t1", "t2", "c"])

    {:ok, %{tags_applied: tags_applied}} = TnC.tags_from_string("c")
    assert tags_applied == MapSet.new(["t1", "t2", "c"])

    {:ok, %{tags_applied: tags_applied}} = TnC.tags_from_string("t4 c")
    assert tags_applied == MapSet.new(["t1", "t2", "c", "t4"])
  end

  test "Cascade definitions" do
    # Basic
    {:ok, %{tags_applied: tags_applied, cascade_defs: cascade_defs}} = TnC.tags_from_string("e f g>h>i")
    assert tags_applied == MapSet.new(["e", "f", "g", "h", "i"])
    assert cascade_defs == %{"i" => MapSet.new(["g", "h", "i"])}

    # Repeated tags
    {:ok, %{tags_applied: tags_applied, cascade_defs: cascade_defs}} = TnC.tags_from_string("e f g>f>i")
    assert tags_applied == MapSet.new(["e", "f", "g", "i"])
    assert cascade_defs == %{"i" => MapSet.new(["g", "f", "i"])}

    # Two definitions
    {:ok, %{tags_applied: tags_applied, cascade_defs: cascade_defs}} = TnC.tags_from_string("f g>h>i g>k>l")
    assert tags_applied == MapSet.new(["f", "g", "h", "i", "k", "l"])
    assert cascade_defs == %{"i" => MapSet.new(["g", "h", "i"]), "l" => MapSet.new(["g", "k", "l"])}

    # Two definitions with the same names
    {:ok, %{tags_applied: tags_applied, cascade_defs: cascade_defs}} = TnC.tags_from_string("g>h>i k>l>i")
    assert tags_applied == MapSet.new(["g", "h", "i", "k", "l"])
    assert cascade_defs == %{"i" => MapSet.new(["k", "l", "i"])}

    # Full monty
    {:ok, %{tags_applied: tags_applied, cascade_defs: cascade_defs}} = TnC.tags_from_string("e f g>h>i c")
    assert tags_applied == MapSet.new(["e", "f", "g", "h", "i", "t1", "t2", "c"])
    assert cascade_defs == %{"i" => MapSet.new(["g", "h", "i"])}
  end

  defp is_error({:error, _}), do: true
  defp is_error({:ok, _}), do: false

  test "Invalid cascade definitions" do
    assert is_error(TnC.tags_from_string("e f g>h>c"))
  end

  test "Known and unknown tags" do
    {:ok, %{known_tags: known_tags, unknown_tags: unknown_tags}} = TnC.tags_from_string("t4 t5 c")
    assert known_tags == MapSet.new(["t1", "t2", "c"])
    assert unknown_tags == MapSet.new(["t4", "t5"])
  end

  test "Summaries" do
    {:ok, %{summary: summary}} = TnC.tags_from_string("c t4 g>h>i g>k>l")
    assert is_binary(summary)
    IO.puts(summary)
  end
end
