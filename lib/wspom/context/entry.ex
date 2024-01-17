defmodule Wspom.Context.Entry do
  defstruct [:description, :title, :year, :month, :day, :weekday, id: 1,
    importance: :normal, fuzzy: 0, needs_review: false, tags: MapSet.new()]
end
