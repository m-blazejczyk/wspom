defmodule Wspom.BookPos do
  use Ecto.Type
  def type, do: :map

  alias Wspom.BookPos

  @parser ~r/^(?<pages>[0-9]+)$|^(?<perc>[0-9]+)%$|^(?<hours>[0-9]+):(?<minutes>[0-9]+)$/

  # `type` can be :pages, :time or :percent
  defstruct [:type, as_int: nil, as_time: nil]

  #####
  # `cast`, `load` and `dump` are implementing the Ecto.Type behavior.
  # See https://hexdocs.pm/ecto/Ecto.Type.html.

  # Provide custom casting rules.
  # Cast strings into the BookPos struct to be used at runtime
  def cast(pos) when is_binary(pos) do
    case BookPos.parse_str(pos) do
      {:ok, _pos_parsed} = ok_result ->
        ok_result
      {:error, _error} ->
        :error
    end
  end
  # Accept casting of BookPos structs as well
  def cast(%BookPos{} = pos), do: {:ok, pos}
  # Everything else is a failure though
  def cast(_), do: :error

  # We'll ignore `load` and `dump` because we don't use Ecto for storage.
  def load(data) do
    IO.warn("BookPos.load() was called!")
    {:ok, data}
  end

  def dump(pos) do
    IO.warn("BookPos.dump() was called!")
    {:ok, pos}
  end

  #####
  # Constructors
  def new_pages(pages)
  when is_integer(pages) do
    %BookPos{type: :pages, as_int: pages}
  end

  def new_time(hours, minutes)
  when is_integer(hours) and is_integer(minutes) do
    %BookPos{type: :time, as_time: {hours, minutes}}
  end

  def new_percent(percent)
  when is_integer(percent) do
    %BookPos{type: :percent, as_int: percent}
  end

  def type_to_string(:pages), do: "the number of pages"
  def type_to_string(:time), do: "time (h:mm)"
  def type_to_string(:percent), do: "percent (including the percent sign)"

  # Expected data structures (examples):
  # %BookPos{type: :pages, as_int: 120} - 120 pages
  # %BookPos{type: :time, as_time: {3, 42}} - 3 hours and 42 minutes
  # %BookPos{type: :percent, as_int: 30} - 30%
  def to_string(%BookPos{type: :pages, as_int: pages}) do
    Integer.to_string(pages)
  end
  def to_string(%BookPos{type: :time, as_time: {hours, minutes}}) do
    Integer.to_string(hours) <> ":" <>
      (if minutes < 10, do: "0", else: "") <> Integer.to_string(minutes)
  end
  def to_string(%BookPos{type: :percent, as_int: percent}) do
    Integer.to_string(percent) <> "%"
  end
  def to_string(nil), do: ""

  # Calculates the "percent completed" value
  # The first argument is the current position, the second one is the length
  def to_percent(%BookPos{type: :pages, as_int: cur_pages},
    %BookPos{type: :pages, as_int: len_pages}) do
    Float.round(cur_pages / len_pages * 100.0, 1)
  end
  def to_percent(%BookPos{type: :time, as_time: {cur_hours, cur_minutes}},
    %BookPos{type: :time, as_time: {len_hours, len_minutes}}) do
    Float.round((cur_hours * 60 + cur_minutes) / (len_hours * 60 + len_minutes) * 100.0, 1)
  end
  def to_percent(%BookPos{type: :percent, as_int: cur_percent}, _) do
    Float.round(cur_percent * 1.0, 1)
  end

  # Returns an integer that can be used to compare book position records.
  def to_comparable_int(%BookPos{type: :pages, as_int: pages}) do
    pages
  end
  def to_comparable_int(%BookPos{type: :time, as_time: {hours, minutes}}) do
    hours * 60 + minutes
  end
  def to_comparable_int(%BookPos{type: :percent, as_int: percent}) do
    percent
  end

  # Multiplies the given position by the second argument (expected to be an int).
  def multiply(%BookPos{type: :time, as_time: {hours, minutes}}, factor)
    when is_integer(factor) do
    total_minutes = (hours * 60 + minutes) * factor
    BookPos.new_time(div(total_minutes, 60), rem(total_minutes, 60))
  end
  def multiply(%BookPos{type: type, as_int: pos}, factor)
    when is_integer(factor) do
    %BookPos{type: type, as_int: pos * factor}
  end

  # Validates a form field representing a BookPos, entered as a string.
  # To be used in changeset() functions.
  def validate(%Ecto.Changeset{} = changeset, field) do
    with {:ok, pos_str} <- changeset |> Ecto.Changeset.fetch_change(field) do
      case BookPos.parse_str(pos_str) do
        {:ok, _pos_parsed} ->
          changeset
        {:error, error} ->
          changeset |> Ecto.Changeset.add_error(field, error)
      end
    else
      _ -> changeset
    end
  end

  # This function returns {:ok, %BookPos{}} or {:error, "Error message"}
  # Regex.named_captures(…) will return one of:
  #   nil - if there's no match
  #   %{"hours" => "", "minutes" => "", "pages" => "", "perc" => "17"}
  #   %{"hours" => "17", "minutes" => "16", "pages" => "", "perc" => ""}
  #   %{"hours" => "", "minutes" => "", "pages" => "18", "perc" => ""}
  def parse_str(pos_str) do
    # Match to the regex; will return nil if there's no match at all
    Regex.named_captures(@parser, pos_str |> String.trim())
    # Remove all named groups with empty values
    |> clean_up_named_captures()
    # Convert to BookPos
    |> to_book_pos()
    # Check the values
    |> check_ranges()
  end

  defp clean_up_named_captures(nil), do: nil
  defp clean_up_named_captures(%{} = map) do
    map
    |> Enum.filter(fn {_k, v} -> String.length(v) > 0 end)
    |> Map.new()
  end

  defp to_book_pos(nil), do: nil
  defp to_book_pos(%{"pages" => pages}) do
    new_pages(String.to_integer(pages))
  end
  defp to_book_pos(%{"hours" => hours, "minutes" => minutes}) do
    new_time(String.to_integer(hours), String.to_integer(minutes))
  end
  defp to_book_pos(%{"perc" => perc}) do
    new_percent(String.to_integer(perc))
  end

  defp check_ranges(nil), do: {:error, "Invalid value; must be one of: p, p%, or h:mm"}
  defp check_ranges(%BookPos{type: :pages, as_int: pages} = pos) do
    if pages >= 0 and pages <= 2000 do
      {:ok, pos}
    else
      {:error, "Invalid number of pages (enter a number between 0 and 2000)"}
    end
  end
  defp check_ranges(%BookPos{type: :time, as_time: {h, m}} = pos) do
    if h >= 0 and h <= 50 and m >= 0 and m < 60 do
      {:ok, pos}
    else
      if m < 0 or m >= 60 do
        {:error, "Invalid time (incorrect number of minutes)"}
      else
        {:error, "Invalid time (can't be more than 50h)"}
      end
    end
  end
  defp check_ranges(%BookPos{type: :percent, as_int: percent} = pos) do
    if percent >= 0 and percent <= 100 do
      {:ok, pos}
    else
      {:error, "Invalid percent value"}
    end
  end
end
