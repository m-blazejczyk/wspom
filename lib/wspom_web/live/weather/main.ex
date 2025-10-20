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
    # IO.inspect(socket.assigns.total_height)
    # IO.inspect(socket.assigns.subcharts)
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :main, _params) do
    socket
    |> assign(:page_title, "Weather")
  end

  defp make_chart(assigns) do
    ~H"""
    <svg viewBox={"0 0 1015 #{@total_height}"} role="img" xmlns="http://www.w3.org/2000/svg">
      <%= for subchart <- @subcharts do %>
        <%= make_subchart(assigns, subchart) %>
      <% end %>
    </svg>
    """
  end

  defp make_subchart(assigns, subchart) do
    assigns = assigns |> assign(subchart: subchart)

    ~H"""
    <rect x="50" y={@subchart.y_pos + 30} width="965" height={@subchart.height - 30} style="fill:rgba(255, 255, 255, 0);stroke-width:1;stroke:gray"/>
    """
  end
end
