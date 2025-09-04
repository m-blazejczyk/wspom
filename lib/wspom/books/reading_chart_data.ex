defmodule Wspom.ReadingChart.TickY do
  # `pos` should be an integer, the Y position within the chart (in pixels).
  # `text` is the string to draw next to the tick (the label).
  defstruct [:pos, :text]
end

defmodule Wspom.ReadingChart.TickX do
  # `pos` should be an integer, the X position within the chart (in pixels).
  # Both `text_xxx` fields may be nil.
  defstruct [:pos, :text_date, :text_year]
end

defmodule Wspom.ReadingChart.ReadingMarker do
  # Either `date` or `x` should be nil at all times. Initially, `date`
  # will be provided to enable some date-based calculations. Later,
  # it will be converted into the X position on the chart (in pixels).
  # The reading marker's line extends between `y_from` and `y_to`.
  # `type` is the same as in ReadingRecord.
  defstruct [:date, :x, :y_from, :y_to, :type]
end

defmodule Wspom.ReadingChart.Data do

  alias Wspom.{ReadingRecord, BookPos, Book}, warn: false
  alias Wspom.ReadingChart.{TickY, TickX, ReadingMarker}, warn: false

  # r Wspom.ReadingChart.Data
  # Wspom.ReadingChart.Data.make_from_book(Wspom.Books.Database.get_book(41), 0, 0, 1000, 400)
  def make_from_book(%Book{length: length, history: history}, x, y, w, h) do
    # We always create three ticks, at intervals that are roughly
    # "good looking" to a human. We don't need massive precision because
    # this is not a scientific chart.

    book_len = BookPos.to_comparable_int(length)

    # first_tick = book_pos_at_first_tick(length)
    # ticks = [first_tick,
    #   first_tick |> BookPos.multiply(2),
    #   first_tick |> BookPos.multiply(3)]
    # |> Enum.map(fn pos ->
    #   pos_perc = BookPos.to_comparable_int(pos) / book_len
    #   %TickY{
    #     pos: round(h * (1.0 - pos_perc)) + y,
    #     text: pos |> BookPos.to_string()}
    # end)

    {markers, _} = history
    |> Enum.reverse()
    |> Enum.map_reduce(0, fn rec, pos ->
      reading_record_to_marker(rec, pos, book_len, y, h)
    end)

    oldest_read = markers |> hd()
    # Days of week start from Monday, but Monday is a 1
    shift = Date.day_of_week(oldest_read.date) - 1
    # first_date is the Monday of the week when I started reading this book
    first_date = if shift == 0, do: oldest_read.date, else: Date.add(oldest_read.date, -shift)

    # Segments are two-week periods that begin on the Monday of the week
    # when I started reading this book.
    # The keys of this map are the indices of two-week periods.
    # This map of segments will have gaps. Example:
    # %{
    #   0 => [~D[2024-06-30]],
    #   18 => [~D[2025-03-16]],
    #   19 => [~D[2025-03-28], ~D[2025-03-27], ~D[2025-03-26], ~D[2025-03-23],
    #   ~D[2025-03-22], ~D[2025-03-21], ~D[2025-03-20], ~D[2025-03-19],
    #   ~D[2025-03-17]]
    # }
    segments_raw = markers
    |> Enum.group_by(
      fn marker -> div(Date.diff(marker.date, first_date), 14) end,
      fn marker -> marker end)

    # This will be `19` in the example above
    last_biweek_period = div(Date.diff((history |> List.first()).date, first_date), 14)

    # This is a list of segments that includes the value of [] whenever
    # there was one or more two-week period without reading history;
    # it is sorted by the period, i.e. it is in the right order.
    segments_mid = if last_biweek_period == 0 do
      # If everything happened during a single two-week period:
      [{0, segments_raw[0]}]
    else
      # If there were multiple two-week periods:
      first_period = segments_raw[0]
      1..last_biweek_period
      |> Enum.reduce([{0, first_period}], fn period_idx, acc ->
        handle_missing_periods(period_idx, segments_raw |> Map.get(period_idx, nil), acc) end)
    end
    |> Enum.sort(fn {p1, _}, {p2, _} -> p1 < p2 end)

    {list, total_width} = segments_mid
    |> Enum.map_reduce(0, fn {period_idx, marker_list}, acc ->
      {xtick, new_marker_list, new_acc} =
        make_x_tick(period_idx, first_date, marker_list, acc)
      {{xtick, new_marker_list}, new_acc} end)

    {list, _} = list
    |> Enum.map_reduce("dummy", &fix_years/2)

    width_shift = div(w - total_width, 2)
    {list, _} = list
    |> Enum.map_reduce(width_shift, &shift_segments/2)

    list
  end

  def reading_record_to_marker(%ReadingRecord{} = record, prev_pos, book_len, y, h) do
    pos_to = BookPos.to_comparable_int(record.position)
    {
      %ReadingMarker{
        date: record.date, type: record.type, x: nil,
        y_to: round(h * (1.0 - (prev_pos / book_len))) + y,
        y_from: round(h * (1.0 - (pos_to / book_len))) + y},
      pos_to
    }
  end

  # No reading history for this period and we already added an empty segment
  defp handle_missing_periods(_period_idx, nil, [{_, []} | _] = acc) do
    acc
  end
  # No reading history for this period and this is the first an empty segment
  defp handle_missing_periods(period_idx, nil, [{_, _history} | _] = acc) do
    [{period_idx, []} | acc]
  end
  # We have reading history - add it
  defp handle_missing_periods(period_idx, history, acc) do
    [{period_idx, history} | acc]
  end

  # `acc` is the x position of this segment.
  # `period_id` is reflects the time progression.
  # This function should return `{%TickX{}, new_acc}`.
  def make_x_tick(_period_idx, _first_date, [], acc) do
    {
      %TickX{pos: acc, text_date: nil, text_year: nil},
      [],
      acc + 15
    }
  end
  def make_x_tick(period_idx, first_date, marker_list, acc) do
    date = Date.add(first_date, period_idx * 14)
    date_str = Calendar.strftime(date, "%b %-d")
    {
      %TickX{pos: acc,
        text_date: date_str,
        text_year: Integer.to_string(date.year)},
      marker_list |> Enum.map(fn marker ->
        %{marker | date: nil, x: acc + 5 * Date.diff(marker.date, date)}
      end),
      acc + 5 * 14
    }
  end

  def fix_years({%TickX{text_year: nil}, _marker_list} = elem, prev_year) do
    {elem, prev_year}
  end
  def fix_years({%TickX{text_year: year}, _marker_list} = elem, prev_year)
    when year != prev_year do
    {elem, year}
  end
  def fix_years({%TickX{text_year: year} = xtick, marker_list}, prev_year)
    when year == prev_year do
    {{%{xtick | text_year: nil}, marker_list}, prev_year}
  end

  def shift_segments({%TickX{pos: pos} = xtick, marker_list}, shift) do
    {
      {
        %{xtick | pos: pos + shift},
        marker_list |> Enum.map(fn marker ->
          %{marker | x: marker.x + shift}
        end)
      },
      shift
    }
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
