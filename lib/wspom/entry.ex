defmodule Wspom.Entry do
  defstruct [:id, :description, :title, :year, :month, :day, :weekday, :date,
    importance: :normal, fuzzy: 0, needs_review: false, tags: MapSet.new()]

  def tags_to_string(tags) do
    if MapSet.size(tags) > 0 do
      tags
      |> MapSet.to_list()
      |> Enum.sort()
      |> Enum.join(", ")
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
