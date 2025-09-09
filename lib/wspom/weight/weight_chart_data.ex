defmodule Wspom.WeightChart.Data do

  # alias Wspom.ReadingChart.ReadingMarker, warn: false
  alias Wspom.Charts.{TickY, TickX}, warn: false

  # r Wspom.WeightChart.Data
  # all = Wspom.Weight.Database.get_all_records()
  # all = all |> Enum.sort(fn w_rec1, w_rec2 -> Date.compare(w_rec1.date, w_rec2.date) == :gt end)
  # all = all |> Enum.take(90)
  # Wspom.WeightChart.Data.make_from_weights(all, 0, 0, 800, 200)
  #
  # Prerequisite: `weights` must be sorted by date
  def make_from_weights(weights, x, y, w, h) do
    # Y ticks are easy: hard-coded
    yticks = 81..89
    |> Enum.map(fn w ->
      h_perc = (w - 80) / 10.0
      %TickY{
        pos: round(h * (1.0 - h_perc)) + y,
        text: Integer.to_string(w)}
    end)

    # Let's see what date range we're dealing with
    {earliest, latest, date_range} =
      with fst <- hd(weights).date,
        lst <- List.last(weights).date,
        diff <- Date.diff(fst, lst)
        do
          if diff >= 0 do
            {lst, fst, diff}
          else
            {fst, lst, -diff}
          end
        end

    # Let's see if there will be enough space for X labels if we create
    # one tick per month; assume 50 pixels per month is the minimum
    effective_width = w - 10
    tick_every_x_months =
      if effective_width / (date_range / 30) >= 50.0 do
        1
      else
        if effective_width / (date_range / 60) >= 50.0 do
          2
        else
          3
        end
      end

    [_ | remaining_dates] = tick_dates =
      add_tick([Date.beginning_of_month(earliest)], tick_every_x_months, latest)
    |> Enum.reverse()

    # After we run add_tick() recursively, we have to remove the
    # last element of the output (i.e. the earliest tick date);
    # that's because the earliest tick date corresponds to the first
    # day of the month of the first weight record, i.e. it falls outside
    # of the chart. The only exception is if the first weight record was
    # taken on the first day of a month.
    tick_dates = if earliest.day == 1, do: tick_dates, else: remaining_dates

    xticks = tick_dates
    |> Enum.map(fn tick_date ->
      w_perc = Date.diff(tick_date, earliest) / date_range
      %TickX{
        pos: round(effective_width * w_perc) + x + 5,
        text_up: Calendar.strftime(tick_date, "%b"),
        text_down: Integer.to_string(tick_date.year)}
    end)

    points = weights
    |> Enum.map(fn %{date: date, weight: weight} ->
      w_perc = Date.diff(date, earliest) / date_range
      h_perc = (weight - 80) / 10.0
      {
        round(effective_width * w_perc) + x + 5,
        round(h * (1.0 - h_perc)) + y
      }
    end)

    {xticks, yticks, points}
  end

  def add_tick([latest | _rest] = list, tick_every_x_months, stop_after) do
    next = move_date_by_months(latest, tick_every_x_months)
    if Date.diff(next, stop_after) > 0 do
      list
    else
      add_tick([next | list], tick_every_x_months, stop_after)
    end
  end

  defp move_date_by_months(date, tick_every_x_months) do
    new_month = date.month + tick_every_x_months

    if new_month > 12 do
      Date.new!(date.year + 1, new_month - 12, 1)
    else
      Date.new!(date.year, date.month + tick_every_x_months, 1)
    end
  end
end
