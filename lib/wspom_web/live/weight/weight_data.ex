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
      |> assign(:records,
        Context.get_all_records
        |> Enum.sort(&(Date.before?(&2.date, &1.date))))
    }
  end

  # These are helper functions for the HEEX template
  # (That's why they are `defp`).
  defp format_weight(w) when is_integer(w), do: Integer.to_string(w) <> ".00"
  defp format_weight(w) when is_float(w), do: :erlang.float_to_binary(w, [{:decimals, 2}])

  defp format_date(d), do: Date.to_string(d)

  defp make_chart(assigns) do
    {xticks, yticks, points} = Wspom.WeightChart.Data.make_from_weights(
      assigns.records |> Enum.take(90), 50, 10, 740, 380)
    assigns = assigns
    |> assign(:xticks, xticks)
    |> assign(:yticks, yticks)
    |> assign(:points, points)

    ~H"""
    <svg width="1000" height="435" xmlns="http://www.w3.org/2000/svg">
      <rect x="50" y="10" width="740" height="380" style="fill:rgba(255, 255, 255, 0);stroke-width:1;stroke:gray"/>

      <!-- Top of the box: value of 90 -->
      <line x1="42" y1="10" x2="50" y2="10" style="stroke:grey;stroke-width:1" />
      <text x="38" y="15" fill="gray" font-size="16" text-anchor="end">
        90
      </text>

      <!-- Y ticks -->
      <%= for tick <- @yticks do %>
        <line x1="42" x2="50" y1={tick.pos} y2={tick.pos} style="stroke:grey;stroke-width:1" />
        <line x1="50" x2="790" y1={tick.pos} y2={tick.pos} style="stroke:rgb(220,220,220);stroke-width:1" />
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
        <!-- Y ticks -->
        <line x1={tick.pos} x2={tick.pos} y1="390" y2="400" style="stroke:grey;stroke-width:1" />
        <line x1={tick.pos} x2={tick.pos} y1="10" y2="390" style="stroke:rgb(220,220,220);stroke-width:1" />

        <!-- Y tick labels -->
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
    </svg>
    """
  end
end
