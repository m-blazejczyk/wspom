# This module cannot be renamed to Wspom.Entries.Entry without
# jeopardizing the data stored in the production database.
defmodule Wspom.Entry do
  alias Wspom.Entries.TnC
  alias Wspom.Entry
  import Ecto.Changeset

  # importance can be :normal, :important or :very_important
  defstruct [:id, :description, :title, :year, :month, :day, :weekday, :date,
    importance: :normal, fuzzy: 0, needs_review: false, tags: MapSet.new()]

  # See https://hexdocs.pm/ecto/Ecto.Schema.html#module-types-and-castin
  @types %{description: :string, title: :string,
    year: :integer, month: :integer, day: :integer, weekday: :integer, date: :date,
    importance: :string, fuzzy: :integer, needs_review: :boolean, tags: :string}

  def new() do
    %Entry{description: "", title: ""}
  end

  def new(title, description, date) do
    %Wspom.Entry{
      # The id will be set by the database when saving - not here
      id: nil,
      description: description,
      title: title,
      year: date.year,
      month: date.month,
      day: date.day,
      weekday: date |> Timex.weekday(),
      date: date
    }
  end

  # Clone the entry but reset fields such as tags, importance, fuzzy
  # and needs_review
  def clone(entry, new_id) do
    %Entry{entry |
      id: new_id, importance: :normal, fuzzy: 0, needs_review: false, tags: MapSet.new()}
  end

  def changeset(entry, attrs) do
    {entry, @types}
    |> cast(attrs, [:description, :title, :year, :month, :day, :weekday, :date,
      :importance, :fuzzy, :needs_review, :tags])
    |> validate_required([:description, :title, :year, :month, :day])
    |> validate_number(:day, greater_than: 0, less_than: 32)
    |> validate_number(:month, greater_than: 0, less_than: 13)
    |> validate_number(:year, greater_than: 1899, less_than: 2026)
    |> validate_inclusion(:importance, ["normal", "important", "very_important"])
    |> validate_date()
    |> ignore_tags()
  end

  defp ignore_tags(%Ecto.Changeset{} = changeset) do
    # This function is needed because of the (very annoying) way Changeset.cast works.
    # Because 'tags' is a MapSet in Entry, Changeset.cast always returns an error,
    # complaining about the 'tags' field.
    # This function simply removes any errors related to 'tags' from the changeset.
    # We will validate tags separately.
    new_changeset = %Ecto.Changeset{changeset | errors: Keyword.delete(changeset.errors, :tags)}
    if length(new_changeset.errors) == 0 do
      %Ecto.Changeset{new_changeset | valid?: true}
    else
      new_changeset
    end
  end

  defp validate_date(%Ecto.Changeset{} = changeset) do
    new_year = Map.get(changeset.changes, :year, Map.get(changeset.data, :year))
    new_month = Map.get(changeset.changes, :month, Map.get(changeset.data, :month))
    new_day = Map.get(changeset.changes, :day, Map.get(changeset.data, :day))
    if new_year != nil and new_month != nil and new_day != nil do
      case Date.new(new_year, new_month, new_day) do
        {:ok, _} ->
          changeset
        {:error, _} ->
          changeset |> Ecto.Changeset.add_error(:day, "invalid date")
      end
    else
      changeset |> Ecto.Changeset.add_error(:day, "empty date")
    end
  end

  def to_editable_map(%Entry{} = entry) do
    %{id: entry.id, description: entry.description, title: entry.title,
      year: entry.year, month: entry.month, day: entry.day,
      fuzzy: entry.fuzzy, needs_review: entry.needs_review,
      tags: tags_to_string(entry.tags)}
  end

  def tags_to_string(tags) do
    if MapSet.size(tags) > 0 do
      tags
      |> MapSet.to_list()
      |> Enum.sort()
      |> Enum.join(" ")
    else
      ""
    end
  end

  @doc """
  Updates an entry if the changeset is valid.
  Returns {:ok, %Entry{}} or {:error, %Ecto.Changeset{}}.
  Notes:
   - changeset.data contains the original entry (type: %Entry{})
   - changeset.changes contains a map containing the changes,
     e.g. %{day: 5, tags: "michal rodzice rodzina"}
  """
  def update_entry(%Ecto.Changeset{valid?: false} = cs) do
    {:error, cs}
  end
  def update_entry(%Ecto.Changeset{data: entry, changes: changes} = changeset) do
    # Go over all changes and update the entry for each of them - or throw an error
    case Enum.reduce(changes, {:continue, entry, %{}}, &update_field/2) do
      {:error, {field, error}} ->
        {:error, changeset |> Ecto.Changeset.add_error(field, error)}
      {:continue, new_entry, tags_info} ->
        # The date has to be checked as the final step
        case Date.new(new_entry.year, new_entry.month, new_entry.day) do
          {:ok, new_date} ->
            new_entry = %Entry{new_entry | date: new_date, weekday: Timex.weekday(new_date)}
            {:ok, new_entry, tags_info}
          {:error, _} ->
            {:error, changeset |> Ecto.Changeset.add_error(:day, "invalid date")}
        end
    end
  end

  # Used by Enum.reduce() to go over a map.
  # The first argument is a tuple with {field_name, new_value}.
  # The second argument is the accumulator - one of:
  # {:continue, %Entry{}, %{}}
  # {:error, message} (where 'message' is a string)
  # Returns the new accumulator.
  defp update_field(_, {:error, _} = error) do
    # Once an error was encountered, ignore all subsequent changes
    error
  end
  defp update_field({field_name, _field_value}, {:continue, %Entry{}, _tags_info})
    when field_name == :weekday or field_name == :date do
    {:error, {field_name, "Not allowed to set #{field_name} directly"}}
  end
  # TODO: it appears that it is nor necessary to manually convert
  # strings to atoms (see book.ex).
  defp update_field({:importance, "normal"}, {:continue, entry = %Entry{}, tags_info}) do
    {:continue, entry |> Map.put(:importance, :normal), tags_info}
  end
  defp update_field({:importance, "important"}, {:continue, entry = %Entry{}, tags_info}) do
    {:continue, entry |> Map.put(:importance, :important), tags_info}
  end
  defp update_field({:importance, "very_important"}, {:continue, entry = %Entry{}, tags_info}) do
    {:continue, entry |> Map.put(:importance, :very_important), tags_info}
  end
  defp update_field({:importance, _other}, {:continue, %Entry{}, _tags_info}) do
    {:error, {:importance, "Importance: unrecognized value"}}
  end
  defp update_field({:tags, field_value}, {:continue, %Entry{} = entry, _tags_info}) do
    case TnC.tags_from_string(field_value) do
      {:error, error} ->
        {:error, {:tags, error}}
      {:ok, %{tags_applied: tags} = tags_info} ->
        {:continue,
        entry |> Map.put(:tags, tags),
        tags_info}
    end
  end
  defp update_field({field_name, field_value}, {:continue, %Entry{} = entry, tags_info}) do
    {:continue, entry |> Map.put(field_name, field_value), tags_info}
  end

  @spec compare_years(%Entry{}, %Entry{}) :: boolean()
  def compare_years(e1, e2), do: e1.year <= e2.year

  @spec compare_dates(%Entry{}, %Entry{}) :: boolean()
  def compare_dates(e1, e2) do
    if e1.year != e2.year do
      e1.year <= e2.year
    else
      if e1.month != e2.month do
        e1.month <= e2.month
      else
        e1.day <= e2.day
      end
    end
  end
end
