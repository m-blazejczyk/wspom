defmodule WspomWeb.EntryLive.Index do
  use WspomWeb, :live_view

  alias Wspom.Context
  alias Wspom.Entry
  alias Wspom.Filter

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket
      # Do not initialize the data here - it will happen in handle_params below
      |> stream(:entries, [])
      |> assign(:filter, nil)
    }
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp build_socket_for_index(socket, filter) do
    socket
    |> assign(:page_title, filter |> Filter.toTitle())
    |> assign(:entry, nil)
    |> assign(:filter, filter)
    |> stream(:entries, filter |> Filter.filter(Context.list_entries()), reset: true)
  end

  defp apply_action(socket, :index, %{"filter" => _which, "day" => _day, "month" => _month} = params) do
    # This is any subsequent page load - we have query params
    filter = Filter.from_params(params)
    socket
    |> build_socket_for_index(filter)
  end
  defp apply_action(socket, :index, %{}) do
    # This is the initial load - no query parameters
    filter = Filter.default()
    socket
    |> build_socket_for_index(filter)
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Entry")
    |> assign(:entry, Context.get_entry!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Entry")
    |> assign(:entry, %Entry{})
  end

  @impl true
  def handle_info({WspomWeb.EntryLive.FormComponent, {:saved, entry}}, socket) do
    {:noreply, stream_insert(socket, :entries, entry)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    entry = Context.get_entry!(id)
    {:ok, _} = Context.delete_entry(entry)

    {:noreply, stream_delete(socket, :entries, entry)}
  end
  # def handle_event("prev", _, socket) do
  #   {new_filter, new_entries} = Filter.prev(
  #     socket.assigns.filter, Context.list_entries())
  #   {:noreply, socket
  #     |> assign(:filter, new_filter)
  #     |> assign(:entries, new_entries)}
  # end
  # def handle_event("next", _, socket) do
  #   {new_filter, new_entries} = Filter.next(
  #     socket.assigns.filter, Context.list_entries())
  #   {:noreply, socket
  #     |> assign(:filter, new_filter)
  #     |> assign(:entries, new_entries)}
  # end
  def handle_event("filter-year", %{"year" => year}, socket) do
    {new_filter, new_entries} = Filter.to_year(
      socket.assigns.filter, String.to_integer(year), Context.list_entries())
    {:noreply, socket
      |> assign(:filter, new_filter)
      |> assign(:entries, new_entries)}
  end
  def handle_event("filter-day", _, socket) do
    {new_filter, new_entries} = Filter.to_day(
      socket.assigns.filter, Context.list_entries())
    {:noreply, socket
      |> assign(:filter, new_filter)
      |> assign(:entries, new_entries)}
  end
  # def handle_event("edit", %{"id" => id}, socket) do
  #   id_int = String.to_integer(id)
  #   {:noreply, socket
  #     |> assign(:entry, socket.assigns.entries |> Enum.find(fn e -> e.id == id_int end))
  #     |> assign(:live_action, :edit)
  #     |> assign(:page_title, "Edit Entry")}
  # end
  # def handle_event("new", _, socket) do
  #   {:noreply, socket
  #     |> assign(:entry, %Entry{})
  #     |> assign(:live_action, :new)
  #     |> assign(:page_title, "New Entry")}
  # end
end
