defmodule Wspom.ContextTest do
  use Wspom.DataCase

  alias Wspom.Context

  describe "entries" do
    alias Wspom.Context.Entry

    import Wspom.ContextFixtures

    @invalid_attrs %{description: nil, title: nil, month: nil, day: nil, year: nil, weekday: nil, importance: nil, fuzzy: nil, needs_review: nil, tags: nil}

    test "list_entries/0 returns all entries" do
      entry = entry_fixture()
      assert Context.list_entries() == [entry]
    end

    test "get_entry!/1 returns the entry with given id" do
      entry = entry_fixture()
      assert Context.get_entry!(entry.id) == entry
    end

    test "create_entry/1 with valid data creates a entry" do
      valid_attrs = %{description: "some description", title: "some title", month: 42, day: 42, year: 42, weekday: 42, importance: 42, fuzzy: 42, needs_review: 42, tags: "some tags"}

      assert {:ok, %Entry{} = entry} = Context.create_entry(valid_attrs)
      assert entry.description == "some description"
      assert entry.title == "some title"
      assert entry.month == 42
      assert entry.day == 42
      assert entry.year == 42
      assert entry.weekday == 42
      assert entry.importance == 42
      assert entry.fuzzy == 42
      assert entry.needs_review == 42
      assert entry.tags == "some tags"
    end

    test "create_entry/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Context.create_entry(@invalid_attrs)
    end

    test "update_entry/2 with valid data updates the entry" do
      entry = entry_fixture()
      update_attrs = %{description: "some updated description", title: "some updated title", month: 43, day: 43, year: 43, weekday: 43, importance: 43, fuzzy: 43, needs_review: 43, tags: "some updated tags"}

      assert {:ok, %Entry{} = entry} = Context.update_entry(entry, update_attrs)
      assert entry.description == "some updated description"
      assert entry.title == "some updated title"
      assert entry.month == 43
      assert entry.day == 43
      assert entry.year == 43
      assert entry.weekday == 43
      assert entry.importance == 43
      assert entry.fuzzy == 43
      assert entry.needs_review == 43
      assert entry.tags == "some updated tags"
    end

    test "update_entry/2 with invalid data returns error changeset" do
      entry = entry_fixture()
      assert {:error, %Ecto.Changeset{}} = Context.update_entry(entry, @invalid_attrs)
      assert entry == Context.get_entry!(entry.id)
    end

    test "delete_entry/1 deletes the entry" do
      entry = entry_fixture()
      assert {:ok, %Entry{}} = Context.delete_entry(entry)
      assert_raise Ecto.NoResultsError, fn -> Context.get_entry!(entry.id) end
    end

    test "change_entry/1 returns a entry changeset" do
      entry = entry_fixture()
      assert %Ecto.Changeset{} = Context.change_entry(entry)
    end
  end
end
