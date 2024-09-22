defmodule Wspom.Context do
  alias Wspom.Database
  alias Wspom.Entry

  @doc """
  Returns the list of entries.

  ## Examples

      iex> list_entries()
      [%Entry{}, ...]

  """
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
  def get_entry!(_id) do
    %Entry{}
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
    # VERY IMPORTANT:
    # Entries MUST be sorted by date.
    # This means that when entries are added, they must be added
    # in the right location in the list.
    # Otherwise, some functions in the Filter module won't work well.

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
    |> IO.inspect(label: "CHANGESET BEFORE")
    |> Database.update_entry()
    |> IO.inspect(label: "RETURN VALUE")
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
