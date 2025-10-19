defmodule WspomWeb.Live.Weather.Main do

  use WspomWeb, :live_view

  alias Wspom.Weather.ChartData

  # API documentation: https://weatherlink.github.io/v2-api/tutorial

  @impl true
  def mount(_params, _session, socket) do
    {subcharts, total_height} = ChartData.process_data
    {:ok, socket
      |> assign(:subcharts, subcharts)
      |> assign(:total_height, total_height),
      layout: {WspomWeb.Layouts, :data_app}}
  end

  @impl true
  def handle_params(params, _url, socket) do
    IO.inspect(socket.assigns.total_height)
    IO.inspect(socket.assigns.subcharts)
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :main, _params) do
    socket
    |> assign(:page_title, "Weather")
  end
end
