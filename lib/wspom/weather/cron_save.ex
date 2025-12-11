defmodule Wspom.Weather.CronSave do
  use GenServer
  require Logger

  alias Wspom.Weather.Database

  # The initial wait before we kick off the first save
  # Set it to nil to completely bypass saving
  @initial 300_000  # 5 minutes
  # Interval between saves
  @interval 86_400_000  # 24 h

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
  def handle_info(:save, nil) do
    Database.save_data()
    schedule(@interval)
    {:noreply, nil}
  end

  defp schedule(nil) do
    # Do nothing - ignore
  end
  defp schedule(i) do
    # Schedule the next execution after the specified interval
    Process.send_after(self(), :save, i)
  end
end
