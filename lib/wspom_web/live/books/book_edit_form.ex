defmodule WspomWeb.Live.BookEditForm do
  use WspomWeb, :live_component

  alias Wspom.Books.Context

  # This is required in order for the form to load the initial value
  # of length from Book.
  defimpl Phoenix.HTML.Safe, for: Wspom.BookPos do
    def to_iodata(pos), do: Wspom.BookPos.to_string(pos)
  end

  @impl true
  def render(assigns) do
    # Note: this code can only use the assigns that have been explicitly passed
    # to the <.live_component> tag in the .html.heex file.
    # This code has no access to the assigns from the parent LiveView.
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

        <.input field={@form[:title]} type="text" label="Title" />
        <.input field={@form[:short_title]} type="text" label="Short title" />
        <.input field={@form[:author]} type="text" label="Author" />
        <.input field={@form[:length]} type="text" label="Length (pages, % or hh:mm)" disabled={@book.status != :active}/>
        <.input field={@form[:medium]} type="select" label="Medium"
          options={[{"Printed book", "book"},
            {"Audiobook", "audiobook"},
            {"E-book", "ebook"},
            {"Comics / Graphic novel", "comics"}]} />
        <.input field={@form[:is_fiction]} type="checkbox" label="Fiction?" />

      </.simple_form>
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
    save_book(socket, socket.assigns.action, params)
  end

  defp save_book(socket, :edit, params) do
    case Context.update_book(socket.assigns.book, params) do
      {:ok, book} ->
        notify_parent({:saved, book})

        {:noreply,
         socket
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
    end
  end

  defp save_book(socket, :add, params) do
    case Context.create_book(params) do
      {:ok, book} ->
        notify_parent({:saved, book})

        {:noreply,
         socket
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
