defmodule WspomWeb.Live.EntryEditForm do
  use WspomWeb, :live_component

  alias Wspom.Context

  # This is required in order for the form to load the initial value of the tags from Entry.
  defimpl Phoenix.HTML.Safe, for: MapSet do
    def to_iodata(set), do: Wspom.Entry.tags_to_string(set)
  end

  @impl true
  def render(assigns) do
    # Note: this code can only use the assigns that have been explicitly passed
    # to the <.live_component> tag in index.html.heex. This code has no access
    # to the assigns from the LiveView.
    ~H"""
    <div>
      <.simple_form
        for={@form}
        id="entry-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.header>
          <%= @title %>
          <:actions>
            <.button phx-disable-with="Saving…">Save</.button>
          </:actions>
        </.header>

        <.input field={@form[:title]} type="text" label="Title" />
        <div class="flex gap-2 ">
          <div class="flex-auto">
            <.input field={@form[:tags]} type="text" label="Tags"/>
          </div>
          <.button type="button" class="flex-none" phx-click={JS.toggle(to: "#all-tags")}>
            T
          </.button>
          <.button type="button" class="flex-none" phx-click={JS.toggle(to: "#all-cascades")}>
            C
          </.button>
        </div>
        <div class="flex gap-2">
          <.input field={@form[:fuzzy]} type="number" label="Fuzzy" />
          <div class="content-center">
            <.input field={@form[:needs_review]} type="checkbox" label="Needs review" />
          </div>
        </div>
        <.input field={@form[:description]} type="textarea"
          rows={scale_description_box(@form[:description])} label="Description" />
        <div class="flex gap-2 ">
          <.input field={@form[:year]} type="number" label="Year" />
          <.input field={@form[:month]} type="number" label="Month" />
          <.input field={@form[:day]} type="number" label="Day" />
        </div>
        <div id="all-tags" class="hidden">
          <h1 class="text-lg font-semibold leading-8 text-zinc-800" phx-click={JS.toggle(to: "#all-tags")}>
            Tags
          </h1>
          <div class="flex flex-wrap">
            <%= for tag <- prepare_tags(@tags) do %>
              <.link patch={Wspom.Filter.switch_to_tag_link(@filter, @entry.year, tag)}>
                <div class="mx-5 my-2 w-20 text-gray-500"><%= tag %></div>
              </.link>
            <% end %>
          </div>
        </div>
        <div id="all-cascades" class="hidden">
          <h1 class="text-lg font-semibold leading-8 text-zinc-800" phx-click={JS.toggle(to: "#all-cascades")}>
            Cascades
          </h1>
          <div class="flex flex-wrap">
            <%= for {name, tags} <- prepare_cascades(@cascades) do %>
              <div class="mx-5 my-2 text-gray-500">
                <b>
                  <.link patch={Wspom.Filter.switch_to_tag_link(@filter, @entry.year, name)}>
                    <%= name %>
                  </.link>
                </b>
                <%= for tag <- tags do %>
                  +
                  <.link patch={Wspom.Filter.switch_to_tag_link(@filter, @entry.year, tag)}>
                    <%= tag %>
                  </.link>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>
      </.simple_form>
    </div>
    """
  end

  defp prepare_tags(raw_tags) do
    # I checked - render() is only called once, not on every change to the form.
    # So it should be safe to only process the tags and cascades here, as opposed
    # to someplace more upstream. (I want to avoid this code getting called more
    # than once).
    raw_tags |> MapSet.to_list() |> Enum.sort()
  end

  defp prepare_cascades(%{} = raw_cascades) do
    raw_cascades
    |> Enum.map(fn {name, tags} ->
      {name, tags |> MapSet.delete(name) |> MapSet.to_list()} end)
    # "The given function should compare two arguments, and return true if the
    # first argument precedes or is in the same place as the second one".
    |> Enum.sort(fn {name1, _}, {name2, _} -> name1 < name2 end)
  end

  defp scale_description_box(description) do
    Enum.max([5, (description.value |> String.length()) / 80])
  end

  @impl true
  def update(%{entry: entry} = assigns, socket) do
    changeset = Context.change_entry(entry)

    {:ok,
      socket
      |> assign(assigns)
      |> assign_new(:form, fn -> to_form(changeset) end)}
  end

  @impl true
  def handle_event("validate", %{"entry" => entry_params}, socket) do
    changeset = Context.change_entry(socket.assigns.entry, entry_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"entry" => entry_params}, socket) do
    save_entry(socket, socket.assigns.action, entry_params)
  end

  defp save_entry(socket, :edit, entry_params) do
    case Context.update_entry(socket.assigns.entry, entry_params) do
      {:ok, entry, summary} ->
        notify_parent({:saved, entry})

        {:noreply,
         socket
         |> put_flash(:info, break_lines("Entry updated successfully!\n" <> summary))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
    end
  end

  defp save_entry(socket, :new, entry_params) do
    case Context.create_entry(entry_params) do
      {:ok, entry, summary} ->
        notify_parent({:saved, entry})

        {:noreply,
         socket
         |> put_flash(:info, break_lines("Entry created successfully!\n" <> summary))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def break_lines(str) do
    assigns = %{str: str}
    ~H"""
    <%= for line <- @str |> String.split("\n") do %>
      <br><%= line %>
    <% end %>
    """
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
