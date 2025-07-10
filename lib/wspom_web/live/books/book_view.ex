defmodule WspomWeb.Live.Books.BookView do
  use WspomWeb, :live_view

  # alias Wspom.Book
  alias Wspom.Books.Context

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket, layout: {WspomWeb.Layouts, :data_app}}
  end

  @impl true
  def handle_params(%{"book" => id}, _, socket) do
    {
      :noreply,
      socket
        |> assign(:page_title, page_title(socket.assigns.live_action))
        |> assign(:book, Context.get_book!(id))
    }
  end

  defp page_title(:view), do: "View Book"
  defp page_title(:edit), do: "Edit Book"
end
