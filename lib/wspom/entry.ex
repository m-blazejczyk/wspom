defmodule Wspom.Entry do
  import Ecto.Changeset

  defstruct [:id, :description, :title, :year, :month, :day, :weekday, :date,
    importance: :normal, fuzzy: 0, needs_review: false, tags: MapSet.new()]

  # See https://hexdocs.pm/ecto/Ecto.Schema.html#module-types-and-castin
  @types %{description: :string, title: :string,
    year: :integer, month: :integer, day: :integer, weekday: :integer, date: :date,
    importance: :string, fuzzy: :integer, needs_review: :boolean, tags: :string}

  def changeset(entry, attrs) do
    {entry, @types}
    |> cast(attrs, [:description, :title, :year, :month, :day, :weekday, :date,
      :importance, :fuzzy, :needs_review, :tags])
    |> validate_required([:description, :title, :year, :month, :day])
    |> validate_number(:day, greater_than: 0, less_than: 32)
    |> validate_number(:month, greater_than: 0, less_than: 13)
    |> validate_number(:year, greater_than: 1899, less_than: 2025)
  end

  def to_editable_map(%Wspom.Entry{} = entry) do
    %{id: entry.id, description: entry.description, title: entry.title,
      year: entry.year, month: entry.month, day: entry.day,
      fuzzy: entry.fuzzy, needs_review: entry.needs_review,
      tags: tags_to_string(entry.tags)}
  end

  def tags_to_string(tags) do
    if MapSet.size(tags) > 0 do
      tags
      |> MapSet.to_list()
      |> Enum.sort()
      |> Enum.join(" ")
    else
      ""
    end
  end

  @spec compare_years(%Wspom.Entry{}, %Wspom.Entry{}) :: boolean()
  def compare_years(e1, e2), do: e1.year <= e2.year

  @spec compare_dates(%Wspom.Entry{}, %Wspom.Entry{}) :: boolean()
  def compare_dates(e1, e2) do
    if e1.year != e2.year do
      e1.year <= e2.year
    else
      if e1.month != e2.month do
        e1.month <= e2.month
      else
        e1.day <= e2.day
      end
    end
  end
end
