defmodule WspomWeb.Live.Weight.WeightData do
  use WspomWeb, :live_view

  alias Wspom.Weight.Context

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket, layout: {WspomWeb.Layouts, :data_app}}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {
      :noreply,
      socket
      |> assign(:chart_days, nil)
      |> assign(:records,
        Context.get_all_records
        |> Enum.sort(&(Date.before?(&2.date, &1.date))))
    }
  end

  @impl true
  def handle_event("chart_days", %{"value" => chart_days}, socket)
    when (chart_days == nil) or (is_integer(chart_days) and chart_days > 0 and chart_days < 5000) do
    {:noreply, socket |> assign(:chart_days, chart_days)}
  end

  # These are helper functions for the HEEX template
  # (That's why they are `defp`).
  defp format_weight(w) when is_integer(w), do: Integer.to_string(w) <> ".00"
  defp format_weight(w) when is_float(w), do: :erlang.float_to_binary(w, [{:decimals, 2}])

  defp format_date(d), do: Date.to_string(d)

  defp chart_days_switch_class(button_days, chart_days) do
    base_class = "border-r border-stroke px-4 py-1 font-medium last-of-type:border-r-0"
    if button_days == chart_days do
      "bg-green-700 text-gray-100 " <> base_class
    else
      "text-gray-500 " <> base_class
    end
  end

  # 740 - 815
  defp make_chart(assigns, width) do
    data = if assigns.chart_days == nil do
      assigns.records
    else
      assigns.records |> Enum.take(assigns.chart_days)
    end
    {xticks, yticks, points} = Wspom.WeightChart.Data.make_from_weights(
      data, 50, 10, width - 75, 380)
    assigns = assigns
    |> assign(:xticks, xticks)
    |> assign(:yticks, yticks)
    |> assign(:points, points)
    |> assign(:width, width)

    ~H"""
    <svg width={@width} height="435" xmlns="http://www.w3.org/2000/svg">
      <rect x="50" y="10" width={@width - 75} height="380" style="fill:rgba(255, 255, 255, 0);stroke-width:1;stroke:gray"/>

      <!-- Top of the box: value of 90 -->
      <line x1="42" y1="10" x2="50" y2="10" style="stroke:grey;stroke-width:1" />
      <text x="38" y="15" fill="gray" font-size="16" text-anchor="end">
        90
      </text>

      <!-- Y ticks -->
      <%= for tick <- @yticks do %>
        <line x1="42" x2="50" y1={tick.pos} y2={tick.pos} style="stroke:grey;stroke-width:1" />
        <line x1="50" x2={@width - 25} y1={tick.pos} y2={tick.pos} style="stroke:rgb(220,220,220);stroke-width:1" />
        <text x="38" y={tick.pos + 5} fill="gray" font-size="16" text-anchor="end">
          <%= tick.text %>
        </text>
      <% end %>

      <!-- Bottom of the box: value of 80 -->
      <line x1="42" y1="390" x2="50" y2="390" style="stroke:grey;stroke-width:1" />
      <text x="38" y="395" fill="gray" font-size="16" text-anchor="end">
        80
      </text>

      <%= for tick <- @xticks do %>
        <!-- X ticks -->
        <line x1={tick.pos} x2={tick.pos} y1="390" y2="400" style="stroke:grey;stroke-width:1" />
        <line x1={tick.pos} x2={tick.pos} y1="10" y2="390" style="stroke:rgb(220,220,220);stroke-width:1" />

        <!-- X tick labels -->
        <%= if tick.text_up do %>
          <text x={tick.pos + 4} y="406" fill="gray" font-size="16" text-anchor="start">
            <%= tick.text_up %>
          </text>
        <% end %>
        <%= if tick.text_down do %>
          <text x={tick.pos + 4} y="425" fill="gray" font-size="16" text-anchor="start">
            <%= tick.text_down %>
          </text>
        <% end %>
      <% end %>

      <!-- Data points -->
      <%= for {x, y} <- @points do %>
        <circle r="4" cx={x} cy={y} fill="rgb(208,62,62)" />
      <% end %>

    </svg>
    """
  end
end
