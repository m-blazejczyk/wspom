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

  defp build_socket_for_index(socket, filter, entries) do
    socket
    |> assign(:page_title, filter |> Filter.toTitle())
    |> assign(:entry, nil)
    |> assign(:filter, filter)
    |> stream(:entries, filter |> Filter.filter(entries), reset: true)
  end

  defp apply_action(socket, :index, %{"filter" => _which, "day" => _day, "month" => _month} = params) do
    # This is any subsequent page load - we have query params
    entries = Context.list_entries()
    filter = Filter.from_params(params, entries)
    socket
    |> build_socket_for_index(filter, entries)
  end
  defp apply_action(socket, :index, %{}) do
    # This is the initial load - no query parameters
    entries = Context.list_entries()
    filter = Filter.default()
    socket
    |> build_socket_for_index(filter, entries)
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
  def handle_event("delete", %{"id" => _id}, socket) do
    # entry = Context.get_entry!(id)
    # {:ok, _} = Context.delete_entry(entry)

    # {:noreply, stream_delete(socket, :entries, entry)}
    {:noreply, socket}
  end
end
