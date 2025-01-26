defmodule WspomWeb.Live.Weight.WeightEdit do
  use WspomWeb, :live_view
  # alias Wspom.Weight.Context

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket, layout: {WspomWeb.Layouts, :data_app}}
  end

  @impl true
  def render(%{live_action: :add} = assigns) do
    ~H"""
    <.live_component
      module={WspomWeb.Live.WeightEditForm}
      id={:new}
      title="Add a Weight Measurement"
      action={@live_action}
      data={nil}
      patch={~p"/weight/data"}
    />
    """
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :add, _) do
    socket
  end
  defp apply_action(socket, :edit, %{"id" => _id}) do
    socket
  end
end
