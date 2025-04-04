defmodule Wspom.Weight.Database do
  use Agent
  require Logger

  alias Wspom.DbBase

  @db_file "weight.dat"
  @db_file_backup "weight.bak.dat"

  defp log_notice(s) do
    Logger.notice(s)
  end

  def start_link([is_production: is_production]) do
    Agent.start_link(fn -> init_state(is_production) end, name: __MODULE__)
  end

  defp init_state(is_production) do
    if is_production do
      DbBase.load_db_file(@db_file, &init_db/0)
      |> maybe_migrate_and_save()
      |> summarize_db()
    else
      data = Enum.map(1..5, &generate_record/1)
      %{
        data: data,
        version: 1,
        is_production: false,
      }
      |> summarize_db()
    end
  end

  defp maybe_migrate_and_save(%{version: _current_version} = state) do
    state
  end

  defp summarize_db(%{data: data, version: version} = state) do
    log_notice("### Weight database version #{version} ###")
    log_notice("### #{length(data)} measurements ###")
    state
  end

  def init_db() do
    %{
      data: [],
      version: 1,
      is_production: true,
    }
  end

  defp generate_record(id) do
    date = DateTime.utc_now()
    |> DateTime.to_date()
    |> Date.add(-(id - 1))
    |> Date.to_string()

    %{
      id: id,
      date: date,
      weight: 83 + (:rand.uniform(200) / 100.0 - 1.0)
    }
  end

  def get_stats do
    Agent.get(__MODULE__, fn %{data: data} ->
      %{days: length(data)}
    end)
  end

  # Will return nil if the record is not found.
  def get_record(id) do
    Agent.get(__MODULE__, fn %{data: data} ->
      data |> Enum.find(fn record -> record.id == id end)
    end)
  end

  def get_all_records() do
    Agent.get(__MODULE__, fn %{data: data} -> data end)
  end

  def add_record_and_save(created_record) do
    Logger.notice("Saving the added record…")
    modify_and_save_data(created_record, fn records, record ->
    # Don't allow duplicate records for the same date!
    record_with_same_date = records |> Enum.find(&(&1.date == record.date))
      if record_with_same_date == nil do
        # No record exists with this date - insert a new one
        max_id = DbBase.find_max_id(records)
        new_record = %{record | id: max_id + 1}
        {[new_record | records], new_record}
      else
        # There already is a record with this date - modify it
        new_record = %{record | id: record_with_same_date.id}
        {records |> DbBase.find_and_replace(new_record), new_record}
      end
    end)
  end

  def replace_record_and_save(updated_record) do
    Logger.notice("Saving the modified record…")
    modify_and_save_data(updated_record, fn records, record ->
      {records |> DbBase.find_and_replace([], record), record}
    end)
  end

  def modify_and_save_data(record, update_fun) do
    Agent.get_and_update(__MODULE__,
      fn %{data: data} = state ->
        {new_data, new_record} = update_fun.(data, record)
        new_state = %{state | data: new_data}

        new_state |> DbBase.save_db_file(@db_file, @db_file_backup)

        {new_record, new_state}
      end)
  end
end
