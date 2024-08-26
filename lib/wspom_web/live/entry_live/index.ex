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
      |> assign(:entries, filter |> Filter.filter(Context.list_entries()))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
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
end
