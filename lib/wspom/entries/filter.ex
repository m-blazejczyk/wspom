defmodule Wspom.Entries.Filter do
  alias Timex.DateTime
  use Timex

  alias Wspom.Entry
  alias Wspom.Entries.Filter

  use Phoenix.VerifiedRoutes, endpoint: WspomWeb.Endpoint, router: WspomWeb.Router

  # In addition to the "current" state of the filter, we also have to
  # store the "Next" and "Previous" so that it can be used to generate links.
  # Allowed values of 'which': :day, :year and :tag.
  defstruct [:which, :day, :month, :year, :tag, :prev_date, :next_date]

  @spec init_day_filter_from_date(DateTime.t()) :: %Filter{}
  defp init_day_filter_from_date(dt) do
    next_date = dt |> Timex.shift(days: 1)
    prev_date = dt |> Timex.shift(days: -1)

    %Filter{
      which: :day,
      day: dt.day, month: dt.month,
      prev_date: prev_date, next_date: next_date}
  end

  # This function is only called on the initial page load.
  @spec default() :: %Filter{}
  def default() do
    init_day_filter_from_date(Timex.now("America/Montreal"))
  end

  @spec from_entry(%Wspom.Entry{}) :: %Filter{}
  def from_entry(entry) do
    init_day_filter_from_date(entry.date)
  end

  @spec from_params(%{}, [%Wspom.Entry{}]) :: %Filter{}
  def from_params(%{"filter" => "day", "day" => day, "month" => month}, _entries) do
    # The year can be anything in this case but let's pick a leap year
    init_day_filter_from_date(Timex.to_date({2024, String.to_integer(month), String.to_integer(day)}))
  end
  def from_params(%{"filter" => "year", "day" => day, "month" => month, "year" => year}, entries) do
    year_int = String.to_integer(year)
    month_int = String.to_integer(month)
    day_int = String.to_integer(day)

    {:ok, now} = Date.new(year_int, month_int, day_int)

    {_now, {_min_diff_prev, prev_date}, {_min_diff_next, next_date}} =
      entries
      |> Enum.reduce({now, {-100000, nil}, {100000, nil}}, &find_next_prev_by_year/2)

    # Note: if there are no records before or after the date specified by PARAMS,
    # prev_date or next_date will remain nil - which is exactly what we want!
    %Filter{
      which: :year,
      day: day_int, month: month_int, year: year_int,
      prev_date: prev_date, next_date: next_date}
  end
  def from_params(%{"filter" => "tag", "day" => day, "month" => month, "year" => year, "tag" => tag}, entries) do
    year_int = String.to_integer(year)
    month_int = String.to_integer(month)
    day_int = String.to_integer(day)

    {:ok, now} = Date.new(year_int, month_int, day_int)

    {_now, _tag, {_min_diff_prev, prev_date}, {_min_diff_next, next_date}} =
      entries
      |> Enum.reduce({now, tag, {-100000, nil}, {100000, nil}}, &find_next_prev_by_year_tag/2)

    # Note: if there are no records before or after the date specified by PARAMS,
    # prev_date or next_date will remain nil - which is exactly what we want!
    %Filter{
      which: :tag,
      day: day_int, month: month_int, year: year_int,
      tag: tag,
      prev_date: prev_date, next_date: next_date}
  end

  @spec toString(%Filter{}) :: String.t()
  def toString(%Filter{which: :day, day: day, month: month}) do
    Timex.month_shortname(month) <> " " <> Integer.to_string(day)
  end
  def toString(%Filter{which: :year, year: year}) do
    Integer.to_string(year)
  end
  def toString(%Filter{which: :tag, tag: tag}) do
    tag
  end
  def toString(_) do
    "Invalid filter"
  end

  @spec toTitle(%Filter{}) :: String.t()
  def toTitle(%Filter{which: :day, day: day, month: month}) do
    Timex.month_shortname(month) <> " " <> Integer.to_string(day)
  end
  def toTitle(%Filter{which: :year, day: day, month: month, year: year}) do
    Timex.month_shortname(month) <> " " <> Integer.to_string(day)
      <> ", " <> Integer.to_string(year)
  end
  def toTitle(%Filter{which: :tag, day: day, month: month, year: year, tag: tag}) do
    tag <> " - "
      <> Timex.month_shortname(month) <> " " <> Integer.to_string(day)
      <> ", " <> Integer.to_string(year)
  end
  def toTitle(_) do
    "???"
  end

  def current_link(%Filter{which: :day, day: day, month: month}) do
    ~p"/entries?filter=day&day=#{day}&month=#{month}"
  end
  def current_link(%Filter{which: :year, day: day, month: month, year: year}) do
    ~p"/entries?filter=year&day=#{day}&month=#{month}&year=#{year}"
  end
  def current_link(%Filter{which: :tag, day: day, month: month, year: year, tag: tag}) do
    ~p"/entries?filter=tag&tag=#{tag}&day=#{day}&month=#{month}&year=#{year}"
  end

  def prev_link(%Filter{prev_date: nil}) do
    ""
  end
  def prev_link(%Filter{which: :day, prev_date: prev_date}) do
    ~p"/entries?filter=day&day=#{prev_date.day}&month=#{prev_date.month}"
  end
  def prev_link(%Filter{which: :year, prev_date: prev_date}) do
    ~p"/entries?filter=year&day=#{prev_date.day}&month=#{prev_date.month}&year=#{prev_date.year}"
  end
  def prev_link(%Filter{which: :tag, tag: tag, prev_date: prev_date}) do
    ~p"/entries?filter=tag&tag=#{tag}&day=#{prev_date.day}&month=#{prev_date.month}&year=#{prev_date.year}"
  end

  def next_link(%Filter{next_date: nil}) do
    ""
  end
  def next_link(%Filter{which: :day, next_date: next_date}) do
    ~p"/entries?filter=day&day=#{next_date.day}&month=#{next_date.month}"
  end
  def next_link(%Filter{which: :year, next_date: next_date}) do
    ~p"/entries?filter=year&day=#{next_date.day}&month=#{next_date.month}&year=#{next_date.year}"
  end
  def next_link(%Filter{which: :tag, tag: tag, next_date: next_date}) do
    ~p"/entries?filter=tag&tag=#{tag}&day=#{next_date.day}&month=#{next_date.month}&year=#{next_date.year}"
  end

  def switch_to_day_link(%Filter{day: day, month: month}) do
    ~p"/entries?filter=day&day=#{day}&month=#{month}"
  end

  def switch_to_year_link(%Filter{day: day, month: month}, year) do
    ~p"/entries?filter=year&day=#{day}&month=#{month}&year=#{year}"
  end

  def switch_to_tag_link(%Filter{day: day, month: month}, year, tag) do
    ~p"/entries?filter=tag&tag=#{tag}&day=#{day}&month=#{month}&year=#{year}"
  end

  @spec filter(%Filter{}, list(%Wspom.Entry{})) :: list(%Wspom.Entry{})
  def filter(%Filter{which: :day, day: day, month: month}, entries) do
    # Return entries for the given day across all years.
    entries
    |> Enum.filter(fn entry -> month == entry.month and day == entry.day end)
    |> Enum.sort(&Entry.compare_years/2)  # Sort by year.
  end
  def filter(%Filter{which: :year, day: day, month: month, year: year}, entries) do
    # Return entries for the given day on one specific year.
    entries
    |> Enum.filter(fn entry -> year == entry.year and month == entry.month and day == entry.day end)
  end
  def filter(%Filter{which: :tag, day: day, month: month, year: year, tag: tag}, entries) do
    # Return entries for the given day on one specific year, and only the ones
    # tagged with a specific tag.
    entries
    |> Enum.filter(fn entry ->
      year == entry.year and month == entry.month and day == entry.day
        and entry.tags |> MapSet.member?(tag)
    end)
  end

  defp find_next_prev_by_year(entry, {now, {min_diff_prev, prev_date}, {min_diff_next, next_date}} = old) do
    # Look for the next and previous dates that are the closest to `now`,
    # as measured by Date.diff().
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

  defp find_next_prev_by_year_tag(
    entry, {now, tag, {min_diff_prev, prev_date}, {min_diff_next, next_date}} = old) do
    # Look for the next and previous dates that are the closest to `now`,
    # as measured by Date.diff(), but also take tags into account.
    if entry.tags |> MapSet.member?(tag) do
      d = Date.diff(now, entry.date)
      cond do
        d > 0 and -d > min_diff_prev ->
          {now, tag, {-d, entry.date}, {min_diff_next, next_date}}
        d < 0 and -d < min_diff_next ->
          {now, tag, {min_diff_prev, prev_date}, {-d, entry.date}}
        true ->
          old
      end
    else
      old
    end
  end
end
