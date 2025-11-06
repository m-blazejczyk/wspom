defmodule WspomWeb.Live.Weather.Main do

  use WspomWeb, :live_view

  alias Wspom.Charts.Subchart
  alias Wspom.Weather.{Hourly, ChartData}

  # API documentation: https://weatherlink.github.io/v2-api/tutorial

  @impl true
  def mount(_params, _session, socket) do
    start = Hourly.get_last_weekly_start
    {
      :ok,
      socket
      |> assign(:page_title, "Weather")
      |> assign(:start_date, start)
      |> assign(:last_date, start)
      |> assign(:first_date, Hourly.get_first_weekly_start),
      layout: {WspomWeb.Layouts, :data_app}
    }
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :main, _params) do
    {subcharts, total_height, xticks} =
      ChartData.process_data(socket.assigns.start_date)

    socket
    |> assign(:subcharts, subcharts)
    |> assign(:total_height, total_height)
    |> assign(:xticks, xticks)
  end

  @impl true
  def handle_event("shift", %{"shift" => shift}, socket) do
    new_start = apply_shift(socket.assigns.start_date, shift)

    new_start = if new_start |> DateTime.before?(socket.assigns.first_date) do
      socket.assigns.first_date
    else
      new_start
    end
    new_start = if new_start |> DateTime.after?(socket.assigns.last_date) do
      socket.assigns.last_date
    else
      new_start
    end

    if new_start != socket.assigns.start_date do
      {subcharts, total_height, xticks} =
        ChartData.process_data(new_start)
      {
        :noreply,
        socket
        |> assign(:start_date, new_start)
        |> assign(:subcharts, subcharts)
        |> assign(:total_height, total_height)
        |> assign(:xticks, xticks)
      }
    else
      {
        :noreply,
        socket
      }
    end
  end

  defp apply_shift(start_date, "-1d"), do: Timex.shift(start_date, days: -1)
  defp apply_shift(start_date, "-1w"), do: Timex.shift(start_date, weeks: -1)
  defp apply_shift(start_date, "-1m"), do: Timex.shift(start_date, months: -1)
  defp apply_shift(start_date, "-1y"), do: Timex.shift(start_date, years: -1)
  defp apply_shift(start_date, "+1d"), do: Timex.shift(start_date, days: +1)
  defp apply_shift(start_date, "+1w"), do: Timex.shift(start_date, weeks: +1)
  defp apply_shift(start_date, "+1m"), do: Timex.shift(start_date, months: +1)
  defp apply_shift(start_date, "+1y"), do: Timex.shift(start_date, years: +1)

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

    <!-- Y tick lines -->
    <line :for={tick <- (@subchart.ticks |> Enum.drop(1) |> Enum.drop(-1))}
      x1={50} x2={1015} y1={tick.pos + @subchart.graph_pos} y2={tick.pos + @subchart.graph_pos} style="stroke:rgb(220,220,220);stroke-width:1" />

    <!-- X tick lines -->
    <line :for={tick <- @xticks}
      x1={tick.pos} x2={tick.pos} y1={@subchart.graph_pos} y2={@subchart.graph_pos + @subchart.graph_height} style="stroke:rgb(220,220,220);stroke-width:1" />

    <%= if @subchart.xticks? do %>
      <%= for tick <- @xticks do %>
        <!-- X ticks -->
        <line x1={tick.pos} x2={tick.pos} y1={@subchart.graph_pos + @subchart.graph_height} y2={@subchart.graph_pos + @subchart.graph_height + 5} style="stroke:grey;stroke-width:1" />

        <!-- X tick labels -->
        <text :if={tick.text_up} x={tick.pos + 4} y={@subchart.graph_pos + @subchart.graph_height + 20} fill="gray" font-size="16" text-anchor="start">
          <%= tick.text_up %>
        </text>
        <text :if={tick.text_down} x={tick.pos + 4} y={@subchart.graph_pos + @subchart.graph_height + 35} fill="gray" font-size="16" text-anchor="start">
          <%= tick.text_down %>
        </text>
      <% end %>
    <% end %>

    <!-- Data points -->
    <%= for series <- @subchart.series do %>
      <circle :for={{x, y} <- series.data}
        r="3" cx={x} cy={y} fill={series.color} />
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
