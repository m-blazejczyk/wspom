defmodule TagsAndCascadesTest do
  use ExUnit.Case

  alias Wspom.Entries.TnC
  alias Wspom.Entry

  ###################################################################
  #
  # BEFORE RUNNING THESE TESTS, open application.ex and change
  # is_production to false!
  #
  ###################################################################

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
    assert summary <> "\n" == """
    Applied 9 tags.
    Known tags: c, t1, t2
    New tags: g, h, i, k, l, t4
    New cascades: i, l
    """
  end

  defp test_entries() do
    [
      %Entry{tags: MapSet.new(["a", "b"])},
      %Entry{tags: MapSet.new(["b", "c"])},
      %Entry{tags: MapSet.new(["d", "e"])},
      %Entry{tags: MapSet.new(["b", "e", "f"])},
      %Entry{tags: MapSet.new(["b"])},
      %Entry{tags: MapSet.new([])},
    ]
  end

  test "Counting tags" do
    entries = test_entries()

    assert entries |> TnC.count_entries_tagged_with("b") == 4
    assert entries |> TnC.count_entries_tagged_with("e") == 2
    assert entries |> TnC.count_entries_tagged_with("g") == 0
  end

  test "Deleting tags" do
    entries_0 = test_entries()
    state_0 = {
      %{entries: entries_0},
      %{tags: MapSet.new(["a", "b", "c", "d", "e", "f"]),
        cascades: Map.new([{"c", MapSet.new(["c", "b"])}, {"b", MapSet.new(["a", "b", "g"])}])}
    }

    state_1 = state_0 |> TnC.delete_tag("b")
    {%{entries: entries_1}, %{tags: tags_1, cascades: cascades_1}} = state_1

    # Check the entries
    assert not (entries_1 |> Enum.at(0) |> Map.get(:tags) |> MapSet.member?("b"))
    assert not (entries_1 |> Enum.at(3) |> Map.get(:tags) |> MapSet.member?("b"))
    assert entries_1 |> Enum.at(0) |> Map.get(:tags) |> MapSet.size() == 1
    assert entries_1 |> Enum.at(3) |> Map.get(:tags) |> MapSet.size() == 2
    assert entries_1 |> TnC.count_entries_tagged_with("b") == 0

    # Check the tags
    assert tags_1 |> MapSet.size() == 5
    assert not (tags_1 |> MapSet.member?("b"))

    # Check the cascades
    assert cascades_1 |> map_size() == 1
    assert cascades_1 |> Map.get("c") |> MapSet.size() == 1
  end
end
