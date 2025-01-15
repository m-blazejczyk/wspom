defmodule Wspom.Weight.Context do

  import Ecto.Changeset

  alias Wspom.Weight.Database

  @doc """
  Returns a new weight measurement record with a `nil` id and with `date`
  defaulted to today. The weight defaults to "" to make it easier on the
  form.

  ## Examples

      iex> new_record()
      %{id: nil, date: today, weight: ""}
  """
  def new_record() do
    now = Timex.now("America/Montreal") |> DateTime.to_date() |> Date.to_string()
    %{id: nil, date: now, weight: ""}
  end

  @doc """
  Creates a changeset based on the given record and a list of changes
  made in a form.

  ## Examples

      iex> to_changeset(%{}, %{})
      %Ecto.Changeset{}
  """
  def to_changeset(%{} = data, form_params \\ %{}) do
    types = %{weight: :float, date: :string}

    {data, types}
    |> cast(form_params, [:weight, :date])
    |> validate_required([:weight, :date])
    |> validate_number(:weight, greater_than: 0, less_than: 100)
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

  @doc """
  Returns all records from the database.

  ## Examples

      iex> list_records()
      [%{}]
  """
  def list_records do
    []
    # Database.get_all_records()
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
    case new_record()
    |> to_changeset(changes)
    |> update_record() do
      {:error, _changeset} = err ->
        err
      {:ok, created_record} ->
        saved_record = Database.add_record_and_save(created_record)
        {:ok, saved_record}
    end
  end

  @doc """
  Updates the given weight measurement record based on a map of changes
  made in a form, then saves it in the database.
  `record` is the original, unmodified record of type %{}.
  `changes` is a map containing all the values from the form.

  ## Examples

      iex> update_record(%{}, %{field: new_value})
      {:ok, %{}}

      iex> update_record(%{}, %{field: bad_value})
      {:error, %Ecto.Changeset{}}
  """
  def update_record(record, attrs) do
    case record
    |> to_changeset(attrs)
    |> update_record() do
      {:error, _changeset} = err ->
        err
      {:ok, updated_record} ->
        saved_record = Database.replace_record_and_save(updated_record)
        {:ok, saved_record}
    end
  end

  @doc """
  Updates the record if the changeset is valid. Does not perform any validation
  (validation is supposed to take place inside to_changeset()).

  Returns {:ok, %{}} or {:error, %Ecto.Changeset{}}.

  Notes:
   - changeset.data contains the original record (type: %{})
   - changeset.changes contains a map with the changes, e.g. %{weight: 83.4}
  """
  def update_record(%Ecto.Changeset{valid?: false} = cs) do
    {:error, cs}
  end
  def update_record(%Ecto.Changeset{data: record, changes: changes}) do
    {:ok, record |> Map.merge(changes)}
  end
end
