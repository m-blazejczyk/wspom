defmodule Wspom.Filter do
  # VERY IMPORTANT:
  # Entries MUST be sorted by date.
  # This means that when entries are added, they must be added
  # in the right location in the list.
  # Otherwise, some functions in the Filter module won't work well.

  use Timex

  alias Wspom.Entry

  defstruct [:which, :day, :month, :year, :tag]

  @spec default() :: %Wspom.Filter{}
  def default() do
    now = Timex.now("America/Montreal")
    %Wspom.Filter{which: :day, day: now.day, month: now.month}
  end

  @spec toString(%Wspom.Filter{}) :: String.t()
  def toString(%Wspom.Filter{which: :day, day: day, month: month}) do
    Timex.month_shortname(month) <> " " <> Integer.to_string(day)
  end
  def toString(%Wspom.Filter{which: :year, year: year}) do
    Integer.to_string(year)
  end
  def toString(_) do
    "Another filter"
  end

  @spec filter(%Wspom.Filter{}, list(%Wspom.Entry{})) :: list(%Wspom.Entry{})
  def filter(%Wspom.Filter{which: :day, day: day, month: month}, entries) do
    # Return entries for the given day across all years
    entries
    |> Enum.filter(fn entry -> month == entry.month and day == entry.day end)
    |> Enum.sort(&Entry.compare_years/2)  # Sort by year
  end
  def filter(%Wspom.Filter{which: :year, day: day, month: month, year: year}, entries) do
    # Return entries for the given day on one specific year
    entries
    |> Enum.filter(fn entry -> year == entry.year and month == entry.month and day == entry.day end)
  end

  defp find_next(entry, {curr_date, next_date, found_entries} = acc) do
    if Date.compare(entry.date, curr_date) != :gt do  # entry.date <= curr_date
      # We are before the current date - continue
      {:cont, acc}
    else
      if Date.compare(entry.date, curr_date) == :gt and next_date == nil do
        # We found the first entry AFTER the current date;
        # initialize the next_date field and add 'entry' to found entries
        IO.puts("Next: found the next date #{entry.date} > current #{curr_date}")
        {:cont, {curr_date, entry.date, [entry]}}
      else
        if Date.compare(entry.date, next_date) == :eq do
          # We found another entry with the same date as next_date
          IO.puts("Next: found another entry with the same date")
          {:cont, {curr_date, next_date, [entry | found_entries]}}
        else
          # We are past next_date - we're done!
          {:halt, acc}
        end
      end
    end
  end

  def next(%Wspom.Filter{which: :day, day: day, month: month}, entries) do
    # The year does not matter but let's pick a leap year
    new_date = Date.new!(2024, month, day) |> Timex.shift(days: 1)
    new_filter = %Wspom.Filter{which: :day, day: new_date.day, month: new_date.month}
    {new_filter, new_filter |> Wspom.Filter.filter(entries) }
  end
  def next(%Wspom.Filter{which: :year, day: day, month: month, year: year}, entries) do
    # We need to find entries that FOLLOW the current date.
    # Imortant: we can assume that entries are SORTED.
    # Complications:
    # - There may be a gap (a missing date) so we cannot just do "date + 1".
    # - There may be more than one entry with the given date.
    # - This code won't work at the very end of the year.
    acc = {Date.new!(year, month, day), nil, []}
    {_, new_date, filtered_entries} = entries
    |> Enum.reduce_while(acc, &find_next/2)
    {%Wspom.Filter{which: :year, day: new_date.day, month: new_date.month, year: new_date.year},
      filtered_entries}
  end

  defp find_prev(entry, {curr_date, prev_date, found_entries} = acc) do
    if Date.compare(entry.date, curr_date) != :lt do  # entry.date >= curr_date
      # We are after the current date - continue
      {:cont, acc}
    else
      if Date.compare(entry.date, curr_date) == :lt and prev_date == nil do
        # We found the first entry BEFORE the current date;
        # initialize the prev_date field and add 'entry' to found_entries
        {:cont, {curr_date, entry.date, [entry]}}
      else
        if Date.compare(entry.date, prev_date) == :eq do
          # We found another entry with the same date as prev_date
          {:cont, {curr_date, prev_date, [entry | found_entries]}}
        else
          # We are before prev_date - we're done!
          {:halt, acc}
        end
      end
    end
  end

  def prev(%Wspom.Filter{which: :day, day: day, month: month}, entries) do
    # The year does not matter but let's pick a leap year
    new_date = Date.new!(2024, month, day) |> Timex.shift(days: -1)
    new_filter = %Wspom.Filter{which: :day, day: new_date.day, month: new_date.month}
    {new_filter, new_filter |> Wspom.Filter.filter(entries) }
  end
  def prev(%Wspom.Filter{which: :year, day: day, month: month, year: year}, entries) do
    # We need to find entries that PRECEED the current date.
    # Imortant: we can assume that entries are SORTED.
    # Complications:
    # - There may be a gap (a missing date) so we cannot just do "date - 1".
    # - There may be more than one entry with the given date.
    # - This code won't work at the very beginning of the year.
    # - It will be easier to revert the list of entries first.
    acc = {Date.new!(year, month, day), nil, []}
    {_, new_date, filtered_entries} = entries
    |> Enum.reverse()
    |> Enum.reduce_while(acc, &find_prev/2)
    {%Wspom.Filter{which: :year, day: new_date.day, month: new_date.month, year: new_date.year},
      filtered_entries}
  end

  def to_year(%Wspom.Filter{which: :day, day: day, month: month}, year, entries) do
    new_filter = %Wspom.Filter{which: :year, day: day, month: month, year: year}
    {new_filter, new_filter |> Wspom.Filter.filter(entries) }
  end

  def to_day(%Wspom.Filter{day: day, month: month}, entries) do
    new_filter = %Wspom.Filter{which: :day, day: day, month: month}
    {new_filter, new_filter |> Wspom.Filter.filter(entries) }
  end
end
