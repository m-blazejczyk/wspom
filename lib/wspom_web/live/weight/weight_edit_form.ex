defmodule WspomWeb.Live.WeightEditForm do
  use WspomWeb, :live_component

  alias Wspom.Weight.Context

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-lg mx-auto border border-gray-200 rounded shadow-md px-8 py-10 flex flex-col items-center">
      <.simple_form
        for={@form}
        id="weight-form"
        class="w-full flex flex-col gap-4"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.header>
          <%= @title %>
        </.header>

        <.input field={@form[:weight]} type="text" class="text-xl text-center"
          class_container="flex items-start flex-col justify-start"
          formatter={&weight_formatter/2} autocomplete="off"/>

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
              phx-click={JS.push("append", value: %{text: "."})} phx-target={@myself}>
              •
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
              class_container="flex items-start flex-col justify-start"
              autocomplete="off"/>
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
          <.button phx-disable-with="Saving…" class="w-full">Save ME!</.button>
        </:actions>

      </.simple_form>
    </div>
    """
  end

  # We need a custom formatter because otherwise, entering "8" using
  # the buttons will display "8.0" (but, magically, adding more digits
  # using the buttons will work just fine).
  defp weight_formatter(_type, nil) do
    ""
  end
  defp weight_formatter(_type, value) when is_binary(value) do
    value
  end
  defp weight_formatter(_type, value) when is_float(value) do
    value_int = Float.round(value)
    if value_int == value, do: round(value_int), else: Float.to_string(value)
  end

  @impl true
  def update(%{data: data} = assigns, socket) do
    # Note: all calls to `to_form()` in this module require the `as: "data"` argument.
    # That's because we're not using a struct to back the form data.
    {:ok,
      socket
      |> assign(assigns)
      |> assign_new(:form, fn -> to_form(Context.to_changeset(data), as: "data") end)}
  end

  @impl true
  def handle_event("validate", %{"data" => form_params}, socket) do
    handle_form_change(socket, form_params)
  end
  def handle_event("save", %{"data" => form_params}, socket) do
    save_record(socket, socket.assigns.action, form_params)
  end
  def handle_event("day_earlier", _, socket) do
    add_days_to_date(socket, -1)
  end
  def handle_event("day_later", _, socket) do
    add_days_to_date(socket, 1)
  end
  def handle_event("append", %{"text" => text}, socket) do
    raw = get_form_param(socket, "weight")
    new_weight = raw <> text
    handle_form_change(socket, Utils.set_form_param(socket, "weight", new_weight))
  end
  def handle_event("delete", _, socket) do
    current_text = get_form_param(socket, "weight")
    new_weight = current_text |> String.slice(0, String.length(current_text) - 1)
    handle_form_change(socket, Utils.set_form_param(socket, "weight", new_weight))
  end

  defp add_days_to_date(socket, days) do
    current_date = get_form_param(socket, "date")
    if is_binary(current_date) do
      # This will get called if the < or > button is clicked while the
      # content of the date field is invalid
      handle_form_change(socket, socket.assigns.form.params)
    else
      # This will get called if the date field contains a valid date
      new_date = current_date |> Date.add(days)
      handle_form_change(socket, Utils.set_form_param(socket, "date", new_date))
    end
  end

  defp handle_form_change(socket, form_params) do
    changeset = Context.to_changeset(socket.assigns.data, form_params)
    form = to_form(changeset, action: :validate, as: "data")
    {:noreply, socket |> assign(form: form)}
  end

  # This function will grab the current value of the given form field;
  # if `params` don't contain it yet (as it will happen if the field wasn't yet
  # modified by the user), we grab the value from `data`, i.e. the initial record.
  def get_form_param(socket, field) do
    Map.get(socket.assigns.form.params, field)
      || Map.get(socket.assigns.form.data, String.to_existing_atom(field))
      || ""
  end

  defp save_record(socket, :edit, form_params) do
    case Context.update_record(socket.assigns.data, form_params) do
      {:ok, data} ->
        notify_parent({:saved, data})

        {:noreply,
         socket
         |> put_flash(:info, "Weight updated successfully!")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, action: :validate, as: "data"))}
    end
  end
  defp save_record(socket, :add, form_params) do
    case Context.create_record(form_params) do
      {:ok, data} ->
        notify_parent({:saved, data})

        {:noreply,
         socket
         |> put_flash(:info, "Weight entered successfully!")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, action: :validate, as: "data"))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
