defmodule WspomWeb.Live.Weather.Main do

  use WspomWeb, :live_view

  alias Wspom.Charts.Subchart
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

  defp make_subchart(assigns, %Subchart{ticks: ticks} = subchart)
  when ticks != nil do
    # IO.inspect(subchart.ticks, label: subchart.name)
    assigns = assigns |> assign(subchart: subchart)

    ~H"""
    <text x="50" y={@subchart.graph_pos - 5} fill="black" font-size="22">
      <%= @subchart.name %>
    </text>
    <rect x="50" y={@subchart.graph_pos} width="965" height={@subchart.graph_height} style="fill:rgba(255, 255, 255, 0);stroke-width:1;stroke:gray"/>

    <%= for tick <- @subchart.ticks do %>
      <line x1={50 - 8} x2={50} y1={tick.pos + @subchart.graph_pos} y2={tick.pos + @subchart.graph_pos} style="stroke:grey;stroke-width:1" />

      <text x={50 - 12} y={tick.pos + @subchart.graph_pos + 5} fill="gray" font-size="16" text-anchor="end">
        <%= tick.text %>
      </text>
    <% end %>

    <line :for={tick <- (@subchart.ticks |> Enum.drop(1) |> Enum.drop(-1))}
      x1={50} x2={1015} y1={tick.pos + @subchart.graph_pos} y2={tick.pos + @subchart.graph_pos} style="stroke:rgb(220,220,220);stroke-width:1" />

    <%= for tick <- @subchart.xticks do %>
      <!-- X ticks -->
      <line x1={tick.pos} x2={tick.pos} y1={@subchart.graph_pos + @subchart.graph_height} y2={@subchart.graph_pos + @subchart.graph_height + 5} style="stroke:grey;stroke-width:1" />
      <line x1={tick.pos} x2={tick.pos} y1={@subchart.graph_pos} y2={@subchart.graph_pos + @subchart.graph_height} style="stroke:rgb(220,220,220);stroke-width:1" />

      <!-- X tick labels -->
      <text :if={tick.text_up != nil} x={tick.pos + 4} y={@subchart.graph_pos + @subchart.graph_height + 16} fill="gray" font-size="16" text-anchor="start">
        <%= tick.text_up %>
      </text>
    <% end %>

    <!-- Data points -->
    <%= for series <- @subchart.series do %>
      <circle :for={{x, y} <- series.data}
        r="3" cx={x} cy={y} fill="rgb(208,62,62)" />
    <% end %>
    """
  end
  defp make_subchart(assigns, subchart) do
    # This variant will draw the wind direction chart
    assigns = assigns |> assign(subchart: subchart)

    ~H"""
    <text x="50" y={@subchart.graph_pos - 5} fill="black" font-size="22">
      <%= @subchart.name %> (special chart)
    </text>
    <rect x="50" y={@subchart.graph_pos} width="965" height={@subchart.graph_height} style="fill:rgba(255, 255, 255, 0);stroke-width:1;stroke:gray"/>
    """
  end
end
