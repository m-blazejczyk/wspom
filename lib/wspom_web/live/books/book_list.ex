defmodule WspomWeb.Live.Books.BookList do
alias Ecto.Query.BooleanExpr
  use WspomWeb, :live_view

  alias Wspom.Book
  alias Wspom.Books.Context

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket, layout: {WspomWeb.Layouts, :data_app}}
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket = socket
    |> assign(:books, Context.get_all_books())
    |> assign(:active, params |> Map.get("active", true) |> parse_active())

    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  def parse_active(b) when is_boolean(b), do: b
  def parse_active("false"), do: false
  def parse_active(_), do: true

  # This page will list all books and provide some filtering / sorting options.
  defp apply_action(socket, :list, _params) do
    socket
    |> assign(:page_title, "All Books")
  end

  # This displays the "add book" popup on top of the books list page.
  defp apply_action(socket, :add, _params) do
    socket
    |> assign(:book, Book.new())
    |> assign(:page_title, "New Book")
  end

  # This displays the "read book" popup on top of the books list page.
  defp apply_action(socket, :read, _params) do
    socket
    |> assign(:page_title, "Read Book")
  end

  # This displays the "edit book" popup on top of the books list page.
  defp apply_action(socket, :edit, %{"book" => id}) do
    book = Context.get_book!(id)
    socket
    |> assign(:book, book)
    |> assign(:page_title, "Edit Book")
  end
end
