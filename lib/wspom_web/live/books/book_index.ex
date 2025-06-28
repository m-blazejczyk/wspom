defmodule WspomWeb.Live.Books.BookIndex do
  use WspomWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket, layout: {WspomWeb.Layouts, :data_app}}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  # This is the main index page for books. It displays several cards
  # with important links (see the html.heex file).
  defp apply_action(socket, :index, _params) do
    socket
  end

  # This displays the "add reading history" popup on top of the index page,
  # keeping it all clean for the most frequent operation.
  defp apply_action(socket, :add_history, _params) do
    socket
  end
end
