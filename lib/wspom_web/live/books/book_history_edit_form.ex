defmodule WspomWeb.Live.BookHistoryEditForm do
  use WspomWeb, :live_component

  alias Wspom.Books.Context

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-lg mx-auto border border-gray-200 rounded shadow-md px-8 py-10 flex flex-col items-center">
      <.simple_form
        for={@form}
        id="book-history-form"
        class="w-full flex flex-col gap-4"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.header>
          <%= @title %>
        </.header>

        <.input :if={@book == nil}
          field={@form[:book_id]} type="text" label="Book (list)"
          class="text-xl text-center"
          class_container="flex items-start flex-col justify-start"/>

        <.input :if={@book != nil}
          field={@form[:book_id]} type="text" label="Book"
          value={@book.title}
          disabled
          class="text-xl text-center"
          class_text="text-zinc-500"
          class_container="flex items-start flex-col justify-start"/>

        <div class="grid grid-cols-1 gap-2">
          <div>
            <.input field={@form[:date]} type="text" label="Date"
              class="text-xl text-center"
              class_container="flex items-start flex-col justify-start"/>
          </div>
          <div>
            <.button type="button" class="float-left w-16" phx-click={JS.push("day_earlier")} phx-target={@myself}>
              &lt;
            </.button>
            <.button type="button" class="float-right w-16" phx-click={JS.push("day_later")} phx-target={@myself}>
              &gt;
            </.button>
          </div>
        </div>

        <.input field={@form[:position]} type="text" label="Position"
          class="text-xl text-center"
          class_container="flex items-start flex-col justify-start"/>

        <div class="flex flex-wrap rounded-lg bg-gray-300 max-w-sm mx-auto mt-24">
          <div class="w-1/3">
            <button type="button" class="w-full h-16 text-xl text-gray-700 rounded-lg hover:bg-gray-400"
              phx-click={JS.push("append", value: %{text: "1"})} phx-target={@myself}>
              1
            </button>
          </div>
          <div class="w-1/3">
            <button type="button" class="w-full h-16 text-xl text-gray-700 rounded-lg hover:bg-gray-400"
              phx-click={JS.push("append", value: %{text: "2"})} phx-target={@myself}>
              2
            </button>
          </div>
          <div class="w-1/3">
            <button type="button" class="w-full h-16 text-xl text-gray-700 rounded-lg hover:bg-gray-400"
              phx-click={JS.push("append", value: %{text: "3"})} phx-target={@myself}>
              3
            </button>
          </div>
          <div class="w-1/3">
            <button type="button" class="w-full h-16 text-xl text-gray-700 rounded-lg hover:bg-gray-400"
              phx-click={JS.push("append", value: %{text: "4"})} phx-target={@myself}>
              4
            </button>
          </div>
          <div class="w-1/3">
            <button type="button" class="w-full h-16 text-xl text-gray-700 rounded-lg hover:bg-gray-400"
              phx-click={JS.push("append", value: %{text: "5"})} phx-target={@myself}>
              5
            </button>
          </div>
          <div class="w-1/3">
            <button type="button" class="w-full h-16 text-xl text-gray-700 rounded-lg hover:bg-gray-400"
              phx-click={JS.push("append", value: %{text: "6"})} phx-target={@myself}>
              6
            </button>
          </div>
          <div class="w-1/3">
            <button type="button" class="w-full h-16 text-xl text-gray-700 rounded-lg hover:bg-gray-400"
              phx-click={JS.push("append", value: %{text: "7"})} phx-target={@myself}>
              7
            </button>
          </div>
          <div class="w-1/3">
            <button type="button" class="w-full h-16 text-xl text-gray-700 rounded-lg hover:bg-gray-400"
              phx-click={JS.push("append", value: %{text: "8"})} phx-target={@myself}>
              8
            </button>
          </div>
          <div class="w-1/3">
            <button type="button" class="w-full h-16 text-xl text-gray-700 rounded-lg hover:bg-gray-400"
              phx-click={JS.push("append", value: %{text: "9"})} phx-target={@myself}>
              9
            </button>
          </div>
          <div class="w-1/3">
            <button type="button" class="w-full h-16 text-xl text-gray-700 rounded-lg hover:bg-gray-400"
              phx-click={JS.push("append", value: %{text: ":"})} phx-target={@myself}>
              :
            </button>
          </div>
          <div class="w-1/3">
            <button type="button" class="w-full h-16 text-xl text-gray-700 rounded-lg hover:bg-gray-400"
              phx-click={JS.push("append", value: %{text: "0"})} phx-target={@myself}>
              0
            </button>
          </div>
          <div class="w-1/3">
            <button type="button" class="w-full h-16 text-xl text-gray-700 rounded-lg hover:bg-gray-400"
              phx-click={JS.push("delete")} phx-target={@myself}>
              ⌫
            </button>
          </div>
        </div>

        <.input field={@form[:type]} type="select" label="Type"
          options={[{"Daily read", "read"},
            {"Bulk update", "updated"},
            {"Skipped to position", "skipped"}]} />

        <:actions>
          <.button phx-disable-with="Saving…" class="w-full">Save</.button>
        </:actions>

      </.simple_form>
    </div>
    """
  end


  @impl true
  def update(%{history: history} = assigns, socket) do
    changeset = Context.change_book_history(history)

    {:ok,
      socket
      |> assign(assigns)
      |> assign_new(:form, fn -> to_form(changeset) end)
    }
  end

  @impl true
  def handle_event("validate", %{"book_history" => params}, socket) do
    IO.inspect(params, label: "PARAMS in VALIDATE")
    changeset = Context.change_book_history(socket.assigns.history, params)
    {:noreply, socket
      |> assign(form: to_form(changeset, action: :validate))
    }
  end

  def handle_event("save", %{"book_history" => params}, socket) do
    save_history(socket, socket.assigns.action, params)
  end

  defp save_history(socket, :history, params) do
    case Context.update_book_history(socket.assigns.history, params) do
      {:ok, history} ->
        notify_parent({:saved, history})

        {:noreply,
         socket
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
    end
  end

  defp save_history(socket, :read, params) do
    case Context.create_book_history(params) do
      {:ok, history} ->
        notify_parent({:saved, history})

        {:noreply,
         socket
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
