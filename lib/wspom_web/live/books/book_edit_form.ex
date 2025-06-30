defmodule WspomWeb.Live.BookEditForm do
  use WspomWeb, :live_component

  alias Wspom.Books.Context

  @impl true
  def render(assigns) do
    # Note: this code can only use the assigns that have been explicitly passed
    # to the <.live_component> tag in the .html.heex file.
    # This code has no access to the assigns from the LiveView.
    ~H"""
    <div>
      <.simple_form
        for={@form}
        id="book-form"
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

        Hello Form!

      </.simple_form>
    </div>
    """
  end

  defp title_field(assigns) do
    ~H"""
    <.input field={@form[:title]} type="text" label="Title" />
    """
  end

  defp content_field(assigns) do
    ~H"""
    <.input field={@form[:description]} type="textarea"
      label="Description" />
    """
  end

  defp date_field(assigns) do
    ~H"""
    <div class="flex gap-2 ">
      <.input field={@form[:day]} type="number" label="Day" />
      <.input field={@form[:month]} type="number" label="Month" />
      <.input field={@form[:year]} type="number" label="Year" />
      <div>
        <label class="block text-sm font-semibold leading-6 text-zinc-800">
          Weekday
        </label>
        <div class="mt-2 block w-full rounded-lg text-zinc-900 sm:leading-6">
          <%= @weekday %>
        </div>
      </div>
    </div>
    """
  end

  defp additional_fields(assigns) do
    ~H"""
    <div class="flex flex-row gap-4">
      <.input field={@form[:fuzzy]} type="number" label="Fuzzy" />
      <div class="content-center justify-items-center grow">
        <.input field={@form[:needs_review]} type="checkbox" label="Needs review" />
      </div>
      <.input field={@form[:importance]} type="select" label="Importance"
        options={[{"Normal", "normal"},
          {"Important", "important"},
          {"Very important", "very_important"}]} />
    </div>
    """
  end

  @impl true
  def update(%{book: book} = assigns, socket) do
    changeset = Context.change_book(book)

    {:ok,
      socket
      |> assign(assigns)
      |> assign_new(:form, fn -> to_form(changeset) end)
    }
  end

  @impl true
  def handle_event("validate", %{"book" => params}, socket) do
    changeset = Context.change_book(socket.assigns.book, params)
    {:noreply, socket
      |> assign(form: to_form(changeset, action: :validate))
    }
  end

  def handle_event("save", %{"book" => params}, socket) do
    save_entry(socket, socket.assigns.action, params)
  end

  defp save_entry(socket, :edit, params) do
    # case Context.update_entry(socket.assigns.entry, params) do
    #   {:ok, entry, summary} ->
    #     notify_parent({:saved, entry})

    #     {:noreply,
    #      socket
    #      |> push_patch(to: socket.assigns.patch)}

    #   {:error, %Ecto.Changeset{} = changeset} ->
    #     {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
    # end
    {:noreply,
      socket
      |> push_patch(to: socket.assigns.patch)}
  end

  defp save_entry(socket, :new, params) do
    # case Context.create_entry(params) do
    #   {:ok, entry, summary} ->
    #     notify_parent({:saved, entry})

    #     {:noreply,
    #      socket
    #      |> push_patch(to: socket.assigns.patch)}

    #   {:error, %Ecto.Changeset{} = changeset} ->
    #     {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
    # end

    {:noreply,
      socket
      |> push_patch(to: socket.assigns.patch)}
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
