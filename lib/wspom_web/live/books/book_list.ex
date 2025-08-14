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
    # TODO: Move `active` into a cookie
    show_active = params |> Map.get("active", true) |> parse_active()
    books = Context.get_all_books()
    |> filter_by_active(show_active)
    |> sort_based_on_active(show_active)
    socket = socket
    |> assign(:books, books)
    |> assign(:active, show_active)

    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  def parse_active(b) when is_boolean(b), do: b
  def parse_active("false"), do: false
  def parse_active(_), do: true

  defp filter_by_active(books, true = _show_active) do
    books |> Enum.filter(&(&1.status == :active))
  end
  defp filter_by_active(books, false = _show_active) do
    books |> Enum.filter(&(&1.status != :active))
  end

  defp sort_based_on_active(books, true = _show_active) do
    # The given function should compare two arguments, and return true if
    # the first argument precedes or is in the same place as the second one.

    # For active books, compare the dates when the books were last read.
    books |> Enum.sort(&compare_active_books/2)
  end
  defp sort_based_on_active(books, false = _show_active) do
    # For completed books, compare the dates when the books were completed.
    books |> Enum.sort(&(Date.compare(&1.finished_date, &2.finished_date) != :lt))
  end

  defp compare_active_books(%Book{history: nil}, %Book{}), do: true
  defp compare_active_books(%Book{}, %Book{history: nil}), do: false
  defp compare_active_books(%Book{history: []}, %Book{}), do: true
  defp compare_active_books(%Book{}, %Book{history: []}), do: false
  defp compare_active_books(%Book{history: [last1 | _]}, %Book{history: [last2 | _]}) do
    Date.compare(last1.date, last2.date) != :lt
  end

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
  defp apply_action(socket, :read, %{"book" => id}) do
    book = Context.get_book!(id)
    socket
    |> assign(:book, book)
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
