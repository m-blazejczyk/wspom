defmodule WspomWeb.EntryLive.Index do
  use WspomWeb, :live_view

  alias Wspom.Context
  alias Wspom.Entry
  alias Wspom.Filter

  @impl true
  def mount(_params, _session, socket) do
    filter = Filter.default()
    {:ok, socket
      |> assign(:filter, filter)
      |> assign(:entries, filter |> Filter.filter(Context.list_entries()))
      |> assign(:expanded, MapSet.new())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Entries")
    |> assign(:entry, nil)
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
  def handle_event("expand", %{"id" => id}, socket) do
    id_int = String.to_integer(id)
    {:noreply, socket
      |> assign(:expanded, socket.assigns.expanded |> MapSet.put(id_int))}
  end
  def handle_event("unexpand", %{"id" => id}, socket) do
    id_int = String.to_integer(id)
    {:noreply, socket
      |> assign(:expanded, socket.assigns.expanded |> MapSet.delete(id_int))}
  end
  def handle_event("prev", _, socket) do
    {new_filter, new_entries} = Filter.prev(
      socket.assigns.filter, Context.list_entries())
    {:noreply, socket
      |> assign(:filter, new_filter)
      |> assign(:entries, new_entries)}
  end
  def handle_event("next", _, socket) do
    {new_filter, new_entries} = Filter.next(
      socket.assigns.filter, Context.list_entries())
    {:noreply, socket
      |> assign(:filter, new_filter)
      |> assign(:entries, new_entries)}
  end
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
  def handle_event("edit", %{"id" => id}, socket) do
    id_int = String.to_integer(id)
    {:noreply, socket
      |> assign(:entry, socket.assigns.entries |> Enum.find(fn e -> e.id == id_int end))
      |> assign(:live_action, :edit)
      |> assign(:page_title, "Edit Entry")}
  end
  def handle_event("new", _, socket) do
    {:noreply, socket
      |> assign(:entry, %Entry{})
      |> assign(:live_action, :new)
      |> assign(:page_title, "New Entry")}
  end
end
