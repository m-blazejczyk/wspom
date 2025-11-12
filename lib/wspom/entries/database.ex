defmodule Wspom.Entries.Database do
  use Agent
  use Timex

  require Logger

  alias Wspom.DbBase
  alias Wspom.Entries.Migrations
  alias Wspom.Entries.TnC
  alias Wspom.Entry

  @db_file "wspom.dat"
  @db_file_backup "wspom.bak.dat"
  @tags_file "tags.dat"
  @tags_file_backup "tags.bak.dat"

  defp log_notice(s) do
    Logger.notice(s)
  end

  def start_link([is_production: is_production]) do
    Agent.start_link(fn -> init_entry_data(is_production) end, name: __MODULE__)
  end

  defp init_entry_data(is_production) do
    if is_production do
      %{version: entries_version} = entries_db =
        DbBase.load_db_file(@db_file, &create_test_entries/0)
      %{version: tags_version} = tags_db =
        DbBase.load_db_file(@tags_file, &create_test_tags_cascades/0)
      if entries_version != tags_version do
        raise "ERROR: versions of the entries and tags databases are different!"
      end
      {entries_db, tags_db} |> maybe_migrate_and_save() |> summarize_db()
    else
      {create_test_entries(), create_test_tags_cascades()}
      |> summarize_db()
    end
  end

  defp create_test_entries() do
    %{
      entries: Enum.map(1..5, &generate_entry/1),
      version: Migrations.current_version(),
      is_production: false,
    }
  end

  defp generate_entry(id) do
    now = DateTime.utc_now() |> Timex.shift(days: -(id - 1))

    %Entry{description: "This is the description of entry #{id}", title: "Entry #{id}",
      id: id, year: now.year, month: now.month, day: now.day,
      weekday: now |> Timex.weekday(), date: now |> DateTime.to_date()}
  end

  defp create_test_tags_cascades() do
    %{
      tags: MapSet.new(["t1", "t2", "c", "t3"]),
      cascades: %{"c" => ["t1", "t2", "c"]},
      version: Migrations.current_version(),
      is_production: false,
    }
  end

  # This function variant transitions from the single-file database
  # to the double-file one.
  defp maybe_migrate_and_save(%{version: current_version} = state) do
    case Migrations.migrate(state) do
      {%{version: new_version}, %{}} = new_state ->
        if new_version != current_version do
          save_all(new_state)
        else
          state
        end
    end
  end
  # This function variant is applicable to the double-file database,
  # i.e. after Dec 30, 2024.
  defp maybe_migrate_and_save({%{version: current_version}, %{}} = state) do
    case Migrations.migrate(state) do
      {%{version: new_version}, %{}} = new_state ->
        if new_version != current_version do
          save_all(new_state)
        else
          state
        end
    end
  end

  defp summarize_db(
    {%{entries: entries, version: version},
     %{tags: tags, cascades: cascades}} = state) do

    log_notice("### Entries database version #{version} ###")
    log_notice("### #{length(entries)} entries ###")
    log_notice("### #{MapSet.size(tags)} tags ###")
    log_notice("### #{map_size(cascades)} cascades ###")
    state
  end

  defp save_all({entries_db, tags_db} = state) do
    DbBase.save_db_file(entries_db, @db_file, @db_file_backup)
    DbBase.save_db_file(tags_db, @tags_file, @tags_file_backup)
    state
  end

  def get_next_entry_to_tag() do
    Agent.get(__MODULE__, fn {%{entries: entries}, %{}} ->
      entries |> Enum.reduce(nil, &entry_to_tag/2)
    end)
  end
  defp entry_to_tag(entry, nil) do
    if MapSet.size(entry.tags) == 0 do
      entry
    else
      nil
    end
  end
  defp entry_to_tag(entry, earliest_entry) do
    # Date.compare() returns :gt if first date is later than the second and :lt for vice versa.
    if MapSet.size(entry.tags) == 0 and Date.compare(entry.date, earliest_entry.date) == :lt do
      entry
    else
      earliest_entry
    end
  end

  def get_stats do
    Agent.get(__MODULE__, fn {%{entries: entries}, %{tags: tags, cascades: cascades}} ->
      %{
        entries: length(entries),
        tags: MapSet.size(tags),
        cascades: map_size(cascades)
      }
    end)
  end

  def get_entry(id) do
    Agent.get(__MODULE__, fn {%{entries: entries}, %{}} ->
      entries |> Enum.find(fn entry -> entry.id == id end)
    end)
  end

  def all_entries() do
    Agent.get(__MODULE__, fn {%{entries: entries}, %{}} -> entries end)
  end

  def all_tags() do
    Agent.get(__MODULE__, fn {%{}, %{tags: tags}} -> tags end)
  end

  def all_cascades() do
    Agent.get(__MODULE__, fn {%{}, %{cascades: cascades}} -> cascades end)
  end

  def all_tags_and_cascades() do
    Agent.get(__MODULE__, fn {%{}, %{tags: tags, cascades: cascades}} -> {tags, cascades} end)
  end

  # This function uses Agent.get_and_update() to modify the entries in the
  # database and to save the entries db file. The tags database is modified
  # according to information provided in arguments `cascade_defs` and `unknown_tags`.
  # The tags database is saved if this information actually resulted in the
  # tags database being altered.
  #
  # The actual modification is performed by the function provided as the last
  # argument; this function takes the list of entries and the new entry, and it
  # returns a tuple of {new_list_of_entries, the_entry}. The entry is returned
  # in case it needed to be modified by the function.
  defp save_entries_and_tags(%Entry{} = entry, cascade_defs, unknown_tags, update_fun) do
    Agent.get_and_update(__MODULE__,
      fn {%{entries: entries} = entries_state,
        %{tags: tags, cascades: cascades} = tags_state} ->

        {new_entries, new_entry} = update_fun.(entries, entry)
        new_entries_state = %{entries_state | entries: new_entries}
        new_tags = tags |> MapSet.union(unknown_tags)
        new_cascades = cascades |> Map.merge(cascade_defs)

        # There is no need to save the tags database if the tags and cascades didn't change
        if MapSet.size(new_tags) == MapSet.size(tags) and map_size(cascade_defs) == 0 do
          new_entries_state |> DbBase.save_db_file(@db_file, @db_file_backup)
          {new_entry, {new_entries_state, tags_state}}
        else
          new_state = {new_entries_state, %{tags_state | tags: new_tags, cascades: new_cascades}}
          |> save_all()
          {new_entry, new_state}
        end
    end)
  end

  # This function uses Agent.get_and_update() to modify the entries in the
  # database and to save the entries db file. The tags database is not modified.
  #
  # The actual modification is performed by the function provided as the second
  # argument; this function takes the list of entries and the new entry, and it
  # returns a tuple of {new_list_of_entries, the_entry}. The entry is returned
  # in case it needed to be modified by the function.
  defp modify_and_save_entries(%Entry{} = entry, update_fun) do
    Agent.get_and_update(__MODULE__,
      fn {%{entries: entries} = entries_state, %{} = tags_state} ->
        {new_entries, new_entry} = update_fun.(entries, entry)
        new_entries_state = %{entries_state | entries: new_entries}

        new_entries_state |> DbBase.save_db_file(@db_file, @db_file_backup)

        {new_entry, {new_entries_state, tags_state}}
      end)
  end

  # The low-level function used to replace an entry in a list of entries.
  #
  # Returns a tuple containing the new list of entries and the original
  # unmodified entry.
  defp replace_entry(entries, entry) do
    {entries |> DbBase.find_and_replace([], entry), entry}
  end

  @doc """
  The top-level function used to add a new entry to the database.
  The second argument is a map containing details about modifications
  to the tags and cascades that were requested by the user.
  If the map is empty, it means that the entry has no tags or the user
  only reused existing tags and cascades.

  This function will modify the input entry: the id will be added.

  The entry will be added and the entries database will be saved.
  The tags database will only be saved if it's necessary.

  ## Examples

      iex> replace_entry_and_save(%Entry{} = entry, %{cascade_defs: cascade_defs, unknown_tags: unknown_tags})
      %Entry{}

      iex> replace_entry_and_save(%Entry{} = entry, %{})
      %Entry{}
  """
  def replace_entry_and_save(%Entry{} = entry, %{cascade_defs: cascade_defs, unknown_tags: unknown_tags}) do
    # This variant will be called when tags have been modified
    log_notice("Saving the modified entry and tags / cascades…")
    save_entries_and_tags(entry, cascade_defs, unknown_tags, &replace_entry/2)
  end
  def replace_entry_and_save(%Entry{} = entry, %{}) do
    # This variant will be called when tags have NOT been modified
    log_notice("Saving only the modified entry…")
    modify_and_save_entries(entry, &replace_entry/2)
  end

  # The low-level function used to add a new entry to a list of entries
  # and to set its id.
  #
  # Returns a tuple containing the new list of entries and the modified entry.
  defp add_entry(entries, entry) do
    max_id = DbBase.find_max_id(entries)
    new_entry = %Entry{entry | id: max_id + 1}
    {[new_entry | entries], new_entry}
  end

  @doc """
  The top-level function used to add a new entry to the database.
  The second argument is a map containing details about modifications
  to the tags and cascades that were requested by the user.
  If the map is empty, it means that the entry has no tags or the user
  only reused existing tags and cascades.

  This function will modify the input entry: the id will be added.

  The entry will be added and the entries database will be saved.
  The tags database will only be saved if it's necessary.

  ## Examples

      iex> add_entry_and_save(%Entry{} = entry, %{cascade_defs: cascade_defs, unknown_tags: unknown_tags})
      %Entry{}

      iex> add_entry_and_save(%Entry{} = entry, %{})
      %Entry{}
  """
  def add_entry_and_save(%Entry{} = entry, %{cascade_defs: cascade_defs, unknown_tags: unknown_tags}) do
    # This variant will be called when tags have been provided
    log_notice("Saving the added entry and tags / cascades…")
    save_entries_and_tags(entry, cascade_defs, unknown_tags, &add_entry/2)
  end
  def add_entry_and_save(%Entry{} = entry, %{}) do
    # This variant will be called when tags have NOT been provided
    log_notice("Saving only the added entry…")
    modify_and_save_entries(entry, &add_entry/2)
  end

  # In addition to adding the entries, this function will also assign ids to them
  # if necessary.
  def append_entries_and_save(entries) do
    log_notice("Appending #{length(entries)} entries and saving the database…")

    Agent.update(__MODULE__,
      fn {%{entries: db_entries} = entries_state, %{} = tags_state} ->
        max_id = DbBase.find_max_id(db_entries)

        {entries_with_ids, _} = entries
        |> Enum.map_reduce(max_id + 1, fn entry, next_id ->
          if entry.id == nil do
            {%Entry{entry | id: next_id}, next_id + 1}
          else
            {entry, next_id}
          end
        end)

        new_entries_state =
          %{entries_state | entries: db_entries ++ entries_with_ids}
          |> DbBase.save_db_file(@db_file, @db_file_backup)
        {new_entries_state, tags_state}
      end)

    :ok
  end

  @doc """
  Clones an entry and saves it in the entries database.

  The cloned entry will not have any tags and fields `importance`, `fuzzy`
  and `needs_review` will be reset to default values. The new entry will
  also have a valid id.

  ## Examples

      iex> clone_entry_and_save(entry)
      %Entry{}

  """
  def clone_entry_and_save(entry) do
    log_notice("Cloning entry with id #{entry.id} and saving the database…")

    Agent.get_and_update(__MODULE__,
      fn {%{entries: db_entries} = entries_state, %{} = tags_state} ->
        max_id = DbBase.find_max_id(db_entries)
        cloned_entry = Entry.clone(entry, max_id + 1)

        new_entries_state =
          %{entries_state | entries: [cloned_entry | db_entries]}
          |> DbBase.save_db_file(@db_file, @db_file_backup)
        {cloned_entry, {new_entries_state, tags_state}}
      end)
  end

  @doc """
  Deletes the given entry and saves the entries database.

  ## Examples

      iex> delete_entry_and_save(%Entry{})
      :ok

  """
  def delete_entry_and_save(entry) do
    log_notice("Deleting entry with id #{entry.id} and saving the database…")

    Agent.get_and_update(__MODULE__,
      fn {%{entries: db_entries} = entries_state, %{} = tags} ->
        new_entries = db_entries
        |> Enum.reject(&(&1.id == entry.id))

        new_entries_state =
          %{entries_state | entries: new_entries}
          |> DbBase.save_db_file(@db_file, @db_file_backup)
        {:ok, {new_entries_state, tags}}
      end)
  end

  @doc """
  Returns the number of entries that are tagged with the given tag.

  ## Examples

      iex> count_entries_tagged_with("felek")
      89
  """
  def count_entries_tagged_with(tag) do
    Agent.get(__MODULE__, fn {%{entries: entries}, %{}} ->
      entries |> TnC.count_entries_tagged_with(tag)
    end)
  end

  @doc """
  Deletes the given tag from the tags database and the entries database.
  Then saves both databases.

  ## Examples

      iex> delete_tag_and_save("test_tag")
      :ok
  """
  def delete_tag_and_save(tag) do
    Agent.update(__MODULE__, fn state ->
      state
      |> TnC.delete_tag(tag)
      |> save_all()
    end)

    :ok
  end

  @doc """
  Deletes the cascade with the given name from the tags database.
  Then saves the database.

  ## Examples

      iex> delete_cascade_and_save("test_cascade")
      {:ok, "Cascade deleted"}
  """
  def delete_cascade_and_save(cascade_name) do
    Agent.update(__MODULE__, fn {%{} = entries_db, %{} = tags_db} ->
      {entries_db,
        tags_db
        |> TnC.delete_cascade(cascade_name)
        |> DbBase.save_db_file(@tags_file, @tags_file_backup)}
    end)

    :ok
  end

  @doc """
  Cleans up and saves the tags database. "Clean up" means removing tags and
  cascades that are not used in any entries.

  ## Examples

      iex> cleanup_tags_and_save()
      {:ok, "Deleted 2 tags and 0 cascades"}

  """
  def cleanup_tags_and_save() do
    Agent.get_and_update(__MODULE__, fn {%{} = entries_db, %{} = tags_db} ->
      {new_tags_db, message} = TnC.cleanup_tags(entries_db, tags_db)

      {
        {:ok, message},
        {
          entries_db,
          new_tags_db
          |> DbBase.save_db_file(@tags_file, @tags_file_backup)
        }
      }
    end)
  end
end
