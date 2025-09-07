defmodule Wspom.WeightChart.Data do

  # alias Wspom.ReadingChart.ReadingMarker, warn: false
  alias Wspom.Charts.{TickY, TickX}, warn: false

  # r Wspom.WeightChart.Data
  # Wspom.WeightChart.Data.make_from_weights(Wspom.Weight.Database.get_all_records() |> Enum.take(90), 0, 0, 800, 200)
  def make_from_weights(weights, x, y, w, h) do
    # Y ticks are easy: hard-coded
    yticks = 81..89
    |> Enum.map(fn w ->
      w_perc = (w - 80) / 10.0
      %TickY{
        pos: round(h * (1.0 - w_perc)) + y,
        text: Integer.to_string(w)}
    end)
  end
end
