defmodule Wspom.Database do
  use Agent
  use Timex
  require Logger
  alias Wspom.Migrations
  alias Wspom.Entry

  @db_file "wspom.dat"
  @db_file_backup "wspom.bak.dat"

  defp log_notice(s) do
    Logger.notice(s)
  end

  def start_link([is_production: is_production]) do
    Agent.start_link(fn -> init_entry_data(is_production) end, name: __MODULE__)
  end

  defp init_entry_data(is_production) do
    if is_production do
      log_notice("### PRODUCTION MODE ###")
      load_db_file() |> maybe_migrate_and_save() |> summarize_db()
    else
      entries = Enum.map(1..5, &generate_entry/1)
      %{
        entries: entries,
        tags: MapSet.new(["t1", "t2", "c", "t3"]),
        cascades: %{"c" => ["t1", "t2", "c"]},
        version: Migrations.current_version(),
        is_production: false,
      }
      |> summarize_db()
    end
  end

  defp load_db_file() do
    File.read!(@db_file) |> :erlang.binary_to_term
  end

  defp maybe_migrate_and_save({_, _, _, current_version} = state) do
    case Migrations.migrate(state) do
      {_new_entries, _new_tags, _new_cascades, new_version} = new_state ->
        if new_version > current_version do
          save(new_state)
        else
          state
        end
      %{version: new_version} = new_state ->
        if new_version > current_version do
          save(new_state)
        else
          state
        end
    end
  end
  defp maybe_migrate_and_save(%{version: current_version} = state) do
    case Migrations.migrate(state) do
      %{version: new_version} = new_state ->
        if new_version > current_version do
          save(new_state)
        else
          state
        end
    end
  end

  defp summarize_db({entries, tags, cascades, current} = state) do
    log_notice("### Database version #{current} ###")
    log_notice("### #{length(entries)} entries ###")
    log_notice("### #{MapSet.size(tags)} tags ###")
    log_notice("### #{map_size(cascades)} cascades ###")
    state
  end
  defp summarize_db(%{entries: entries, tags: tags, cascades: cascades, version: version, is_production: production?} = state) do
    log_notice("### Database version #{version} ###")
    log_notice("### #{if production?, do: "PRODUCTION", else: "TEST"} ###")
    log_notice("### #{length(entries)} entries ###")
    log_notice("### #{MapSet.size(tags)} tags ###")
    log_notice("### #{map_size(cascades)} cascades ###")

    IO.inspect(tags |> Enum.filter(fn k -> k |> String.starts_with?("t") end), label: "TAGS LOADED")
    IO.inspect(cascades |> Enum.filter(fn {k, _} -> k |> String.starts_with?("t") end), label: "CASCADES LOADED")

    state
  end

  defp generate_entry(id) do
    now = DateTime.utc_now() |> Timex.shift(days: -(id - 1))

    %Entry{description: "This is the description of entry #{id}", title: "Entry #{id}",
      id: id, year: now.year, month: now.month, day: now.day,
      weekday: now |> Timex.weekday(), date: now |> DateTime.to_date()}
  end

  defp save(state) do
    # Rename the current database file to serve as a backup.
    # This will overwrite an existing, previous backup.
    File.rename(@db_file, @db_file_backup)

    # Save.
    File.write! "wspom.dat", :erlang.term_to_binary(state)
    log_notice("Database saved!")

    # Return the state.
    state
  end

  def get_next_entry_to_tag() do
    Agent.get(__MODULE__, fn %{entries: entries} ->
      entries |> Enum.find(&entry_to_tag?/1)
    end)
  end
  defp entry_to_tag?(entry) do
    MapSet.size(Map.get(entry, :tags)) == 0
  end

  def get_entry(id) do
    Agent.get(__MODULE__, fn %{entries: entries} ->
      entries |> Enum.find(fn entry -> entry.id == id end)
    end)
  end

  def all_entries() do
    Agent.get(__MODULE__, fn %{entries: entries} -> entries end)
  end

  def all_tags() do
    Agent.get(__MODULE__, fn %{tags: tags} -> tags end)
  end

  def all_cascades() do
    Agent.get(__MODULE__, fn %{cascades: cascades} -> cascades end)
  end

  def all_tags_and_cascades() do
    Agent.get(__MODULE__, fn %{tags: tags, cascades: cascades} -> {tags, cascades} end)
  end

  def save() do
    Agent.update(__MODULE__, fn data -> save(data) end)
  end

  def replace_entry_and_save(%Entry{} = entry, %{} = tags_info) do
    log_notice("Saving modified entry…")

    Agent.update(__MODULE__, fn %{entries: entries, tags: tags, cascades: cascades} = state ->
      # `tags_info` is a temporary field in the Entry, added by Entry.update_field().
      # It contains data collected by TnC.tags_from_string().
      %{cascade_defs: cascade_defs, unknown_tags: unknown_tags} = tags_info

      %{state |
        entries: entries |> find_and_replace([], entry),
        tags: tags |> MapSet.union(unknown_tags),
        cascades: cascades |> Map.merge(cascade_defs)}
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

  # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # All the functions below have been copied from older code.
  # They are not used at the moment and may not work as intended.

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
end
