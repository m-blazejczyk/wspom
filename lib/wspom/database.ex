defmodule Wspom.Database do
  use Agent
  use Timex
  require Logger
  alias Wspom.Migrations
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
      log_notice("### PRODUCTION MODE ###")
      %{version: entries_version} = entries_db = load_db_file(@db_file)
      %{version: tags_version} = tags_db = load_db_file(@tags_file)
      if entries_version != tags_version do
        raise "ERROR: versions of the entries and tags databases are different!"
      end
      {entries_db, tags_db} |> maybe_migrate_and_save() |> summarize_db()
    else
      entries = Enum.map(1..5, &generate_entry/1)
      {%{
        entries: entries,
        version: Migrations.current_version(),
        is_production: false,
      }, %{
        tags: MapSet.new(["t1", "t2", "c", "t3"]),
        cascades: %{"c" => ["t1", "t2", "c"]},
        version: Migrations.current_version(),
        is_production: false,
      }}
      |> summarize_db()
    end
  end

  defp load_db_file(filename) do
    File.read!(filename) |> :erlang.binary_to_term
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
    {%{entries: entries, version: version, is_production: production?},
     %{tags: tags, cascades: cascades}} = state) do

    log_notice("### Database version #{version} ###")
    log_notice("### #{if production?, do: "PRODUCTION", else: "TEST"} ###")
    log_notice("### #{length(entries)} entries ###")
    log_notice("### #{MapSet.size(tags)} tags ###")
    log_notice("### #{map_size(cascades)} cascades ###")
    state
  end

  defp generate_entry(id) do
    now = DateTime.utc_now() |> Timex.shift(days: -(id - 1))

    %Entry{description: "This is the description of entry #{id}", title: "Entry #{id}",
      id: id, year: now.year, month: now.month, day: now.day,
      weekday: now |> Timex.weekday(), date: now |> DateTime.to_date()}
  end

  defp save_all({entries_db, tags_db} = state) do
    save_one_file(entries_db, @db_file, @db_file_backup)
    save_one_file(tags_db, @tags_file, @tags_file_backup)
    state
  end

  defp save_one_file(data, db_file, backup_file) do
    # Rename the current database file to serve as a backup.
    # This will overwrite an existing, previous backup.
    File.rename(db_file, backup_file)

    # Save.
    File.write!(db_file, :erlang.term_to_binary(data))
    log_notice("Database saved to #{db_file}!")

    # Return the data in case the caller wants to chain function calls.
    data
  end

  def get_next_entry_to_tag() do
    Agent.get(__MODULE__, fn {%{entries: entries}, %{}} ->
      entries |> Enum.reduce(nil, &entry_to_tag/2)
    end)
  end
  defp entry_to_tag(entry, nil), do: entry
  defp entry_to_tag(entry, earliest_entry) do
    # Date.compare() returns :gt if first date is later than the second and :lt for vice versa.
    if MapSet.size(entry.tags) == 0 and Date.compare(entry.date, earliest_entry.date) == :lt do
      entry
    else
      earliest_entry
    end
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

  # This variant will be called when tags have been modified
  def replace_entry_and_save(%Entry{} = entry, %{cascade_defs: cascade_defs, unknown_tags: unknown_tags}) do
    log_notice("Saving modified entry and tags / cascades…")

    Agent.update(__MODULE__,
      fn {%{entries: entries} = entries_state,
        %{tags: tags, cascades: cascades} = tags_state} ->

        new_entries_state =
          %{entries_state | entries: entries |> find_and_replace([], entry)}

        new_tags = tags |> MapSet.union(unknown_tags)
        new_cascades = cascades |> Map.merge(cascade_defs)

        # There is no need to save the tags database if the tags and cascades didn't change
        if MapSet.size(new_tags) == MapSet.size(tags) and map_size(cascade_defs) == 0 do
          new_entries_state |> save_one_file(@db_file, @db_file_backup)
          {new_entries_state, tags_state}
        else
          {new_entries_state, %{tags_state | tags: new_tags, cascades: new_cascades}}
          |> save_all()
        end
    end)

    entry
  end
  # This variant will be called when tags have NOT been modified
  def replace_entry_and_save(%Entry{} = entry, %{}) do
    log_notice("Saving modified entry…")

    Agent.update(__MODULE__,
      fn {%{entries: entries} = entries_state, %{} = tags_state} ->
        new_entries_state =
          %{entries_state | entries: entries |> find_and_replace([], entry)}
          |> save_one_file(@db_file, @db_file_backup)
        {new_entries_state, tags_state}
      end)

    entry
  end

  # In addition to adding the entries, this function will also assign ids to them
  # if necessary.
  def append_entries_and_save(entries) do
    log_notice("Appending #{length(entries)} entries and saving the database…")

    Agent.update(__MODULE__,
      fn {%{entries: db_entries} = entries_state, %{} = tags_state} ->
        max_id = db_entries |> Enum.reduce(0, fn entry, max_id ->
          if entry.id > max_id, do: entry.id, else: max_id end)

        {entries_with_ids, _} = entries
        |> Enum.map_reduce(max_id + 1, fn entry, next_id ->
          if entry.id == nil do
            {%Wspom.Entry{entry | id: next_id}, next_id + 1}
          else
            {entry, next_id}
          end
        end)

        new_entries_state =
          %{entries_state | entries: db_entries ++ entries_with_ids}
          |> save_one_file(@db_file, @db_file_backup)
        {new_entries_state, tags_state}
      end)

    :ok
  end

  defp find_and_replace([], acc, _), do: acc
  defp find_and_replace([head | rest], acc, nil) do
    # This variant will be called AFTER we found the entry to be replaced
    # Just keep building the list
    find_and_replace(rest, [head | acc], nil)
  end
  defp find_and_replace([head | rest], acc, %Entry{} = entry) do
    # This variant will be called BEFORE we find the entry to be replaced
    if head.id == entry.id do
      # We found it! Recursively call find_and_replace with entry set to nil
      # to prevent unnecessary comparisons
      find_and_replace(rest, [entry | acc], nil)
    else
      # We haven't found it yet. Keep going!
      find_and_replace(rest, [head | acc], entry)
    end
  end

  # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # All the functions below have been copied from older code.
  # They are not used at the moment and may not work as intended.

  # def modify_tags_cascades_and_save(data) do
  #   log_notice("Making requested changes to tags and/or cascades…")
  #   Agent.update(__MODULE__, fn {entries, tags, cascades, version} ->
  #     {entries |> rename_tag_in_entries(data),
  #       tags |> rename_tag_in_tags(data),
  #       cascades |> rename_tag_in_cascades(data) |> remove_cascade(data),
  #       version}
  #     |> save()
  #   end)
  # end

  # defp rename_tag_in_entries(entries, %{rename_tag: _} = data) do
  #   entries
  #   |> Enum.map(fn entry ->
  #     if entry |> Map.has_key?(:tags) do
  #       %{entry | tags: rename_tag_in_tags(entry.tags, data)}
  #     else
  #       entry
  #     end
  #   end)
  # end
  # defp rename_tag_in_entries(entries, _), do: entries

  # defp rename_tag_in_tags(tags, %{rename_tag: {old_name, new_name}}) do
  #   if tags |> MapSet.member?(old_name) do
  #     tags
  #     |> MapSet.delete(old_name)
  #     |> MapSet.put(new_name)
  #   else
  #     tags
  #   end
  # end
  # defp rename_tag_in_tags(tags, _), do: tags

  # defp rename_tag_in_cascades(cascades, %{rename_tag: {old_name, new_name}} = data) do
  #   cascades
  #   |> Enum.map(fn {name, tags} ->
  #     {if(name == old_name, do: new_name, else: name),
  #       rename_tag_in_tags(tags, data)}
  #   end)
  #   |> Map.new()
  # end
  # defp rename_tag_in_cascades(cascades, _), do: cascades

  # defp remove_cascade(cascades, %{remove_cascade: cascade_name}) do
  #   cascades
  #   |> Map.delete(cascade_name)
  # end
  # defp remove_cascade(cascades, _), do: cascades
end
