defmodule Wspom.Context do
  alias Wspom.Database
  alias Wspom.Entry

  def list_entries do
    Database.all_entries()
  end

  @doc """
  Gets a single entry.

  Raises `Ecto.NoResultsError` if the Entry does not exist.

  ## Examples

      iex> get_entry!(123)
      %Entry{}

      iex> get_entry!(456)
      ** (Ecto.NoResultsError)

  """
  def get_entry!(id) when is_binary(id) do
    get_entry!(String.to_integer(id))
  end
  def get_entry!(id) when is_integer(id) do
    case entry = Database.get_entry(id) do
      %Entry{} ->
        entry
      _ ->
        raise Ecto.NoResultsError, message: "No entry with id #{id}"
    end
  end

  @doc """
  Creates a entry.

  ## Examples

      iex> create_entry(%{field: value})
      {:ok, %Entry{}}

      iex> create_entry(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_entry(_attrs \\ %{}) do
    # %Entry{}
    # |> Entry.changeset(attrs)
    # |> Repo.insert()
    {:ok, %Entry{}}
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking entry changes.
  This function is invoked every time a field in the form changes.

  ## Examples

      iex> change_entry(entry)
      %Ecto.Changeset{data: %Entry{}}

  """
  def change_entry(entry, attrs \\ %{}) do
    Entry.changeset(entry, attrs)
  end

  @doc """
  Updates a entry.
  The 'entry' argument is the original, unmodified entry (%Entry{}).
  The 'attrs' argument is a map containing all the values from the form.

  ## Examples

      iex> update_entry(entry, %{field: new_value})
      {:ok, %Entry{}}

      iex> update_entry(entry, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_entry(entry, attrs) do
    entry
    |> Entry.changeset(attrs)
    |> Entry.update_entry()
    |> Database.replace_entry_and_save()
    # TODO: Update the tags and cascades
end

  @doc """
  Deletes a entry.

  ## Examples

      iex> delete_entry(entry)
      {:ok, %Entry{}}

      iex> delete_entry(entry)
      {:error, %Ecto.Changeset{}}

  """
  def delete_entry(%Entry{}) do
    # Repo.delete(entry)
    {:ok, %Entry{}}
  end
end
