defmodule WspomWeb.Live.Books.BookView do
  use WspomWeb, :live_view

  alias Wspom.Book
  alias Wspom.Books.Context

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket, layout: {WspomWeb.Layouts, :data_app}}
  end

  @impl true
  def handle_params(%{"book" => book_id} = params, _url, socket) do
    book = Context.get_book!(book_id)
    {:noreply,
      apply_action(socket, socket.assigns.live_action, book, params)}
  end

  defp apply_action(socket, :view, book, _params) do
    socket
    |> assign(:book, book)
    |> assign(:page_title, "View Book")
  end

  defp apply_action(socket, :edit, book, _params) do
    socket
    |> assign(:book, book)
    |> assign(:page_title, "Edit Book")
  end

  defp apply_action(socket, :read, book, _params) do
    socket
    |> assign(:book, book)
    |> assign(:page_title, "Read Book")
  end

  defp apply_action(socket, :history, book, %{"hist" => hist_id}) do
    socket
    |> assign(:book, book)
    |> assign(:history, book |> Book.find_history(hist_id))
    |> assign(:page_title, "Edit Book History Record")
  end

  # These are helper functions for the HEEX template
  # (That's why they are `defp`).
  defp format_type(:read), do: ""
  defp format_type(:updated), do: "Bulk update"
  defp format_type(:skipped), do: "Skipped to:"
end
