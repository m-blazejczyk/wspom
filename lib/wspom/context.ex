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
  Gets the next entry that needs to be tagged.

  ## Examples

      iex> get_next_entry_to_tag()
      %Entry{}

  """
  def get_next_entry_to_tag(), do: Database.get_next_entry_to_tag()

  @doc """
  Retrieves the set of all tags and the map of all cascades.

  ## Example

      iex> get_tags_and_cascades()
      {MapSet, %{"name" => MapSet}}

  """
  def get_tags_and_cascades() do
    Database.all_tags_and_cascades()
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
    case entry
    |> Entry.changeset(attrs)
    |> Entry.update_entry() do
      {:error, _changeset} = err ->
        err
      {:ok, updated_entry, tags_info} ->
        # Note: `tags_info` is not a part of the Entry struct;
        # it was added by Entry.update_entry() and it won't be saved.
        summary = tags_info |> Map.get(:summary, "")
        saved_entry = Database.replace_entry_and_save(updated_entry, tags_info)
        {:ok, saved_entry, summary}
    end
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
