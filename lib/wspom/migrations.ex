defmodule Wspom.Migrations do
  alias Wspom.Entry

  require Logger

  @versions [{2, &Wspom.Migrations.add_index/1},
             {3, &Wspom.Migrations.convert_entry/1},
             {4, &Wspom.Migrations.fix_weekdays/1},
             {5, &Wspom.Migrations.fix_br/1},
             {6, &Wspom.Migrations.fix_nil_descriptions/1}]

  def migrate(state) do
    inspect_data(state)
    new_state = Enum.reduce(@versions, state, &maybe_migrate/2)
    if elem(new_state, 3) <= elem(state, 3) do
      Logger.notice("No need to migrate the database")
    end
    new_state
  end

  defp inspect_data({[_ | [_elem | _]] = _entries, _tags, _cascades, _current}) do
  end

  # %{
  #   id: 2,
  #   description: "This is an event reminder",
  #   title: "urodziny wujka Wacka",
  #   month: 3,
  #   __struct__: Entry,
  #   day: 15,
  #   year: 1942,
  #   tags: MapSet.new(["michal", "rodzina", "urodziny", "wujki_ciocie"]),
  #   fuzzy: 0,
  #   importance: :normal,
  #   needs_review: false,
  #   weekday: 3
  # }

  defp maybe_migrate({migration_version, _}, {_, _, _, current} = state)
  when current >= migration_version do
    state
  end
  defp maybe_migrate({migration_version, fun}, {entries, tags, cascades, current})
  when current < migration_version do
    {new_entries, new_tags, new_cascades, descr} = fun.({entries, tags, cascades})
    Logger.notice("Migrating the database to version #{migration_version}: #{descr}")
    {new_entries, new_tags, new_cascades, migration_version}
  end

  def add_index({entries, tags, cascades}) do
    new_entries = entries |> Enum.with_index(fn entry, index ->
      Map.put(entry, :id, index + 1)
    end)
    {new_entries, tags, cascades, "Adding indices to all entries"}
  end

  defp convert_one_entry(%{
      id: id,
      description: description,
      title: title,
      month: month,
      day: day,
      year: year,
      tags: tags,
      fuzzy: fuzzy,
      importance: importance,
      needs_review: needs_review,
      weekday: weekday
    }) do
    %Entry{id: id,
      description: description,
      title: title,
      month: month,
      day: day,
      year: year,
      tags: tags,
      fuzzy: fuzzy,
      importance: importance,
      needs_review: needs_review,
      weekday: weekday}
  end

  def convert_entry({entries, tags, cascades}) do
    new_entries = entries |> Enum.map(&convert_one_entry/1)
    {new_entries, tags, cascades, "Converting all entries to Wspom.Entry type"}
  end

  defp fix_weekday(entry) do
    new_weekday = Date.new!(entry.year, entry.month, entry.day) |> Timex.weekday()
    %Entry{entry | weekday: new_weekday}
  end

  def fix_weekdays({entries, tags, cascades}) do
    new_entries = entries |> Enum.map(&fix_weekday/1)
    {new_entries, tags, cascades, "Fixing weekdays"}
  end

  defp fix_one_br(entry) do
    new_descr = if entry.description == nil do
      Logger.warning("Nil description for #{entry.title}")
      nil
    else
      entry.description
        |> String.replace("<br><br>", "\n")
        |> String.replace("<br>", "\n")
    end
    %Entry{entry | description: new_descr}
  end

  def fix_br({entries, tags, cascades}) do
    new_entries = entries |> Enum.map(&fix_one_br/1)
    {new_entries, tags, cascades, "Fixing <br> tags"}
  end

  defp fix_nil_description(entry) do
    new_descr = if entry.description == nil do
      ""
    else
      entry.description
    end
    %Entry{entry | description: new_descr}
  end

  def fix_nil_descriptions({entries, tags, cascades}) do
    new_entries = entries |> Enum.map(&fix_nil_description/1)
    {new_entries, tags, cascades, "Fixing nil descriptions"}
  end
end
