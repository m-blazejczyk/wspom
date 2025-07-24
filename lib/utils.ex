defmodule Utils do
  def weekday_long_name(1), do: "Poniedziałek"
  def weekday_long_name(2), do: "Wtorek"
  def weekday_long_name(3), do: "Środa"
  def weekday_long_name(4), do: "Czwartek"
  def weekday_long_name(5), do: "Piątek"
  def weekday_long_name(6), do: "Sobota"
  def weekday_long_name(7), do: "Niedziela"

  def weekday_short_name(1), do: "Pn"
  def weekday_short_name(2), do: "Wt"
  def weekday_short_name(3), do: "Śr"
  def weekday_short_name(4), do: "Czw"
  def weekday_short_name(5), do: "Pt"
  def weekday_short_name(6), do: "So"
  def weekday_short_name(7), do: "N"

  def date_now() do
    Timex.now("America/Montreal") |> DateTime.to_date() |> Date.to_string()
  end

  # Takes the form params, turns them into a changeset and then runs it through `to_form`
  # and assigns the result to the socket.
  def apply_dynamic_param_change(socket, param, value, changeset_fn, opts \\ []) do
    new_params = socket.assigns.form.params |> Map.put(param, value)
    changeset = changeset_fn.(socket.assigns.data, new_params)
    form = Phoenix.Component.to_form(changeset, opts ++ [action: :validate])
    {:noreply, socket |> Phoenix.Component.assign(form: form)}
  end

  # This function will grab the current value of the given form field;
  # if `params` don't contain it yet (as it will happen if the field wasn't yet
  # modified by the user), we grab the value from `data`, i.e. the initial record.
  def get_form_param(socket, field) do
    Map.get(socket.assigns.form.params, field)
      || Map.get(socket.assigns.form.data, String.to_existing_atom(field))
  end

  # This function will set a new value of the given form field.
  def set_form_param(socket, field, value) do
    socket.assigns.form.params |> Map.put(field, value)
  end
end
