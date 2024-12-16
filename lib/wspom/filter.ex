defmodule Wspom.Filter do
  # VERY IMPORTANT:
  # Entries MUST be sorted by date.
  # This means that when entries are added, they must be added
  # in the right location in the list.
  # Otherwise, some functions in the Filter module won't work well.

alias Timex.DateTime
  use Timex

  alias Wspom.Entry

  # In addition to the "current" state of the filter, we also have to
  # store the "Next" and "Previous" so that it can be used in navigation.
  defstruct [:which, :day, :month, :year, :tag,
    :next_day, :next_month, :prev_day, :prev_month]

  @spec init_day_from_date(DateTime.t()) :: %Wspom.Filter{}
  defp init_day_from_date(dt) do
    next_date = dt |> Timex.shift(days: 1)
    prev_date = dt |> Timex.shift(days: -1)

    %Wspom.Filter{
      which: :day,
      day: dt.day, month: dt.month,
      next_day: next_date.day, next_month: next_date.month,
      prev_day: prev_date.day, prev_month: prev_date.month}
  end

  # This function is only called on the initial page load.
  @spec default() :: %Wspom.Filter{}
  def default() do
    init_day_from_date(Timex.now("America/Montreal"))
  end

  @spec from_params(%{}) :: %Wspom.Filter{}
  def from_params(%{"filter" => "day", "day" => day, "month" => month}) do
    # The year can be anything in this case but let's pick a leap year
    init_day_from_date(Timex.to_date({2024, String.to_integer(month), String.to_integer(day)}))
  end
  def from_params(%{"filter" => "year", "day" => _day, "month" => _month, "year" => _year}) do
    nil
  end

  @spec toString(%Wspom.Filter{}) :: String.t()
  def toString(%Wspom.Filter{which: :day, day: day, month: month}) do
    Timex.month_shortname(month) <> " " <> Integer.to_string(day)
  end
  def toString(%Wspom.Filter{which: :year, year: year}) do
    Integer.to_string(year)
  end
  def toString(_) do
    "Unknown filter"
  end

  @spec toTitle(%Wspom.Filter{}) :: String.t()
  def toTitle(%Wspom.Filter{day: day, month: month}) do
    Timex.month_shortname(month) <> " " <> Integer.to_string(day)
  end

  def prev_link(%Wspom.Filter{which: :day, prev_day: day, prev_month: month}) do
    "/entries?filter=day&day=#{day}&month=#{month}"
  end
  def prev_link(%Wspom.Filter{which: :year, prev_day: day, prev_month: month, year: year}) do
    "/entries?filter=year&day=#{day}&month=#{month}&year=#{year}"
  end

  def next_link(%Wspom.Filter{which: :day, next_day: day, next_month: month}) do
    "/entries?filter=day&day=#{day}&month=#{month}"
  end
  def next_link(%Wspom.Filter{which: :year, next_day: day, next_month: month, year: year}) do
    "/entries?filter=year&day=#{day}&month=#{month}&year=#{year}"
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
