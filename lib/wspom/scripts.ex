defmodule Wspom.Scripts do

  @doc """
  The code in this module should be executed from inside an iex session (iex -S mix)

  Examples:
  Wspom.Scripts.create_empty_entries_db("wspom2023.dat")
  entries = Wspom.Scripts.entries_from_json("wspom2023.json")
  Wspom.Database.append_entries_and_save(entries)
  """

  def entries_from_json(filename) do
    # We expect `json` to be a list of maps
    {:ok, json} = read_json(filename)

    json |> Enum.map(&(entry_from_json(&1)))
  end

  defp read_json(filename) do
    with {:ok, body} <- File.read(filename),
         {:ok, json} <- Poison.decode(body), do: {:ok, json}
  end

  defp entry_from_json(%{} = entry) do
    [from, to] = entry["dateRange"]
    {:ok, dt_from, _} = DateTime.from_iso8601(from)
    {:ok, dt_to, _} = DateTime.from_iso8601(to)
    date_from = dt_from |> DateTime.to_date()
    date_to = dt_to |> DateTime.to_date()

    %Wspom.Entry{
      # The id will be set by the database, not here
      id: nil,
      description: entry["entry"] |> String.trim(),
      title: entry["rawDate"],
      year: date_from.year,
      month: date_from.month,
      day: date_from.day,
      weekday: date_from |> Timex.weekday(),
      date: date_from,
      importance: :normal,
      fuzzy: Date.diff(date_to, date_from),
      needs_review: false,
      tags: MapSet.new([])
    }
  end

  def create_empty_entries_db(filename) do
    if File.exists?(filename) do
      IO.puts("File #{filename} already exists; skipping")
    else
      File.write!(filename, :erlang.term_to_binary(%{
        entries: [],
        version: Wspom.Entries.Migrations.current_version(),
        is_production: true,
      }))
      IO.puts("File #{filename} created")
    end
  end

  @roman_lookup %{
    "i" => 1,
    "ii" => 2,
    "iii" => 3,
    "iv" => 4,
    "v" => 5,
    "vi" => 6,
    "vii" => 7,
    "viii" => 8,
    "ix" => 9,
    "x" => 10,
    "xi" => 11,
    "xii" => 12,
  }

  # Create an empty database if needed:
  #   Wspom.Scripts.create_empty_entries_db("wspom.dat")
  #
  # Then:
  #   entries = Wspom.Scripts.read_text("/home/michal/Documents/Wspom/test.txt", 2025)
  # or:
  #   entries = Wspom.Scripts.read_text("/home/michal/Documents/Wspom/wspom2023.toimport.txt", 2023)
  #
  # Then call:
  #   Wspom.Entries.Database.append_entries_and_save(entries)
  def read_text(filename, year) do
    {entries_raw, _} = File.read!(filename)
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.chunk_while([], &chunker/2, &wrapup/1)
    |> Enum.map_reduce(year, &validate_entry/2)

    errors = entries_raw |> Enum.filter(&find_errors/1)

    if length(errors) > 0 do
      IO.puts("Errors encountered:")

      errors
      |> Enum.map(fn {:error, error} -> error end)
      |> Enum.each(&IO.puts/1)

      nil
    else
      IO.puts("Data is valid")

      entries_raw
      |> Enum.map(fn {date, title, description} -> Wspom.Entry.new(title, description, date) end)
    end
  end

  defp chunker(elem, acc) do
    # This looks for a line composed of two or more dashes;
    # when it finds one, the accumulator is emitted as a chunk
    # and a new, empty list is returned as the new accumulator
    if elem |> String.match?(~r/^-[-]+$/) do
      {:cont, Enum.reverse(acc), []}
    else
      # If it's not the dashes then add the line to the accumulator
      # but only if it is not empty
      if String.length(elem) > 0 do
        {:cont, [elem | acc]}
      else
        {:cont, acc}
      end
    end
  end

  # This function is called at the very end of the file
  # It simply emits the accumulator
  defp wrapup(acc), do: {:cont, Enum.reverse(acc), []}

  defp validate_entry([date_str | [title_raw | content]], year) do
    with {:ok, date} <- convert_roman_date(date_str, year),
         {:ok, title} <- validate_title(title_raw) do
      {{date, title, Enum.join(content, "\n\n")}, year}
    else
      {:error, error} -> {{:error, error}, year}
    end
  end

  # Returns a {:ok, Date} or {:error, "Error message"}
  defp convert_roman_date(date_str, year) do
    # This will throw an exception if `date_str` is not
    [day_str | [month_roman | []]] = date_str |> String.split(" ")

    with {day, ""} <- Integer.parse(day_str),
         {:ok, month} <- @roman_lookup |> Map.fetch(month_roman |> String.downcase()),
         {:ok, date} <- Date.new(year, month, day) do
      {:ok, date}
    else
      _ -> {:error, "Incorrect date: #{date_str}"}
    end
  end

  defp validate_title(title) do
    if String.length(title) > 60 do
      {:error, "Title too long: #{title}"}
    else
      {:ok, title}
    end
  end

  defp find_errors({:error, _}), do: true
  defp find_errors(_), do: false
end
