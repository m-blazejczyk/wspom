defmodule WspomWeb.Live.BookHistoryEditForm do
  use WspomWeb, :live_component

  alias Wspom.Books.Context

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-lg mx-auto border border-gray-200 rounded shadow-md px-8 py-10 flex flex-col items-center">
      <div class="flex justify-center items-center w-full">
        <section class="min-w-md">
          <ul class="grid grid-cols-3 gap-6">
            <WspomWeb.CardComponent.small_card href={~p"/"} img={~p"/images/home_64.png"}
              label="Go back to the home page" />
            <WspomWeb.CardComponent.small_card href={~p"/weight/data"} img={~p"/images/table_64.png"}
              label="View all weight data" />
            <WspomWeb.CardComponent.small_card href={~p"/weight/charts"} img={~p"/images/chart_64.png"}
              label="View weight charts" />
          </ul>
        </section>
      </div>
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

        <.input field={@form[:position]} type="text" class="text-xl text-center"
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

        <div class="grid grid-cols-1 gap-2">
          <div>
            <.input field={@form[:date]} type="text" class="text-xl text-center"
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
  def handle_event("validate", %{"history" => params}, socket) do
    changeset = Context.change_book_history(socket.assigns.book, params)
    {:noreply, socket
      |> assign(form: to_form(changeset, action: :validate))
    }
  end

  def handle_event("save", %{"history" => _params}, _socket) do
    # save_history(socket, socket.assigns.action, params)
    nil
  end

  # defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
