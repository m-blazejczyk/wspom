defmodule Wspom.ContextFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Wspom.Context` context.
  """

  @doc """
  Generate a entry.
  """
  def entry_fixture(attrs \\ %{}) do
    {:ok, entry} =
      attrs
      |> Enum.into(%{
        day: 42,
        description: "some description",
        fuzzy: 42,
        importance: 42,
        month: 42,
        needs_review: 42,
        tags: "some tags",
        title: "some title",
        weekday: 42,
        year: 42
      })
      |> Wspom.Context.create_entry()

    entry
  end
end
