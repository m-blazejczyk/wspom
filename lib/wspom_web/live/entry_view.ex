defmodule WspomWeb.Live.EntryView do
  use WspomWeb, :live_view

  alias Wspom.Entry
  alias Wspom.Entries.Context
  alias Wspom.Entries.Filter

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket
      # Do not initialize the data here - it will happen in handle_params below
      |> stream(:entries, [])
      |> assign(:filter, nil)
      |> assign(:entry, nil)
      |> assign(:tags, nil)
      |> assign(:cascades, nil)
    }
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp build_socket_for_index(socket, filter, entries) do
    socket
    |> assign(:page_title, filter |> Filter.toTitle())
    |> assign(:filter, filter)
    |> stream(:entries, filter |> Filter.filter(entries), reset: true)
    |> assign(:entry, nil)
    |> assign(:tags, nil)
    |> assign(:cascades, nil)
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
    entry = Context.get_entry!(id) |> IO.inspect(label: "EDITING ENTRY")
    {tags, cascades} = Context.get_tags_and_cascades()

    socket
    |> assign(:page_title, "Edit Entry")
    |> assign(:entry, entry)
    # Normally, users only navigate to the Edit Entry page through the Index page;
    # When that happens, :filter is already set in the assigns when we get to the code here.
    # :filter is required in order to initialize the return URLs provided to the modal.
    # However, when by some chance, the initial page that the user navigates to is Edit
    # then there is no :filter in the assigns and the modal cannot be initialized properly.
    |> assign_if_not_exists(:filter, Filter.from_entry(entry))
    # We're passing tags and cascades "as is"; they will be converted to a more suitable
    # format later on - in form_component.ex.
    |> assign(:tags, tags)
    |> assign(:cascades, cascades)
  end

  defp apply_action(socket, :new, _params) do
    {tags, cascades} = Context.get_tags_and_cascades()
    socket
    |> assign(:page_title, "New Entry")
    |> assign(:entry, Entry.new())
    # See comment in the :edit variant of this function, above.
    |> assign_if_not_exists(:filter, Filter.default())
    # We're passing tags and cascades "as is"; they will be converted to a more suitable
    # format later on - in form_component.ex.
    |> assign(:tags, tags)
    |> assign(:cascades, cascades)
  end

  @impl true
  def handle_info({WspomWeb.Live.EntryEditForm, {:saved, entry}}, socket) do
    {:noreply, stream_insert(socket, :entries, entry)}
  end

  @impl true
  def handle_event("delete", %{"id" => _id}, socket) do
    # entry = Context.get_entry!(id)
    # {:ok, _} = Context.delete_entry(entry)

    # {:noreply, stream_delete(socket, :entries, entry)}
    {:noreply, socket}
  end
  def handle_event("clone", %{"id" => id}, socket) do
    {:ok, cloned_entry} = Context.get_entry!(id)
    |> Context.clone_entry()

    {:noreply,
    socket
    # TODO: insert in the right position
    |> stream_insert(:entries, cloned_entry, at: -1)
    |> put_flash(:info, "Entry cloned.")}
  end
  def handle_event("tag-next", _, socket) do
    entry = Context.get_next_entry_to_tag()
    {:noreply, push_patch(socket, to: ~p"/entries?filter=year&day=#{entry.day}&month=#{entry.month}&year=#{entry.year}")}
  end

  defp assign_if_not_exists(socket, key, value) do
    if socket.assigns |> Map.has_key?(key) and socket.assigns |> Map.get(key) != nil do
      socket
    else
      socket |> assign(key, value)
    end
  end
end
