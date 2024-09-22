defmodule WspomWeb.EntryLive.FormComponent do
  use WspomWeb, :live_component

  alias Wspom.Context

  # This is required in order for the form to load the initial value of the tags from Entry.
  defimpl Phoenix.HTML.Safe, for: MapSet do
    def to_iodata(set), do: Wspom.Entry.tags_to_string(set)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
      </.header>

      <.simple_form
        for={@form}
        id="entry-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:title]} type="text" label="Title" />
        <.input field={@form[:tags]} type="text" label="Tags" />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <.input field={@form[:year]} type="number" label="Year" />
        <.input field={@form[:month]} type="number" label="Month" />
        <.input field={@form[:day]} type="number" label="Day" />
        <.input field={@form[:fuzzy]} type="number" label="Fuzzy" />
        <.input field={@form[:needs_review]} type="checkbox" label="Needs review" />
        <:actions>
          <.button phx-disable-with="Saving…">Save</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{entry: entry} = assigns, socket) do
    changeset = Context.change_entry(entry)

    {:ok,
      socket
      |> assign(assigns)
      |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"entry" => entry_params}, socket) do
    changeset =
      socket.assigns.entry
      |> Context.change_entry(entry_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"entry" => entry_params}, socket) do
    save_entry(socket, socket.assigns.action, entry_params)
  end

  defp save_entry(socket, :edit, entry_params) do
    case Context.update_entry(socket.assigns.entry, entry_params) do
      {:ok, entry} ->
        notify_parent({:saved, entry})

        {:noreply,
         socket
         |> put_flash(:info, "Entry updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_entry(socket, :new, entry_params) do
    case Context.create_entry(entry_params) do
      {:ok, entry} ->
        notify_parent({:saved, entry})

        {:noreply,
         socket
         |> put_flash(:info, "Entry created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
