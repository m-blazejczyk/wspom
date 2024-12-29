defmodule Wspom.Scripts do

  @doc """
  The code in this module should be executed from inside an iex session (iex -S mix)

  Example:
  Wspom.Scripts.entries_from_json("wspom2023.json")
  """

  def entries_from_json(filename) do
    {:ok, json} = Wspom.Scripts.read_json(filename)
    raw_entry = hd(json)
    entry_from_json(raw_entry)
  end

  def read_json(filename) do
    with {:ok, body} <- File.read(filename),
         {:ok, json} <- Poison.decode(body), do: {:ok, json}
  end

  def entry_from_json(%{} = entry) do
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

end
