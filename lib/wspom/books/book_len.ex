defmodule Wspom.BookLen do
  # This module collects some utility functions for tuples that represent
  # book lengths and book positions.
  #
  # Expected data structures (examples):
  # {:pages, 120} - 120 pages
  # {:time, 3, 42} - 3 hours and 42 minutes
  # {:percent, 30} - 30%
  def len_to_string({:pages, pages}) when is_integer(pages) do
    Integer.to_string(pages)
  end
  def len_to_string({:time, hours, minutes}) when is_integer(hours) and is_integer(minutes) do
    Integer.to_string(hours) <> ":" <> Integer.to_string(minutes)
  end
  def len_to_string({:percent, percent}) when is_integer(percent) do
    Integer.to_string(percent) <> "%"
  end
end
