defmodule Wspom.Weather.CronFetch do
  use GenServer

  @interval 2_000  # 2 second interval (in milliseconds)

  # Start the GenServer
  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    schedule()
    {:ok, {1, :ok}}
  end

  @impl true
  def handle_info(:fetch, {n, :ok}) do
    try do
      # Perform the task
      perform_fetch(n)

      # Schedule the next fetch after the current one completes
      # This is important because if `perform_fetch()` throws an
      # exception, this code will never be executed and the process
      # loop will stop and no more data will be fetched
      schedule()
    rescue
      e ->
        # There is no way to get the stacktrace from the exception
        # Logger.error(Exception.format(:error, e, __STACKTRACE__))
        IO.puts("Error fetching data")
        IO.puts(Exception.format(:error, e))
    end

    {:noreply, {n + 1, :ok}}
  end

  defp schedule() do
    # Schedule the next execution after the specified interval
    Process.send_after(self(), :fetch, @interval)
  end

  defp perform_fetch(n) do
    v = n / (n - 5)

    IO.puts("Cron executed at #{DateTime.utc_now()}, v = #{v}")
  end
end
