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
    now = Timex.now("America/Montreal") |> DateTime.to_date() |> Date.to_string()
    %{id: nil, date: now, weight: ""}
  end

  @doc """
  Creates a changeset based on the given record and a list of changes
  made in a form. Note: form field values are expected to be strings.

  ## Examples

      iex> to_changeset(%{}, %{})
      %Ecto.Changeset{}
  """
  def to_changeset(%{} = data, form_params \\ %{}) do
    types = %{weight: :string, date: :string}

    {data, types}
    |> cast(form_params, [:weight, :date])
    |> validate_required([:weight, :date])
    |> validate_weight(:weight)
    |> validate_date(:date)
  end

  defp validate_date(%Ecto.Changeset{} = changeset, field) do
    with {:ok, date_str} <- changeset |> Ecto.Changeset.fetch_change(field),
         {:error, _err} <- Date.from_iso8601(date_str) do
      changeset |> Ecto.Changeset.add_error(:date, "invalid date")
    else
      _ -> changeset
    end
  end

  defp validate_weight(%Ecto.Changeset{} = changeset, field) do
    with {:ok, weight_str} <- changeset |> Ecto.Changeset.fetch_change(field) do
      with {_, ""} <- Float.parse(weight_str) do
        changeset
      else
        _ -> changeset |> Ecto.Changeset.add_error(:weight, "invalid weight")
      end
    else
      _ -> changeset
    end
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
      {:ok, %{}}

      iex> create_record(%{field: bad_value})
      {:error, %Ecto.Changeset{}}
  """
  def create_record(changes \\ %{}) do
    case new_form_data()
    |> to_changeset(changes)
    |> change_form_record()
    |> to_db_record() do
      {:error, _changeset} = err ->
        err
      {:ok, db_record} ->
        IO.inspect(db_record, label: "DB RECORD IN create_record()")
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
      {:ok, %{}}

      iex> update_record(%{}, %{field: bad_value})
      {:error, %Ecto.Changeset{}}
  """
  def update_record(form_record, attrs \\ %{}) do
    case form_record
    |> to_changeset(attrs)
    |> change_form_record()
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
  Note: the input data for the changeset is the so-called "form record" where the
  fields are specified as strings.
  The data is returned in the format expected by the form (as strings).

  Returns {:ok, %{}} or {:error, %Ecto.Changeset{}}.

  Notes:
   - changeset.data contains the original record (type: %{})
   - changeset.changes contains a map with the changes, e.g. %{"weight" => "83.4"}
  """
  def change_form_record(%Ecto.Changeset{valid?: false} = cs) do
    {:error, cs}
  end
  def change_form_record(%Ecto.Changeset{data: record, changes: changes}) do
    {:ok, record |> Map.merge(changes)}
  end

  @doc """
  Converts the record from the format expected by the form (where all fields are strings)
  to the format expected by the database.

  Returns {:ok, %{}} or {:error, %Ecto.Changeset{}}.
  """
  def to_db_record({:error, _changeset} = err) do
    err
  end
  def to_db_record({:ok, %{id: id, date: date_str, weight: weight_str}}) do
    {:ok, date} = Date.from_iso8601(date_str)
    {weight, ""} = Float.parse(weight_str)

    {:ok, %{id: id, date: date, weight: weight}}
  end
end
