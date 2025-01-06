defmodule Wspom.Context do
  alias Wspom.Database
  alias Wspom.Entry

  @doc """
  Returns all entries from the database.

  ## Examples

      iex> list_entries()
      [%Entry{}]

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
  Gets the next entry that needs to be tagged, i.e. the earliest entry
  that has no tags.

  ## Examples

      iex> get_next_entry_to_tag()
      %Entry{}

  """
  def get_next_entry_to_tag do
    Database.get_next_entry_to_tag()
  end

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
  Creates an entry.

  ## Examples

      iex> create_entry(%{field: value})
      {:ok, %Entry{}, tag_changes_summary}

      iex> create_entry(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_entry(attrs \\ %{}) do
    case Entry.new()
    |> Entry.changeset(attrs)
    |> Entry.update_entry() do
      {:error, _changeset} = err ->
        err
      {:ok, updated_entry, tags_info} ->
        # Note: `tags_info` is not a part of the Entry struct;
        # it was added by Entry.update_entry() and it won't be saved.
        # It is used to make changes to the tags database.
        summary = tags_info |> Map.get(:summary, "")
        saved_entry = Database.add_entry_and_save(updated_entry, tags_info)
        {:ok, saved_entry, summary}
    end
  end

  @doc """
  Updates an entry and saves it in the database.
  The 'entry' argument is the original, unmodified entry (%Entry{}).
  The 'attrs' argument is a map containing all the values from the form.

  ## Examples

      iex> update_entry(entry, %{field: new_value})
      {:ok, %Entry{}, tag_changes_summary}

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
        # It is used to make changes to the tags database.
        summary = tags_info |> Map.get(:summary, "")
        saved_entry = Database.replace_entry_and_save(updated_entry, tags_info)
        {:ok, saved_entry, summary}
    end
end

  @doc """
  Deletes an entry.

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

  @doc """
  Clones an entry and saves it in the entries database.

  The cloned entry will not have any tags and fields `importance`, `fuzzy`
  and `needs_review` will be reset to default values. The new entry will
  also have a valid id.

  ## Examples

      iex> clone_entry(entry)
      {:ok, %Entry{}}

  """
  def clone_entry(%Entry{} = entry) do
    cloned_entry = Database.clone_entry_and_save(entry)
    {:ok, cloned_entry}
  end
end
