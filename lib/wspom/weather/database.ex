defmodule Wspom.Weather.Database do
  use Agent
  require Logger

  alias Wspom.{DbBase}

  @db_file "weather.dat"
  @db_file_backup "weather.bak.dat"

  def start_link([is_production: is_production]) do
    Agent.start_link(fn -> init_state(is_production) end, name: __MODULE__)
  end

  defp init_state(is_production) do
    if is_production do
      DbBase.load_db_file(@db_file, &init_db/0)
      |> maybe_migrate_and_save()
    else
      %{
        hourly: fake_hourly(),
        version: 1,
        is_production: false,
      }
    end
    |> summarize_db()
  end

  defp init_db() do
    %{
      hourly: [],
      version: 1,
      is_production: true,
    }
  end

  defp fake_hourly, do: []

  defp maybe_migrate_and_save(%{version: _current_version} = state) do
    # We will write this function when we need it!
    state
  end

  defp summarize_db(%{hourly: hourly, version: version} = state) do
    Logger.notice("### Weather database version #{version} ###")
    Logger.notice("### #{length(hourly)} hourly records ###")
    state
  end

  def get_stats do
    Agent.get(__MODULE__, fn %{hourly: hourly} ->
      %{hourly: length(hourly)}
    end)
  end

  def get_hourly_all() do
    Agent.get(__MODULE__, fn %{hourly: hourly} -> hourly end)
  end

  def get_hourly_filtered(func) do
    Agent.get(__MODULE__, fn %{hourly: hourly} -> hourly |> Enum.filter(func) end)
  end

  def get_hourly_count() do
    Agent.get(__MODULE__, fn %{hourly: hourly} -> length(hourly) end)
  end

  def get_hourly_earliest() do
    Agent.get(__MODULE__, fn %{hourly: hourly} -> hd(hourly) end)
  end
  def get_hourly_earliest(n) do
    Agent.get(__MODULE__, fn %{hourly: hourly} -> hourly |> Enum.take(n) end)
  end

  def get_hourly_latest() do
    Agent.get(__MODULE__, fn %{hourly: hourly} -> List.last(hourly) end)
  end
  def get_hourly_latest(n) do
    Agent.get(__MODULE__, fn %{hourly: hourly} -> hourly |> Enum.take(-n) end)
  end

  @doc """
  Appends the given data to the hourly data in the database.

  The new data should have been obtained via a call to
  `Wspom.Weather.Fetcher.process_raw_data()`.

  Returns `:ok` or `{:error, message}`.
  """
  def append_hourly_data(new_data)
  when is_list(new_data) and is_map(hd(new_data)) and is_map_key(hd(new_data), :ts) do
    Agent.get_and_update(__MODULE__, fn %{hourly: hourly} = state ->
      old_last = List.last(hourly).ts
      new_first = hd(new_data).ts
      if new_first - old_last != 3600 do
        {
          {:error, "Data to append starts at #{new_first}; old end: #{old_last}"},
          state
        }
      else
        {
          :ok,
          %{state | hourly: hourly ++ new_data}
        }
      end
    end)
  end

  @doc """
  Saves the data to the database, as is (but only if this is a production
  database).
  """
  def save_data() do
    Agent.update(__MODULE__,
      fn %{is_production: is_prod} = state ->
        if is_prod do
          state |> DbBase.save_db_file(@db_file, @db_file_backup)
        end

        state
      end)
  end
end
