defmodule WspomWeb.Live.BookHistoryEditForm do
alias Wspom.BookLen
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
  def update(%{history: history, book: book} = assigns, socket) do
    changeset = Context.change_book_history(history, book)

    {:ok,
      socket
      |> assign(assigns)
      |> assign_new(:form, fn -> to_form(changeset) end)
    }
  end

  @impl true
  def handle_event("validate", %{"book_history" => params}, socket) do
    handle_form_change(socket, params)
  end
  def handle_event("save", %{"book_history" => params}, socket) do
    save_history(socket, socket.assigns.action, params)
  end
  def handle_event("day_earlier", _, socket) do
    add_days_to_date(socket, -1)
  end
  def handle_event("day_later", _, socket) do
    add_days_to_date(socket, 1)
  end
  def handle_event("append", %{"text" => text}, socket) do
    new_position = get_position_from_form(socket) <> text
    handle_form_change(socket, Utils.set_form_param(socket, "position", new_position))
  end
  def handle_event("delete", _, socket) do
    current_text = get_position_from_form(socket)
    new_position = current_text |> String.slice(0, String.length(current_text) - 1)
    handle_form_change(socket, Utils.set_form_param(socket, "position", new_position))
  end

  defp add_days_to_date(socket, days) do
    current_text = get_date_from_form(socket)
    new_date = with {:ok, date} <- Date.from_iso8601(current_text) do
      date |> Date.add(days) |> to_string()
    else
      _ -> current_text
    end
    handle_form_change(socket, Utils.set_form_param(socket, "date", new_date))
  end

  defp handle_form_change(socket, params) do
    changeset = Context.change_book_history(
      socket.assigns.history, socket.assigns.book, params)
    {:noreply, socket
      |> assign(form: to_form(changeset, action: :validate))
    }
  end

  # This function will grab the current value of the `date` field;
  # if `params` don't contain it yet (as it will happen if the field wasn't yet
  # modified by the user), we grab the value from `data`, i.e. the initial record,
  # and convert it to a string.
  defp get_date_from_form(socket) do
    Map.get(socket.assigns.form.params, "date")
      || Date.to_string(Map.get(socket.assigns.form.data, :date))
  end

  # Same as above but for the `position` field.
  defp get_position_from_form(socket) do
    Map.get(socket.assigns.form.params, "position")
      || BookLen.to_string(Map.get(socket.assigns.form.data, :position))
  end

  defp save_history(socket, :history, params) do
    case Context.update_book_history(
      socket.assigns.history, socket.assigns.book, params) do
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
    case Context.create_book_history(socket.assigns.book, params) do
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
