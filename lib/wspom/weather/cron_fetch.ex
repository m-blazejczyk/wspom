defmodule Wspom.Weather.CronFetch do
  use GenServer

  @interval 5_000  # 5 second interval (in milliseconds)

  # Start the GenServer
  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    # Start the first job immediately
    schedule()
    {:ok, {1, :ok}}
  end

  @impl true
  def handle_info(:fetch, {n, :ok}) do
    try do
      # Perform the task
      perform_fetch(n)

      # Schedule the next job after it finishes
      schedule()
    rescue
      e ->
        # Logger.error(Exception.format(:error, e, __STACKTRACE__))
        IO.puts("Error fetching data")
        IO.puts(Exception.format(:error, e, __STACKTRACE__))
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
