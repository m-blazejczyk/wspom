defmodule Wspom.Charts.TickY do
  # `pos` should be an integer, the Y position within the chart (in pixels).
  # `text` is the string to draw next to the tick (the label).
  defstruct [:pos, :text]
end

defmodule Wspom.Charts.TickX do
  # `pos` should be an integer, the X position within the chart (in pixels).
  # Both `text_xxx` fields may be nil.
  defstruct [:pos, :text_up, :text_down]
end
