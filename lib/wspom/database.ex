defmodule Wspom.Database do
  use Agent
  require Logger

  @prod_mode false
  @db_file "wspom.dat"
  @db_file_backup "wspom.bak.dat"

  def start_link(_) do
    Agent.start_link(&init_entry_data/0, name: __MODULE__)
  end

  defp init_entry_data() do
    if @prod_mode do
      Logger.notice("PRODUCTION DB MODE")
      # This will raise an exception in case of trouble, and that's great!
      {[_ | _], %MapSet{}, %{}} = File.read!(@db_file) |> :erlang.binary_to_term
    else
      if File.exists?(@db_file) do
        Logger.notice("TEST DB MODE: file loaded")
        File.read!(@db_file) |> :erlang.binary_to_term
      else
        Logger.notice("TEST DB MODE: entries generated")
        {Enum.map(1..5, &generate_entry/1),
          MapSet.new(),
          %{}}
      end
    end
  end

  defp generate_entry(id) do
    %Wspom.Entry{description: "This is the description", title: "Entry #{id}",
      year: Enum.random(2011..2022), month: Enum.random(1..12), day: Enum.random(1..28),
      weekday: Enum.random(1..7)}
  end

  def all_entries() do
    Agent.get(__MODULE__, fn {entries, _, _} -> entries end)
  end

  def all_tags() do
    Agent.get(__MODULE__, fn {_, tags, _} -> tags end)
  end

  def all_cascades() do
    Agent.get(__MODULE__, fn {_, _, cascades} -> cascades end)
  end

  def get_state() do
    Agent.get(__MODULE__, fn data -> data end)
  end

  def set_state(data) do
    Agent.update(__MODULE__, fn _ -> data end)
  end

  def save() do
    Agent.update(__MODULE__, fn data -> save(data) end)
  end

  defp save(state) do
    if @prod_mode do
      # Rename the current database file to serve as a backup.
      # This will overwrite an existing, previous backup.
      File.rename(@db_file, @db_file_backup)

      # Save.
      File.write! "wspom.dat", :erlang.term_to_binary(state)

      Logger.notice("FILE SAVED")
    else
      Logger.notice("PRETENDING to save the file")
    end

    # Return the state.
    state
  end
end
