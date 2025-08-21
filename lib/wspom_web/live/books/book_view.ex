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

  defp apply_action(socket, :add_read, book, _params) do
    socket
    |> assign(:book, book)
    |> assign(:reading_rec, nil)
    |> assign(:page_title, "Read Book")
  end

  defp apply_action(socket, :edit_read, book, %{"hist" => record_id}) do
    socket
    |> assign(:book, book)
    |> assign(:reading_rec, book |> Book.find_reading_record(record_id))
    |> assign(:page_title, "Edit Book Reading Record")
  end

  @impl true
  def handle_event("delete", %{"id" => record_id}, socket) do
    {:ok, changed_book} = Context.delete_reading_record(record_id, socket.assigns.book)
    {:noreply, socket |> assign(:book, changed_book)}
  end

  # These are helper functions for the HEEX template
  # (That's why they are `defp`).
  defp format_type(:read), do: ""
  defp format_type(:updated), do: "Bulk update"
  defp format_type(:skipped), do: "Skipped to:"

  defp format_status(:active), do: "Active"
  defp format_status(:finished), do: "Finished"
  defp format_status(:abandoned), do: "Abandoned"

  defp format_medium(:book), do: "Printed book"
  defp format_medium(:audiobook), do: "Audiobook"
  defp format_medium(:ebook), do: "E-book"
  defp format_medium(:comics), do: "Comics / Graphic novel"

  defp format_is_fiction(true), do: "Fiction"
  defp format_is_fiction(false), do: "Non-fiction"
end
