defmodule Wspom.Charts.TickY do
  # `pos` should be an integer, the Y position within the chart (in pixels).
  # `text` is the string to draw next to the tick (the label); may be nil.
  defstruct [:pos, :text]
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
  defstruct [:name, :min, :max, :data]
end

defmodule Wspom.Charts.Subchart do
  # `name` is the name to be displayed on the Y axis
  # `min` and `max` are the minimum and maximum values of all the series
  # belonging to this subchart
  # `series` is a list of Series structs
  # `major_tick` and `minor_tick` are the "lengths" of those ticks, in chart units
  # `ticks` is a list of TickY structs
  # `height` is the height of the chart in pixels, and `y_pos` - its Y position,
  # in pixels as well
  defstruct [
    :name, :min, :max, :series,
    :major_tick, :minor_tick, :ticks,
    :height, :y_pos
  ]
end
