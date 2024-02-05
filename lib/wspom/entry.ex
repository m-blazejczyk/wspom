defmodule Wspom.Entry do
  defstruct [:description, :title, :year, :month, :day, :weekday,
    importance: :normal, fuzzy: 0, needs_review: false, tags: MapSet.new()]
end
