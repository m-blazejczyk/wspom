defmodule Wspom.Filter do
  alias Timex.DateTime
  use Timex

  alias Wspom.Entry

  # In addition to the "current" state of the filter, we also have to
  # store the "Next" and "Previous" so that it can be used to generate links.
  #Allowed values of 'which': :day, :year and :tag.
  defstruct [:which, :day, :month, :year, :tag, :prev_date, :next_date]

  @spec init_day_from_date(DateTime.t()) :: %Wspom.Filter{}
  defp init_day_from_date(dt) do
    next_date = dt |> Timex.shift(days: 1)
    prev_date = dt |> Timex.shift(days: -1)

    %Wspom.Filter{
      which: :day,
      day: dt.day, month: dt.month,
      prev_date: prev_date, next_date: next_date}
  end

  # This function is only called on the initial page load.
  @spec default() :: %Wspom.Filter{}
  def default() do
    init_day_from_date(Timex.now("America/Montreal"))
  end

  @spec from_params(%{}, [%Wspom.Entry{}]) :: %Wspom.Filter{}
  def from_params(%{"filter" => "day", "day" => day, "month" => month}, _entries) do
    # The year can be anything in this case but let's pick a leap year
    init_day_from_date(Timex.to_date({2024, String.to_integer(month), String.to_integer(day)}))
  end
  def from_params(%{"filter" => "year", "day" => day, "month" => month, "year" => year}, entries) do
    year_int = String.to_integer(year)
    month_int = String.to_integer(month)
    day_int = String.to_integer(day)

    {:ok, now} = Date.new(year_int, month_int, day_int)

    {_now, {_min_diff_prev, prev_date}, {_min_diff_next, next_date}} =
      entries
      |> Enum.reduce({now, {-400, nil}, {400, nil}}, &find_next_prev_by_year/2)

    # Note: if there are no records before or after the date specified by PARAMS,
    # prev_date or next_date will remain nil - which is exactly what we want!
    %Wspom.Filter{
      which: :year,
      day: day_int, month: month_int, year: year_int,
      prev_date: prev_date, next_date: next_date}
  end

  @spec toString(%Wspom.Filter{}) :: String.t()
  def toString(%Wspom.Filter{which: :day, day: day, month: month}) do
    Timex.month_shortname(month) <> " " <> Integer.to_string(day)
  end
  def toString(%Wspom.Filter{which: :year, year: year}) do
    Integer.to_string(year)
  end
  def toString(_) do
    "Invalid filter"
  end

  @spec toTitle(%Wspom.Filter{}) :: String.t()
  def toTitle(%Wspom.Filter{which: :day, day: day, month: month}) do
    Timex.month_shortname(month) <> " " <> Integer.to_string(day)
  end
  def toTitle(%Wspom.Filter{which: :year, day: day, month: month, year: year}) do
    Timex.month_shortname(month) <> " " <> Integer.to_string(day)
      <> ", " <> Integer.to_string(year)
  end
  def toTitle(_) do
    "???"
  end

  def prev_link(%Wspom.Filter{which: :day, prev_date: prev_date}) do
    "/entries?filter=day&day=#{prev_date.day}&month=#{prev_date.month}"
  end
  def prev_link(%Wspom.Filter{which: :year, prev_date: prev_date}) do
    "/entries?filter=year&day=#{prev_date.day}&month=#{prev_date.month}&year=#{prev_date.year}"
  end

  def next_link(%Wspom.Filter{which: :day, next_date: next_date}) do
    "/entries?filter=day&day=#{next_date.day}&month=#{next_date.month}"
  end
  def next_link(%Wspom.Filter{which: :year, next_date: next_date}) do
    "/entries?filter=year&day=#{next_date.day}&month=#{next_date.month}&year=#{next_date.year}"
  end

  def switch_to_day_link(%Wspom.Filter{which: :year, day: day, month: month}) do
    "/entries?filter=day&day=#{day}&month=#{month}"
  end
  def switch_to_day_link(_), do: ""

  def switch_to_year_link(%Wspom.Filter{which: :day, day: day, month: month}, year) do
    "/entries?filter=year&day=#{day}&month=#{month}&year=#{year}"
  end
  def switch_to_year_link(_, _), do: ""

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

  defp find_next_prev_by_year(entry, {now, {min_diff_prev, prev_date}, {min_diff_next, next_date}} = old) do
    # Look for the next and previous dates that are the closest to 'now',
    # as measured by Date.diff.
    d = Date.diff(now, entry.date)
    cond do
      d > 0 and -d > min_diff_prev ->
        {now, {-d, entry.date}, {min_diff_next, next_date}}
      d < 0 and -d < min_diff_next ->
        {now, {min_diff_prev, prev_date}, {-d, entry.date}}
      true ->
        old
    end
  end
end
