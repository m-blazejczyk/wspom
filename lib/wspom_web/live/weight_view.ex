defmodule WspomWeb.Live.WeightView do
  use WspomWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket, layout: {WspomWeb.Layouts, :data_app}}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _) do
    socket
  end
  defp apply_action(socket, :data, _) do
    socket
  end
  defp apply_action(socket, :new, _) do
    socket
  end
  defp apply_action(socket, :edit, %{"id" => _id}) do
    socket
  end
  defp apply_action(socket, :charts, _) do
    socket
  end

  @impl true
  def handle_info(_, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", _, socket) do
    {:noreply, socket}
  end
end
