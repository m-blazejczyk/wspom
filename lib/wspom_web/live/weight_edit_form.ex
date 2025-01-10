defmodule WspomWeb.Live.WeightEditForm do
  use WspomWeb, :live_component

  import Ecto.Changeset

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

        <.input field={@form[:date]} type="text"
          class_container="flex items-start flex-col justify-start"/>

        <.input field={@form[:weight]} type="number"
          class_container="flex items-start flex-col justify-start"/>

        <:actions>
          <.button phx-disable-with="Saving…" class="w-full">Save</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  defp to_changeset(%{} = data, attrs \\ %{}) do
    types = %{weight: :float, date: :date}

    {data, types}
    |> cast(attrs, [:weight, :date])
    |> validate_required([:weight, :date])
    |> validate_number(:weight, greater_than: 0, less_than: 100)
  end

  @impl true
  def update(%{data: data} = assigns, socket) do
    {:ok,
      socket
      |> assign(assigns)
      |> assign_new(:form, fn -> to_form(to_changeset(data), as: "data") end)}
  end

  @impl true
  def handle_event("validate", %{"data" => form_params}, socket) do
    changeset = to_changeset(socket.assigns.data, form_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate, as: "data"))}
  end

  def handle_event("save", %{"data" => form_params}, socket) do
    save_entry(socket, socket.assigns.action, form_params)
  end

  defp save_entry(socket, :edit, form_params) do
    case update_record(socket.assigns.data, form_params) do
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
  defp save_entry(socket, :add, form_params) do
    case create_record(form_params) do
      {:ok, data} ->
        notify_parent({:saved, data})

        {:noreply,
         socket
         |> put_flash(:info, "Weight entered successfully!")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, as: "data"))}
    end
  end

  defp update_record(data, _form_params) do
    {:ok, data}
  end

  defp create_record(_form_params) do
    {:ok, %{}}
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
