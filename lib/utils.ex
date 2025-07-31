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
    Timex.now("America/Montreal") |> DateTime.to_date()
  end

  # This function will set a new value of the given form field.
  def set_form_param(socket, field, value) do
    socket.assigns.form.params |> Map.put(field, value)
  end
end
