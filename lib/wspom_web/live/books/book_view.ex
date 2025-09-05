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

  defp make_chart(assigns) do
    data = Wspom.ReadingChart.Data.make_from_book(assigns.book, 50, 10, 940, 380)

    ~H"""
    <svg width="1000" height="435" xmlns="http://www.w3.org/2000/svg">
      <rect x="50" y="10" width="940" height="380" style="fill:rgba(255, 255, 255, 0);stroke-width:1;stroke:gray"/>

      <line x1="42" y1="10" x2="50" y2="10" style="stroke:grey;stroke-width:1" />
      <text x="38" y="15" fill="gray" font-size="16" text-anchor="end">380</text>

      <line x1="42" y1="100" x2="50" y2="100" style="stroke:grey;stroke-width:1" />
      <line x1="50" y1="100" x2="990" y2="100" style="stroke:rgb(220,220,220);stroke-width:1" />
      <text x="38" y="105" fill="gray" font-size="16" text-anchor="end">300</text>

      <line x1="42" y1="390" x2="50" y2="390" style="stroke:grey;stroke-width:1" />
      <text x="38" y="395" fill="gray" font-size="16" text-anchor="end">0</text>

      <line x1="500" x2="500" y1="390" y2="400" style="stroke:grey;stroke-width:1" />
      <line x1="500" x2="500" y1="10" y2="390" style="stroke:rgb(220,220,220);stroke-width:1" />
      <text x="504" y="406" fill="gray" font-size="16" text-anchor="start">Aug 25</text>

      <line x1="570" x2="570" y1="390" y2="400" style="stroke:grey;stroke-width:1" />
      <line x1="570" x2="570" y1="10" y2="390" style="stroke:rgb(220,220,220);stroke-width:1" />
      <text x="574" y="406" fill="gray" font-size="16" text-anchor="start">Sep 8</text>

      <text x="504" y="425" fill="gray" font-size="16" text-anchor="start">2025</text>

      <line x1="500" x2="500" y1="390" y2="300" style="stroke:rgb(208,62,62);stroke-width:4" />
      <line x1="505" x2="505" y1="300" y2="280" style="stroke:rgb(208,62,62);stroke-width:4" />
      <line x1="515" x2="515" y1="280" y2="254" style="stroke:rgb(208,62,62);stroke-width:4" />
      <line x1="520" x2="520" y1="254" y2="218" style="stroke:rgb(208,62,62);stroke-width:4" />
      <line x1="580" x2="580" y1="218" y2="108" style="stroke:rgb(208,62,62);stroke-width:4" />
      <line x1="585" x2="585" y1="108" y2="63" style="stroke:rgb(208,62,62);stroke-width:4" />
      <line x1="620" x2="620" y1="63" y2="10" style="stroke:rgb(208,62,62);stroke-width:4" />
    </svg>
    """
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
