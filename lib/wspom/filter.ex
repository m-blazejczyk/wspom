defmodule Wspom.Filter do
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
  def toString(_) do
    "Another filter"
  end

  def filter(%Wspom.Filter{which: :day, day: day, month: month}, entries) do
    entries
    |> Enum.filter(fn entry -> month == entry.month and day == entry.day end)
    |> Enum.sort(Entry)
  end

  def next(%Wspom.Filter{which: :day, day: day, month: month}, _entries) do
    # The year does not matter but let's pick a leap year
    new_date = Date.new!(2024, month, day) |> Timex.shift(days: 1)
    %Wspom.Filter{which: :day, day: new_date.day, month: new_date.month}
  end

  def prev(%Wspom.Filter{which: :day, day: day, month: month}, _entries) do
    # The year does not matter but let's pick a leap year
    new_date = Date.new!(2024, month, day) |> Timex.shift(days: -1)
    %Wspom.Filter{which: :day, day: new_date.day, month: new_date.month}
  end
end
