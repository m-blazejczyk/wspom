defmodule Wspom.ChartTick do
  defstruct [:pos, :text]
end

defmodule Wspom.ReadingChartData do

  alias Wspom.{ReadingRecord, BookPos, Book}, warn: false
  alias Wspom.{ChartTick}, warn: false

  def make_from_book(%Book{length: length, history: history}, x, y, w, h) do
    # We always create three ticks, at intervals that are roughly
    # "good looking" to a human. We don't need massive precision because
    # this is not a scientific chart.
    first_tick = book_pos_at_first_tick(length)
    [first_tick,
      first_tick |> BookPos.multiply(2),
      first_tick |> BookPos.multiply(3)]
    |> Enum.map(fn pos ->
      pos_perc = BookPos.to_comparable_int(pos) / BookPos.to_comparable_int(length)
      %ChartTick{
        pos: round(h * (1.0 - pos_perc)) + y,
        text: pos |> BookPos.to_string()}
    end)
  end

  def to_tick_pos(%BookPos{} = pos, %BookPos{} = length, x, y, w, h) do

  end

  def book_pos_at_first_tick(%BookPos{type: :pages, as_int: pages} = _length) do
    # This is a heuristic that I came up with using Google Sheets.
    # The first tick will be roughly at 25%-30% of the book length.
    scale = if pages < 300, do: 5, else: 10
    tick_pages = div(trunc(pages / 3.5), scale) * scale
    BookPos.new_pages(tick_pages)
  end
  def book_pos_at_first_tick(%BookPos{type: :time, as_time: {hours, minutes}}) do
    total_minutes = hours * 60 + minutes
    scale = 30
    tick_minutes = div(trunc(total_minutes / 3.5), scale) * scale
    BookPos.new_time(div(tick_minutes, 60), rem(tick_minutes, 60))
  end
  def book_pos_at_first_tick(%BookPos{type: :percent}) do
    BookPos.new_percent(25)
  end

end
