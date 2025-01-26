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
      |> assign(:data,
        Context.get_all_records
        |> Enum.sort(&(&2.date <= &1.date))
        |> Enum.take(30))
    }
  end


  defp format_weight(w) when is_integer(w), do: Integer.to_string(w) ++ ".00"
  defp format_weight(w) when is_float(w), do: :erlang.float_to_binary(w, [{:decimals, 2}])

  defp format_date(d), do: Date.to_string(d)
end
