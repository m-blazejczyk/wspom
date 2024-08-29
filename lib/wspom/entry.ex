defmodule Wspom.Entry do
  defstruct [:id, :description, :title, :year, :month, :day, :weekday,
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

  def compare(e1, e2) when e1.year > e2.year, do: :gt
  def compare(e1, e2) when e1.year < e2.year, do: :lt
  def compare(e1, e2) when e1.year == e2.year, do: :eq
end
