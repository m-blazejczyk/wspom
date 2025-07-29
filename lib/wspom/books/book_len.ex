defmodule Wspom.BookLen do
  use Ecto.Type
  def type, do: :map

  alias Wspom.BookLen

  @parser ~r/^(?<pages>[0-9]+)$|^(?<perc>[0-9]+)%$|^(?<hours>[0-9]+):(?<minutes>[0-9]+)$/

  # `len_type` can be :pages, :time or :percent
  defstruct [:len_type, int_len: nil, time_len: nil]

  #####
  # `cast`, `load` and `dump` are implementing the Ecto.Type behavior.
  # See https://hexdocs.pm/ecto/Ecto.Type.html.

  # Provide custom casting rules.
  # Cast strings into the BookLen struct to be used at runtime
  def cast(len) when is_binary(len) do
    case BookLen.parse_str(len) do
      {:ok, _length_parsed} = ok_result ->
        ok_result
      {:error, _error} ->
        :error
    end
  end
  # Accept casting of BookLen structs as well
  def cast(%BookLen{} = len), do: {:ok, len}
  # Everything else is a failure though
  def cast(_), do: :error

  # We'll ignore `load` and `dump` because we don't use Ecto for storage.
  def load(data) do
    IO.warn("BookLen.load() was called!")
    {:ok, data}
  end

  def dump(len) do
    IO.warn("BookLen.dump() was called!")
    {:ok, len}
  end

  #####
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

  # Calculates the "percent completed" value
  # The first argument is the current position, the second one is the length
  def to_percent(%BookLen{len_type: :pages, int_len: cur_pages},
    %BookLen{len_type: :pages, int_len: len_pages}) do
    Float.round(cur_pages / len_pages * 100.0, 1)
  end
  def to_percent(%BookLen{len_type: :time, time_len: {cur_hours, cur_minutes}},
    %BookLen{len_type: :time, time_len: {len_hours, len_minutes}}) do
    Float.round((cur_hours * 60 + cur_minutes) / (len_hours * 60 + len_minutes) * 100.0, 1)
  end
  def to_percent(%BookLen{len_type: :percent, int_len: cur_percent}, _) do
    Float.round(cur_percent / 1 * 100.0, 1)
  end

  # Validates a form field representing a BookLen, entered as a string.
  # To be used in changeset() functions.
  def validate(%Ecto.Changeset{} = changeset, field) do
    with {:ok, length_str} <- changeset |> Ecto.Changeset.fetch_change(field) do
      case BookLen.parse_str(length_str) do
        {:ok, _length_parsed} ->
          changeset
        {:error, error} ->
          changeset |> Ecto.Changeset.add_error(field, error)
      end
    else
      _ -> changeset
    end
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
