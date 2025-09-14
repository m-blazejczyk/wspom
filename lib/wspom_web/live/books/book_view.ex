defmodule WspomWeb.Live.Books.BookView do
  use WspomWeb, :live_view

  alias Wspom.{BookPos, Book}
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

  defp make_chart(assigns, width, ylabels?) do
    chartx = if ylabels?, do: 50, else: 10
    {yticks, segments} = Wspom.ReadingChart.Data.make_from_book(
      assigns.book, chartx, 10, width - chartx - 10, 380)
    assigns = assigns
    |> assign(:yticks, yticks)
    |> assign(:segments, segments)
    |> assign(:width, width)
    |> assign(:chartx, chartx)
    |> assign(:ylabels?, ylabels?)

    ~H"""
    <svg width={@width} height="435" xmlns="http://www.w3.org/2000/svg">
      <rect x={@chartx} y="10" width={@width - @chartx - 10} height="380" style="fill:rgba(255, 255, 255, 0);stroke-width:1;stroke:gray"/>

      <!-- Top of the box: length of the book -->
      <%= if @ylabels? do %>
        <line x1={@chartx - 8} x2={@chartx} y1="10" y2="10" style="stroke:grey;stroke-width:1" />
        <text x={@chartx - 12} y="15" fill="gray" font-size="16" text-anchor="end">
          <%= BookPos.to_string(@book.length) %>
        </text>
      <% end %>

      <!-- Y ticks -->
      <%= for tick <- @yticks do %>
        <line x1={@chartx - 8} x2={@chartx} y1={tick.pos} y2={tick.pos} style="stroke:grey;stroke-width:1" />
        <line x1={@chartx} x2={@width - 10} y1={tick.pos} y2={tick.pos} style="stroke:rgb(220,220,220);stroke-width:1" />
        <%= if @ylabels? do %>
          <text x={@chartx - 12} y={tick.pos + 5} fill="gray" font-size="16" text-anchor="end">
            <%= tick.text %>
          </text>
        <% end %>
      <% end %>

      <!-- Bottom of the box: start of the book -->
      <%= if @ylabels? do %>
        <line x1={@chartx - 8} x2={@chartx} y1="390" y2="390" style="stroke:grey;stroke-width:1" />
        <text x={@chartx - 12} y="395" fill="gray" font-size="16" text-anchor="end">
          <%= BookPos.zero_to_string(@book.length) %>
        </text>
      <% end %>

      <%= for {tick, markers} <- @segments do %>
        <!-- X ticks -->
        <line x1={tick.pos} x2={tick.pos} y1="390" y2="400" style="stroke:grey;stroke-width:1" />
        <line x1={tick.pos} x2={tick.pos} y1="10" y2="390" style="stroke:rgb(220,220,220);stroke-width:1" />

        <!-- X tick labels -->
        <%= if tick.text_up do %>
          <text x={tick.pos + 4} y="406" fill="gray" font-size="16" text-anchor="start">
            <%= tick.text_up %>
          </text>
        <% end %>
        <%= if tick.text_down do %>
          <text x={tick.pos + 4} y="425" fill="gray" font-size="16" text-anchor="start">
            <%= tick.text_down %>
          </text>
        <% end %>

        <%= if length(markers) == 0 do %>
          <!-- Empty segment -->
          <rect x={tick.pos} y="10" width="15" height="380" style="fill:rgb(220,220,220);stroke-width:1;stroke:gray"/>
        <% else %>
          <!-- Non-empty segment -->
          <%= for marker <- markers do %>
            <%= case marker.type do %>
              <% :read -> %>
                <line x1={marker.x} x2={marker.x} y1={marker.y_from} y2={marker.y_to}
                  style="stroke:rgb(208,62,62);stroke-width:4" />
              <% :updated -> %>
                <line x1={marker.x} x2={marker.x} y1={marker.y_from} y2={marker.y_to}
                  style="stroke:rgb(242, 178, 178);stroke-width:4" />
              <% :skipped -> %>
                <line x1={marker.x} x2={marker.x} y1={marker.y_from} y2={marker.y_to}
                  style="stroke:rgb(50,50,50);stroke-width:4" />
            <% end %>
          <% end %>
        <% end %>
      <% end %>
    </svg>
    """
  end

  # - :read - :position should contain the current position in the book
  # - :updated - same as above but this one is used to bulk-advance the
  #   current reading position in situations when detailed reading history
  #   is not available; in other words, the pages were read but not
  #   on the date indicated but over time
  # - :skipped - same as above but to advance the current reading position
  #   to indicate pages that were not read, i.e. that were skipped

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
