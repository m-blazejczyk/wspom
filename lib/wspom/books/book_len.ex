defmodule Wspom.BookLen do

  alias Wspom.BookLen

  @parser ~r/^(?<pages>[0-9]+)$|^(?<perc>[0-9]+)%$|^(?<hours>[0-9]+):(?<minutes>[0-9]+)$/

  # `len_type` can be :pages, :time or :percent
  defstruct [:len_type, int_len: nil, time_len: nil]

  # Constructors
  def new_pages(pages)
  when is_integer(pages) do
    %BookLen{len_type: :pages, int_len: pages}
  end

  def new_time(hours, minutes)
  when is_integer(hours) and is_integer(minutes) do
    %BookLen{len_type: :time, time_len: {hours, minutes}}
  end

  def new_percent(percent)
  when is_integer(percent) do
    %BookLen{len_type: :percent, int_len: percent}
  end

  # Expected data structures (examples):
  # %BookLen{len_type: :pages, int_len: 120} - 120 pages
  # %BookLen{len_type: :time, time_len: {3, 42}} - 3 hours and 42 minutes
  # %BookLen{len_type: :percent, int_len: 30} - 30%
  def to_string(%BookLen{len_type: :pages, int_len: pages}) do
    Integer.to_string(pages)
  end
  def to_string(%BookLen{len_type: :time, time_len: {hours, minutes}}) do
    Integer.to_string(hours) <> ":" <> Integer.to_string(minutes)
  end
  def to_string(%BookLen{len_type: :percent, int_len: percent}) do
    Integer.to_string(percent) <> "%"
  end

  # This function returns {:ok, %BookLen{}} or {:error, "Error message"}
  # Regex.named_captures(…) will return one of:
  #   nil - if there's no match
  #   %{"hours" => "", "minutes" => "", "pages" => "", "perc" => "17"}
  #   %{"hours" => "17", "minutes" => "16", "pages" => "", "perc" => ""}
  #   %{"hours" => "", "minutes" => "", "pages" => "18", "perc" => ""}
  def parse_str(len_str) do
    # Match to the regex; will return nil if there's no match at all
    Regex.named_captures(@parser, len_str |> String.trim())
    # Remove all named groups with empty values
    |> clean_up_named_captures()
    # Convert to BookLen
    |> to_book_len()
    # Check the values
    |> check_ranges()
  end

  defp clean_up_named_captures(nil), do: nil
  defp clean_up_named_captures(%{} = map) do
    map
    |> Enum.filter(fn {_k, v} -> String.length(v) > 0 end)
    |> Map.new()
  end

  defp to_book_len(nil), do: nil
  defp to_book_len(%{"pages" => pages}) do
    new_pages(String.to_integer(pages))
  end
  defp to_book_len(%{"hours" => hours, "minutes" => minutes}) do
    new_time(String.to_integer(hours), String.to_integer(minutes))
  end
  defp to_book_len(%{"perc" => perc}) do
    new_percent(String.to_integer(perc))
  end

  defp check_ranges(nil), do: {:error, "Invalid length; must be one of: p, p%, or h:mm"}
  defp check_ranges(%BookLen{len_type: :pages, int_len: pages} = len) do
    if pages >= 0 and pages <= 2000 do
      {:ok, len}
    else
      {:error, "Invalid number of pages (enter a number between 0 and 2000)"}
    end
  end
  defp check_ranges(%BookLen{len_type: :time, time_len: {h, m}} = len) do
    if h >= 0 and h <= 50 and m >= 0 and m < 60 do
      {:ok, len}
    else
      if m < 0 or m >= 60 do
        {:error, "Invalid time (incorrect number of minutes)"}
      else
        {:error, "Invalid time (can't be more than 50h)"}
      end
    end
  end
  defp check_ranges(%BookLen{len_type: :percent, int_len: percent} = len) do
    if percent >= 0 and percent <= 100 do
      {:ok, len}
    else
      {:error, "Invalid percent value"}
    end
  end
end
