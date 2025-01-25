defmodule WspomWeb.Live.WeightEditForm do
  use WspomWeb, :live_component

  alias Wspom.Weight.Context

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-lg mx-auto border border-gray-200 rounded shadow-md px-8 py-10 flex flex-col items-center">
      <div class="flex justify-center items-center w-full">
        <section class="min-w-md p-4">
          <ul class="grid grid-cols-2 gap-6">
            <WspomWeb.CardComponent.small_card href={~p"/weight/data"} img={~p"/images/table_64.png"}
              label="View all weight data" />
            <WspomWeb.CardComponent.small_card href={~p"/weight/charts"} img={~p"/images/chart_64.png"}
              label="View weight charts" />
          </ul>
        </section>
      </div>
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

        <div class="flex gap-2 ">
          <.button type="button" class="flex-none w-20" phx-click={JS.push("day_earlier")} phx-target={@myself}>
            &lt;
          </.button>
          <div class="flex-auto">
            <.input field={@form[:date]} type="text" class="text-xl text-center"
              class_container="flex items-start flex-col justify-start"/>
          </div>
          <.button type="button" class="flex-none w-20" phx-click={JS.push("day_later")} phx-target={@myself}>
            &gt;
          </.button>
        </div>

        <.input field={@form[:weight]} type="text" class="text-xl text-center"
          class_container="flex items-start flex-col justify-start"/>

        <div class="flex flex-wrap rounded-lg bg-gray-300 max-w-sm mx-auto mt-24">
          <div class="w-1/3">
            <button type="button" class="w-full h-20 text-xl text-gray-700 rounded-lg hover:bg-gray-400"
              phx-click={JS.push("append", value: %{text: "1"})} phx-target={@myself}>
              1
            </button>
          </div>
          <div class="w-1/3">
            <button type="button" class="w-full h-20 text-xl text-gray-700 rounded-lg hover:bg-gray-400"
              phx-click={JS.push("append", value: %{text: "2"})} phx-target={@myself}>
              2
            </button>
          </div>
          <div class="w-1/3">
            <button type="button" class="w-full h-20 text-xl text-gray-700 rounded-lg hover:bg-gray-400"
              phx-click={JS.push("append", value: %{text: "3"})} phx-target={@myself}>
              3
            </button>
          </div>
          <div class="w-1/3">
            <button type="button" class="w-full h-20 text-xl text-gray-700 rounded-lg hover:bg-gray-400"
              phx-click={JS.push("append", value: %{text: "4"})} phx-target={@myself}>
              4
            </button>
          </div>
          <div class="w-1/3">
            <button type="button" class="w-full h-20 text-xl text-gray-700 rounded-lg hover:bg-gray-400"
              phx-click={JS.push("append", value: %{text: "5"})} phx-target={@myself}>
              5
            </button>
          </div>
          <div class="w-1/3">
            <button type="button" class="w-full h-20 text-xl text-gray-700 rounded-lg hover:bg-gray-400"
              phx-click={JS.push("append", value: %{text: "6"})} phx-target={@myself}>
              6
            </button>
          </div>
          <div class="w-1/3">
            <button type="button" class="w-full h-20 text-xl text-gray-700 rounded-lg hover:bg-gray-400"
              phx-click={JS.push("append", value: %{text: "7"})} phx-target={@myself}>
              7
            </button>
          </div>
          <div class="w-1/3">
            <button type="button" class="w-full h-20 text-xl text-gray-700 rounded-lg hover:bg-gray-400"
              phx-click={JS.push("append", value: %{text: "8"})} phx-target={@myself}>
              8
            </button>
          </div>
          <div class="w-1/3">
            <button type="button" class="w-full h-20 text-xl text-gray-700 rounded-lg hover:bg-gray-400"
              phx-click={JS.push("append", value: %{text: "9"})} phx-target={@myself}>
              9
            </button>
          </div>
          <div class="w-1/3">
            <button type="button" class="w-full h-20 text-xl text-gray-700 rounded-lg hover:bg-gray-400"
              phx-click={JS.push("append", value: %{text: "."})} phx-target={@myself}>
              •
            </button>
          </div>
          <div class="w-1/3">
            <button type="button" class="w-full h-20 text-xl text-gray-700 rounded-lg hover:bg-gray-400"
              phx-click={JS.push("append", value: %{text: "0"})} phx-target={@myself}>
              0
            </button>
          </div>
          <div class="w-1/3">
            <button type="button" class="w-full h-20 text-xl text-gray-700 rounded-lg hover:bg-gray-400"
              phx-click={JS.push("delete")} phx-target={@myself}>
              ⌫
            </button>
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
  def update(%{data: nil} = assigns, socket) do
    # This variant is called when the "Add Weight" form is initialized…
    # …and we simply call the other variant.
    default_data = Context.new_form_data()
    update(assigns |> Map.replace(:data, default_data), socket)
  end
  def update(%{data: data} = assigns, socket) do
    # This variant is called in all other contexts.
    # It expects a properly formed `:data` attribute in `assigns`.
    # For this reason, all calls to `to_form()` in this module require the `as: "data"` argument.
    # That's because we're not using a struct to back the form data.
    {:ok,
      socket
      |> assign(assigns)
      |> assign_new(:form, fn -> to_form(Context.to_changeset(data), as: "data") end)}
  end

  @impl true
  def handle_event("validate", %{"data" => form_params}, socket) do
    {:noreply, socket |> apply_form_params(form_params)}
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
    new_weight = get_param(socket.assigns.form, "weight") <> text
    new_params = %{"date" => get_param(socket.assigns.form, "date"), "weight" => new_weight}
    {:noreply, socket |> apply_form_params(new_params)}
  end
  def handle_event("delete", _, socket) do
    current_text = get_param(socket.assigns.form, "weight")
    new_weight = current_text |> String.slice(0, String.length(current_text) - 1)
    new_params = %{"date" => get_param(socket.assigns.form, "date"), "weight" => new_weight}
    {:noreply, socket |> apply_form_params(new_params)}
  end

  defp apply_form_params(socket, form_params) do
    changeset = Context.to_changeset(socket.assigns.data, form_params)
    form = to_form(changeset, action: :validate, as: "data")
    socket |> assign(form: form)
  end

  defp add_days_to_date(socket, days) do
    modify_field(socket, "date", fn current_date ->
      with {:ok, date} <- Date.from_iso8601(current_date) do
        date |> Date.add(days) |> to_string()
      else
        _ -> current_date
      end
    end)
  end

  defp modify_field(socket, field, fun) do
    old_value = Map.get(socket.assigns.form.params, field)
      || Map.get(socket.assigns.form.data, String.to_existing_atom(field))
    new_value = fun.(old_value)

    # I am not sure if this is the idiomatic way of handling this…
    # But based on what I found on the internet and tried out myself,
    # this is the most effective way of making dynamic changes to form fields.
    new_params = Map.put(socket.assigns.form.params, field, new_value)
    handle_event("validate", %{"data" => new_params}, socket)
  end

  defp get_param(form, field) do
    Map.get(form.params, field)
      || Map.get(form.data, String.to_existing_atom(field))
  end

  defp save_record(socket, :edit, form_params) do
    case Context.update_record(socket.assigns.data, form_params) do
      {:ok, data} ->
        notify_parent({:saved, data})

        {:noreply,
         socket
         |> put_flash(:info, "Weight updated successfully!")
         |> push_patch(to: socket.assigns.patch)}

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
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, action: :validate, as: "data"))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
