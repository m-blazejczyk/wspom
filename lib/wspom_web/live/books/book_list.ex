defmodule WspomWeb.Live.Books.BookList do
  use WspomWeb, :live_view

  alias Wspom.Book
  alias Wspom.Books.Context

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket, layout: {WspomWeb.Layouts, :data_app}}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  # This page will list all books and provide some filtering / sorting options.
  defp apply_action(socket, :list, _params) do
    socket
    |> assign(:books, Context.get_all_records())
    |> assign(:page_title, "All Books")
  end

  # This displays the "add book" popup on top of the books list page.
  defp apply_action(socket, :add, _params) do
    socket
    |> assign(:books, Context.get_all_records())
    |> assign(:book, Book.new())
    |> assign(:page_title, "New Book")
  end

  # This displays the "read book" popup on top of the books list page.
  defp apply_action(socket, :read, _params) do
    socket
    |> assign(:books, Context.get_all_records())
    |> assign(:page_title, "Read Book")
  end

  # This displays the "edit book" popup on top of the books list page.
  defp apply_action(socket, :edit, %{"book" => id}) do
    book = Context.get_book!(id)
    socket
    |> assign(:books, Context.get_all_records())
    |> assign(:book, book)
    |> assign(:page_title, "Edit Book")
  end
end
