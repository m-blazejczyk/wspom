defmodule Wspom.Database do
  # VERY IMPORTANT:
  # Entries MUST be sorted by date.
  # This means that when entries are added, they must be added
  # in the right location in the list.
  # Otherwise, some functions in the Filter module won't work well.

  use Agent
  use Timex
  require Logger
  alias Wspom.Migrations
  alias Wspom.Entry

  @prod_mode false
  @db_file "wspom.dat"
  @db_file_backup "wspom.bak.dat"

  defp log_notice(s) do
    Logger.notice(s)
  end

  def start_link(_) do
    Agent.start_link(&init_entry_data/0, name: __MODULE__)
  end

  defp init_entry_data() do
    if @prod_mode do
      log_notice("### PRODUCTION MODE ###")
      load_db_file() |> maybe_migrate_and_save() |> summarize_db()
    else
      if File.exists?(@db_file) do
        log_notice("### TEST MODE: file loaded ###")
        load_db_file() |> maybe_migrate_and_save() |> summarize_db()
      else
        entries = Enum.map(1..5, &generate_entry/1) ++
          [%Entry{description: "One year ago", title: "Entry 6", id: 6,
            year: 2023, month: 8, day: 26, weekday: 2}]
        log_notice("### TEST MODE: #{length(entries)} entries generated ###")
        {entries, MapSet.new(), %{}, 1}
      end
    end
  end

  defp load_db_file() do
    # This will raise an exception in case of trouble, and that's great!
    {[_ | _], %MapSet{}, %{}, _} = File.read!(@db_file) |> :erlang.binary_to_term
  end

  defp maybe_migrate_and_save({_, _, _, current} = state) do
    {new_entries, new_tags, new_cascades, new_version} = Migrations.migrate(state)
    if new_version > current do
      save({new_entries, new_tags, new_cascades, new_version})
    else
      state
    end
  end

  defp summarize_db({entries, tags, cascades, current} = state) do
    log_notice("### Database version #{current} ###")
    log_notice("### #{length(entries)} entries ###")
    log_notice("### #{MapSet.size(tags)} tags ###")
    log_notice("### #{map_size(cascades)} cascades ###")
    state
  end

  defp generate_entry(id) do
    %Entry{description: "This is the description", title: "Entry #{id}", id: id,
      year: Enum.random(2011..2022), month: Enum.random(1..12), day: Enum.random(1..28),
      weekday: Enum.random(1..7)}
  end

  def get_next_entry_to_tag() do
    Agent.get(__MODULE__, fn {entries, _, _, _} ->
      entries |> Enum.find(&entry_to_tag?/1)
    end)
  end

  defp entry_to_tag?(entry) do
    MapSet.size(Map.get(entry, :tags)) == 0
  end

  def all_entries() do
    Agent.get(__MODULE__, fn {entries, _, _, _} -> entries end)
  end

  def all_tags() do
    Agent.get(__MODULE__, fn {_, tags, _, _} -> tags end)
  end

  def all_cascades() do
    Agent.get(__MODULE__, fn {_, _, cascades, _} -> cascades end)
  end

  def get_state() do
    Agent.get(__MODULE__, fn data -> data end)
  end

  def set_state(data) do
    Agent.update(__MODULE__, fn _ -> data end)
  end

  def migrate() do
    Agent.update(__MODULE__, fn data -> Wspom.Migrations.migrate(data) |> save() end)
  end

  def save() do
    Agent.update(__MODULE__, fn data -> save(data) end)
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
    case Enum.reduce(changes, {:continue, entry}, &update_field/2) do
      {:error, {field, error}} ->
        {:error, changeset |> Ecto.Changeset.add_error(field, error)}
      {:continue, new_entry} ->
        case Date.new(new_entry.year, new_entry.month, new_entry.day) do
          {:ok, new_date} ->
            new_entry = %Entry{new_entry | date: new_date, weekday: Timex.weekday(new_date)}
            {:ok, replace_entry_and_save(new_entry)}
          {:error, _} ->
            {:error, changeset |> Ecto.Changeset.add_error(:day, "invalid date")}
        end
    end

    # Update the tags
  end

  # Used by Enum.reduce() to go over a map.
  # The first argument is a tuple with {field_name, new_value}.
  # The second argument is the accumulator - one of:
  # {:continue, %Entry{}}
  # {:error, message} (where 'message' is a string)
  # Returns the new accumulator.
  defp update_field(_, {:error, _} = error) do
    # Once an error was encountered, ignore all subsequent changes
    error
  end
  defp update_field({field_name, _field_value}, {:continue, %Entry{} = _entry})
    when field_name == :weekday or field_name == :date do
    {:error, {field_name, "Not allowed to set #{field_name} directly"}}
  end
  defp update_field({field_name, _field_value}, {:continue, %Entry{} = _entry})
    when field_name == :importance or field_name == :tags do
    {:error, {field_name, "#{field_name}: not implemented"}}
  end
  defp update_field({field_name, field_value}, {:continue, %Entry{} = entry}) do
    {:continue, entry |> Map.put(field_name, field_value)}
  end

  defp replace_entry_and_save(%Entry{} = entry) do
    log_notice("Saving modified entry…")
    Agent.update(__MODULE__, fn {entries, tags, cascades, version} ->
      {entries |> find_and_replace([], entry),
        tags,
        cascades,
        version}
      |> save()
    end)
    entry
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

  def tag_entry_and_save(data) do
    log_notice("Saving entered data…")
    Agent.update(__MODULE__, fn {entries, tags, cascades, version} ->
      {entries |> tag_entries(data),
        tags |> add_tags(data),
        cascades |> add_cascades(data),
        version}
      |> save()
    end)
  end

  def modify_tags_cascades_and_save(data) do
    log_notice("Making requested changes to tags and/or cascades…")
    Agent.update(__MODULE__, fn {entries, tags, cascades, version} ->
      {entries |> rename_tag_in_entries(data),
        tags |> rename_tag_in_tags(data),
        cascades |> rename_tag_in_cascades(data) |> remove_cascade(data),
        version}
      |> save()
    end)
  end

  defp tag_entries([], _), do: []
  defp tag_entries([entry | rest], nil) do
    [entry | tag_entries(rest, nil)]
  end
  defp tag_entries([entry | rest], data) do
    if entry_to_tag?(entry) do
      # Update entry with data and continue.
      # Pass 'nil' as 'data' to indicate that the item has been updated.#
      [entry |> tag_entry(data) | tag_entries(rest, nil)]
    else
      [entry | tag_entries(rest, data)]
    end
  end

  defp tag_entry(entry, data) do
    %{entry |
      fuzzy: data |> Map.get(:fuzzy, entry.fuzzy),
      importance: data |> Map.get(:importance, entry.importance),
      needs_review: data |> Map.get(:needs_review, entry.needs_review),
      tags: MapSet.union(entry.tags, data |> Map.get(:tags, MapSet.new()))}
  end

  defp add_tags(tags, %{tags_unknown: new_tags}) do
    MapSet.union(tags, MapSet.new(new_tags))
  end
  defp add_tags(tags, _), do: tags

  defp add_cascades(cascades, %{cascades_unknown: new_cascades}) do
    Map.merge(cascades, Map.new(new_cascades))
  end
  defp add_cascades(cascades, _), do: cascades

  defp rename_tag_in_entries(entries, %{rename_tag: _} = data) do
    entries
    |> Enum.map(fn entry ->
      if entry |> Map.has_key?(:tags) do
        %{entry | tags: rename_tag_in_tags(entry.tags, data)}
      else
        entry
      end
    end)
  end
  defp rename_tag_in_entries(entries, _), do: entries

  defp rename_tag_in_tags(tags, %{rename_tag: {old_name, new_name}}) do
    if tags |> MapSet.member?(old_name) do
      tags
      |> MapSet.delete(old_name)
      |> MapSet.put(new_name)
    else
      tags
    end
  end
  defp rename_tag_in_tags(tags, _), do: tags

  defp rename_tag_in_cascades(cascades, %{rename_tag: {old_name, new_name}} = data) do
    cascades
    |> Enum.map(fn {name, tags} ->
      {if(name == old_name, do: new_name, else: name),
        rename_tag_in_tags(tags, data)}
    end)
    |> Map.new()
  end
  defp rename_tag_in_cascades(cascades, _), do: cascades

  defp remove_cascade(cascades, %{remove_cascade: cascade_name}) do
    cascades
    |> Map.delete(cascade_name)
  end
  defp remove_cascade(cascades, _), do: cascades

  defp save(state) do
    # Rename the current database file to serve as a backup.
    # This will overwrite an existing, previous backup.
    File.rename(@db_file, @db_file_backup)

    # Save.
    File.write! "wspom.dat", :erlang.term_to_binary(state)
    log_notice("Saved!")

    # Return the state.
    state
  end
end
