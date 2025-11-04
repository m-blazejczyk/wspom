defmodule Wspom.Weather.Database do
  use Agent
  require Logger

  alias Wspom.{DbBase}

  @db_file "weather.dat"
  # @db_file_backup "weather.bak.dat"

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

  def get_hourly_latest() do
    Agent.get(__MODULE__, fn %{hourly: hourly} -> List.last(hourly) end)
  end
end
