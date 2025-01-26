defmodule WspomWeb.Live.Weight.WeightCharts do
  use WspomWeb, :live_view
  # alias Wspom.Weight.Context

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket, layout: {WspomWeb.Layouts, :data_app}}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end
end
