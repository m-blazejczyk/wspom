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
      init_db(fake_hourly(), false)
    end
    |> summarize_db()
  end

  defp init_db(hourly \\ [], is_prod \\ true) do
    %{
      hourly: hourly,
      status: %{
        status: :success,
        last_fetch: nil,
        last_save: nil,
        description: ""
      },
      version: 2,
      is_production: is_prod,
    }
  end

  defp fake_hourly, do: []

  defp maybe_migrate_and_save(%{version: 1} = state) do
    %{state | version: 2}
    |> Map.put(:status, %{
      success: true,
      last_fetch: nil,
      last_save: nil,
      description: ""
    })
    |> DbBase.save_db_file(@db_file, @db_file_backup)
  end
  defp maybe_migrate_and_save(%{version: 2} = state) do
    %{state |
      version: 3,
      status: state.status |> Map.delete(:success) |> Map.put(:status, :success)
    }
    |> DbBase.save_db_file(@db_file, @db_file_backup)
  end
  defp maybe_migrate_and_save(%{version: 3} = state) do
    state
  end

  defp summarize_db(%{hourly: hourly, version: version} = state) do
    Logger.notice("### Weather database version #{version} ###")
    Logger.notice("### #{length(hourly)} hourly records ###")
    state
  end

  def get_stats do
    Agent.get(__MODULE__, fn %{hourly: hourly} ->
      %{hours: length(hourly),
        days: div(length(hourly), 24),
        years: length(hourly) / (24 * 365)
      }
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
  Gets the status of fetch and save operations.
  Returns the entire status map.
  """
  def get_status() do
    Agent.get(__MODULE__, fn %{status: status} -> status end)
  end

  @doc """
  Gets the full description of the status of fetch and save operations.
  Returns a string separated with \n.
  """
  def get_status_description() do
    Agent.get(__MODULE__, fn %{status: status} ->
      get_fetch_status_description(status.description)
      <> get_save_status_description(status.last_save)
    end)
  end

  defp get_fetch_status_description("" = _descr) do
    "No fetch yet recorded.\n"
  end
  defp get_fetch_status_description(descr)
  when is_binary(descr) do
    descr
  end

  defp get_save_status_description(nil = _time) do
    "No database save yet recorded.\n"
  end
  defp get_save_status_description(time) do
    "Database was last saved at #{format_time(time)}."
  end

  @doc """
  Sets the fetch status.

  `new_status` can be :success, :failed or :ignore.

  `time` should be a DateTime.
  """
  def set_fetch_status(new_status, range_str) do
    Agent.update(__MODULE__, fn %{status: status} = state ->
      now = DateTime.now!("America/Montreal")
      %{state |
        status: act_set_fetch_status(status, new_status, now, range_str)
      }
    end)
  end

  defp act_set_fetch_status(old_status, :success, time, range_str) do
    %{old_status |
      status: :success,
      last_fetch: time,
      description:
        """
        Successfully fetched weather data at #{format_time(time)}.
        Timestamp range requested: #{range_str}.
        """
    }
  end
  defp act_set_fetch_status(old_status, :ignore, time, range_str) do
    %{old_status |
      status: :ignore,
      description:
        """
        IGNORED weather data fetch at #{format_time(time)}.
        Last successful fetch was at #{format_time(old_status.last_fetch)}.
        Timestamp range requested: #{range_str}.
        """
    }
  end
  defp act_set_fetch_status(old_status, :failed, time, range_str) do
    %{old_status |
      status: :failed,
      description:
        """
        FAILED to fetch weather data at #{format_time(time)}.
        Last successful fetch was at #{format_time(old_status.last_fetch)}.
        Timestamp range requested: #{range_str}.
        """
    }
  end

  defp format_time(t) do
    t |> Calendar.strftime("%a %b %-d, %-H:%M")
  end

  @doc """
  Appends the given data to the hourly data in the database.

  The new data should have been obtained via a call to
  `Wspom.Weather.Fetcher.process_raw_data()`.

  Returns `:ok` or `{:error, message}`.
  """
  def append_hourly_data(new_data)
  when is_list(new_data) and is_map(hd(new_data)) and is_map_key(hd(new_data), :ts) do
    Agent.get_and_update(__MODULE__, fn state ->
      act_append_hourly_data(state, new_data)
    end)
  end

  defp act_append_hourly_data(%{status: %{status: :failed}} = state, _new_data) do
    Logger.warning("append_hourly_data() called on db in failed state")
    state
  end
  defp act_append_hourly_data(%{hourly: hourly} = state, new_data) do
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
  end

  @doc """
  Saves the data to the database, as is (but only if this is a production
  database).
  """
  def save_data() do
    Agent.update(__MODULE__, fn state -> act_save_data(state) end)
  end

  defp act_save_data(%{status: %{status: :failed}} = state) do
    Logger.warning("save_data() called on db in failed state")
    state
  end
  defp act_save_data(%{is_production: is_prod, status: status} = state) do
    if is_prod do
      %{state | status: %{status | last_save: DateTime.now!("America/Montreal")}}
      |> DbBase.save_db_file(@db_file, @db_file_backup)
    else
      state
    end
  end
end
