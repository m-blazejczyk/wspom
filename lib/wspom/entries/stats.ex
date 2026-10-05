defmodule Wspom.Entries.Stats do
  use Timex

  def get_stats(entries) do
    entries_count = length(entries)
    days_count = entries
    |> Enum.map(& &1.date)
    |> Enum.uniq()
    |> length()
    years_count = entries
    |> Enum.frequencies_by(& &1.date.year)              # returns a map %{year => count}
    |> Enum.filter(fn {_year, count} -> count > 20 end) # returns a list of tuples [{year, count}]
    |> length()
    pages_count = entries
    |> Enum.map(& &1.description |> String.length())
    |> Enum.sum()
    tagged_count = entries
    |> Enum.count(& MapSet.size(&1.tags) > 0)
    important_count = entries
    |> Enum.count(& &1.importance == :important)
    very_important_count = entries
    |> Enum.count(& &1.importance == :very_important)
    needs_review_count = entries
    |> Enum.count(& &1.needs_review)

    %{
      entries: entries_count,
      days: days_count,
      years: years_count,
      pages: pages_count,
      tagged: tagged_count,
      important: important_count,
      very_important: very_important_count,
      needs_review: needs_review_count
    }
  end
end
