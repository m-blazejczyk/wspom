defmodule Wspom.Entries.Stats do
  use Timex

  @empty_year_threshold 20

  def get_stats(entries) do
    entries_count = length(entries)
    days_count = entries
    |> Enum.map(& &1.date)
    |> Enum.uniq()
    |> length()
    all_years = entries
    |> Enum.frequencies_by(& &1.date.year)  # returns a map %{year => count}
    |> Enum.sort_by(fn {year, _count} -> year end)  # returns a list of tuples [{year, count}]
    years_count = all_years
    |> Enum.filter(fn {_year, count} -> count > @empty_year_threshold end) # returns a list of tuples [{year, count}]
    |> length()
    years_list = all_years
    |> Enum.reduce([], &years_disp_reducer/2)
    |> Enum.reverse()
    # Stats based on the first pages of "Miazga", single-spaced,
    # font size 12 Liberation Serif:
    # - 28 pages is 100K characters
    # - 1 page is 3,600 characters
    # - 500 words per page
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

    now = Utils.date_now()

    %{
      now: "#{Timex.month_shortname(now.month)} #{now.day}",
      entries: entries_count,
      days: days_count,
      years: years_count,
      years_list: years_list,
      pages: "#{ :io_lib.format("~.1f", [pages_count / 3600]) }",
      tagged: "#{ tagged_count } (#{ :io_lib.format("~.1f", [tagged_count / entries_count * 100]) }%)",
      important: important_count,
      very_important: very_important_count,
      needs_review: needs_review_count
    }
  end

  # All the code in years_disp_reducer() assumes that years are sorted
  # in ascending order; that at the beginning there are some empty "years";
  # and then afterwards, years can be intersperced by "gaps" of empty years.

  # First year ever - just return the count of entries
  defp years_disp_reducer({_year, count}, []) do
    [{nil, count}]
  end
  # Remaining "empty" years pre-1992
  defp years_disp_reducer({_year, count}, [{nil, acc}])
  when count < @empty_year_threshold do
    [{nil, acc + count}]
  end
  # First non-"empty" year
  defp years_disp_reducer({year, count}, [{nil, acc}])
  when count >= @empty_year_threshold do
    [{year, count}, {"…‒#{year - 1}", acc}]
  end
  # Non-"empty" years, continue the gap
  defp years_disp_reducer({_year, count}, [{{gap, nil}, last_count} | remaining])
  when count < @empty_year_threshold do
    [{{gap, nil}, last_count + count}] ++ remaining
  end
  # Non-"empty" years, close the gap
  defp years_disp_reducer({year, count}, [{{gap, nil}, last_count} | remaining])
  when count >= @empty_year_threshold do
    [{year, count}, {"#{gap}‒#{year - 1}", last_count}] ++ remaining
  end
  # Non-"empty" years, open a gap: change the shape of the first item
  defp years_disp_reducer({_year, count}, [{last_year, last_count} | remaining])
  when count < @empty_year_threshold do
    [{{last_year + 1, nil}, count}, {last_year, last_count}] ++ remaining
  end
  # Non-"empty" years, continue full years
  defp years_disp_reducer({year, count}, items)
  when count >= @empty_year_threshold  do
    [{year, count}] ++ items
  end
end
