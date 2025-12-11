defmodule Wspom.Weather.CronFetch do
  use GenServer
  require Logger

  alias Wspom.Weather.{Database, Fetcher}

  # The initial wait before we kick off the first fetch
  # Set it to nil to completely bypass fetching
  @initial 60_000  # 1 minute
  # Interval between fetches
  @interval 3_600_000  # 1 hour

  # Start the GenServer
  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    schedule(@initial)
    {:ok, nil}
  end

  @impl true
  def handle_info(:fetch, nil) do
    fetch(Fetcher.timestamps_to_fetch)
    {:noreply, nil}
  end

  defp fetch({:ignore, start_ts, end_ts}) do
    ts_range  = "#{start_ts}-#{end_ts}"
    Logger.info("*** IGNORED fetch for #{ts_range} ***")
    Database.set_fetch_status(:ignore, ts_range)
    schedule(@interval)
  end
  defp fetch({:ok, start_ts, end_ts}) do
    ts_range  = "#{start_ts}-#{end_ts}"
    try do
      # Perform the task
      perform_fetch(start_ts, end_ts)

      Logger.info("*** SUCCESSFUL fetch for #{ts_range} ***")
      Database.set_fetch_status(:success, ts_range)

      # Schedule the next fetch after the current one completes
      # This is important because if `perform_fetch()` throws an
      # exception, this code will never be executed and the process
      # loop will stop and no more data will be fetched
      schedule(@interval)
    rescue
      e ->
        # There is no way to get the stacktrace from the exception
        Logger.error("*** ERROR fetching data ***")
        Logger.error("*** Timestamp range: #{ts_range} ***")
        Logger.error(Exception.format(:error, e))

        Database.set_fetch_status(:failed, ts_range)
    end
  end

  defp perform_fetch(start_ts, end_ts) do
    Fetcher.download_weather_data(start_ts, end_ts)
    |> Fetcher.process_raw_data
    |> Database.append_hourly_data
  end

  defp schedule(nil) do
    # Do nothing - ignore
  end
  defp schedule(i) do
    # Schedule the next execution after the specified interval
    Process.send_after(self(), :fetch, i)
  end
end
