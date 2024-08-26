defmodule Wspom.Database do
  use Agent
  require Logger
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
      load_db_file() |> summarize_db()
    else
      if File.exists?(@db_file) do
        log_notice("### TEST MODE: file loaded ###")
        load_db_file() |> summarize_db()
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

  def tag_entry_and_save(data) do
    log_notice("\nSaving entered data…")
    Agent.update(__MODULE__, fn {entries, tags, cascades, version} ->
      {entries |> tag_entries(data),
        tags |> add_tags(data),
        cascades |> add_cascades(data),
        version}
      |> save()
    end)
    log_notice("Saved.\n")
  end

  def modify_tags_cascades_and_save(data) do
    log_notice("\nMaking requested changes to tags and/or cascades…")
    Agent.update(__MODULE__, fn {entries, tags, cascades, version} ->
      {entries |> rename_tag_in_entries(data),
        tags |> rename_tag_in_tags(data),
        cascades |> rename_tag_in_cascades(data) |> remove_cascade(data),
        version}
      |> save()
    end)
    log_notice("Saved.\n")
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

    # Return the state.
    state
  end
end
