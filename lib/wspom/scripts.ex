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
end
