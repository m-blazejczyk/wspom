defmodule Wspom.Weight.Context do

  import Ecto.Changeset

  alias Wspom.Weight.Database

  @doc """
  Returns a new weight measurement record with a `nil` id and with `date`
  defaulted to today, formatted as string. The weight defaults to "" to make it
  easier on the form. This is the data structure expected by the form component -
  not the data structure to be saved in the database.

  ## Examples

      iex> new_form_data()
      %{id: nil, date: "2025-01-16", weight: ""}
  """
  def new_form_data() do
    %{id: nil, date: Utils.date_now(), weight: ""}
  end

  @doc """
  Creates a changeset based on the given record and a list of changes
  made in a form. Note: form field values are expected to be strings.

  ## Examples

      iex> to_changeset(%{}, %{})
      %Ecto.Changeset{}
  """
  def to_changeset(%{} = data, form_params \\ %{}) do
    types = %{weight: :string, weight_float: :float, date: :string, date_date: :date}

    {data, types}
    |> cast(form_params, [:weight, :date])
    |> validate_required([:weight, :date])
    |> validate_weight(:weight, :weight_float)
    |> validate_date(:date, :date_date)
  end

  # In addition to validating the string field, this function will also
  # put the value as Date into field `db_field` of the changeset.
  defp validate_date(%Ecto.Changeset{} = changeset, str_field, db_field) do
    with {:ok, date_str} <- changeset |> Ecto.Changeset.fetch_change(str_field) do
      with {:ok, date} <- Date.from_iso8601(date_str) do
        changeset |> Ecto.Changeset.put_change(db_field, date)
      else
        _ -> changeset |> Ecto.Changeset.add_error(str_field, "Invalid date")
      end
    else
      _ -> changeset
    end
  end

  # In addition to validating the string field, this function will also
  # put the value as Float into field `db_field` of the changeset.
  defp validate_weight(%Ecto.Changeset{} = changeset, str_field, db_field) do
    with {:ok, weight_str} <- changeset |> Ecto.Changeset.fetch_change(str_field) do
      with {weight, ""} <- Float.parse(weight_str) do
        changeset |> Ecto.Changeset.put_change(db_field, weight)
      else
        _ -> changeset |> Ecto.Changeset.add_error(str_field, "Invalid weight")
      end
    else
      _ -> changeset
    end
  end

  @doc """
  Returns a map with database stats.
  """
  def get_stats do
    Database.get_stats()
  end

  @doc """
  Returns all records from the database.

  ## Examples

      iex> get_all_records()
      [%{}]
  """
  def get_all_records do
    Database.get_all_records()
  end

  @doc """
  Gets a single weight measurement record.

  Raises `Ecto.NoResultsError` if the record does not exist.

  ## Examples

      iex> get_record!(123)
      %{}

      iex> get_record!(456)
      ** (Ecto.NoResultsError)
  """
  def get_record!(id) when is_binary(id) do
    get_record!(String.to_integer(id))
  end
  def get_record!(id) when is_integer(id) do
    # case record = Database.get_record(id) do
    #   %{} ->
    #     record
    #   _ ->
    #     raise Ecto.NoResultsError, message: "No record with id #{id}"
    # end

    # The record's fields must be converted to strings here!
    %{}
  end

  @doc """
  Creates a weight measurement record based on a map of changes made in a form,
  then saves it in the database.

  ## Examples

      iex> create_record(%{field: new_value})
      {:ok, %{...}}

      iex> create_record(%{field: bad_value})
      {:error, %Ecto.Changeset{}}
  """
  def create_record(form_params \\ %{}) do
    case new_form_data()
    |> to_changeset(form_params)
    |> to_db_record() do
      {:error, _changeset} = err ->
        err
      {:ok, db_record} ->
        saved_record = Database.add_record_and_save(db_record)
        {:ok, saved_record}
    end
  end

  @doc """
  Updates the given weight measurement record based on a map of changes
  made in a form, then saves it in the database.
  `record` is the original, unmodified form record of type %{}.
  It's the form record, i.e. it contains all field values specified as strings.
  `changes` is a map containing all the values from the form.

  ## Examples

      iex> update_record(%{}, %{field: new_value})
      {:ok, %{...}}

      iex> update_record(%{}, %{field: bad_value})
      {:error, %Ecto.Changeset{}}
  """
  def update_record(form_record, form_params \\ %{}) do
    case form_record
    |> to_changeset(form_params)
    |> to_db_record() do
      {:error, _changeset} = err ->
        err
      {:ok, db_record} ->
        saved_record = Database.replace_record_and_save(db_record)
        {:ok, saved_record}
    end
  end

  @doc """
  Updates the record if the changeset is valid. Does not perform any validation
  (validation is supposed to take place inside to_changeset()).
  The data is returned in the format expected by the database.

  Returns {:ok, %{...}} or {:error, %Ecto.Changeset{}}.

  Notes:
   - changeset.data contains the original record (type: %{})
   - changeset.changes contains a map with the changes, e.g. %{weight_float: 83.4}
  """
  def to_db_record(%Ecto.Changeset{valid?: false} = cs) do
    {:error, cs}
  end
  def to_db_record(%Ecto.Changeset{data: original, changes: changes}) do
    date = if changes |> Map.has_key?(:date_date),
      do: changes.date_date,
      else: Date.from_iso8601!(original.date)
    weight = if changes |> Map.has_key?(:weight_float),
      do: changes.weight_float,
      else: parse_float!(original.weight)

    {:ok, %{id: original.id, date: date, weight: weight}}
  end

  defp parse_float!(s) do
    {v, ""} = Float.parse(s)
    v
  end
end
