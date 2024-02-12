defmodule Wspom.Migrations do
  @versions [{2, &Wspom.Migrations.add_index/1}]

  def migrate(state) do
    Enum.reduce(@versions, state, &maybe_migrate/2)
  end

  defp maybe_migrate({migration_version, _}, {_, _, _, current} = state)
  when current >= migration_version do
    state
  end
  defp maybe_migrate({migration_version, fun}, {entries, tags, cascades, current})
  when current < migration_version do
    {new_entries, new_tags, new_cascades, descr} = fun.({entries, tags, cascades})
    IO.puts('Migrating the database to version #{migration_version}: #{descr}')
    {new_entries, new_tags, new_cascades, migration_version}
  end

  def add_index({entries, tags, cascades}) do
    new_entries = entries |> Enum.with_index(fn entry, index ->
      Map.put(entry, :id, index + 1)
    end)
    {new_entries, tags, cascades, 'Adding indices to all entries'}
  end
end
