defmodule Wspom.Charts.TickY do
  # `pos` should be an integer, the Y position within the chart (in pixels).
  # `raw_pos` is the position in chart units (for reference only).
  # `text` is the string to draw next to the tick (the label); may be nil.
  defstruct [:pos, :raw_pos, :text]
end

defmodule Wspom.Charts.TickX do
  # `pos` should be an integer, the X position within the chart (in pixels).
  # Both `text_xxx` fields may be nil.
  defstruct [:pos, :text_up, :text_down]
end

defmodule Wspom.Charts.Series do
  # `name` is the name to be displayed on the legend
  # `min` and `max` are the minimum and maximum values of the series
  # `data` is a list of numbers that may contain `nil` values
  # In later stages, `data` will be a list of tuples: {x, y}, or nil values
  # `color` is suitable for SVN
  defstruct [:name, :min, :max, :data, :color]
end

defmodule Wspom.Charts.Subchart do
  # `name` is the name to be displayed on the Y axis
  # `position` is one of: :top, :middle, :bottom
  # `min` and `max` are the minimum and maximum values of all the series
  # belonging to this subchart
  # `series` is a list of Series structs
  # `tick_len` is the distance between ticks, in chart units
  # `ticks` is a list of TickY structs
  # `xticks?` - true if x-ticks should be drawn
  # `chart_height` is the height of the entire chart in pixels
  # `chart_pos` is its Y position, in pixels as well (including the title etc.)
  # `graph_xxx` are the same but for the graph box
  defstruct [
    :name, :position, :min, :max, :series,
    :tick_len, :ticks, :xticks?,
    :min_limit, :max_limit,
    :chart_height, :chart_pos, :graph_height, :graph_pos
  ]
end
