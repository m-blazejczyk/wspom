defmodule Wspom.DbBase do
  require Logger

  def load_db_file(filename, init_fun \\ nil) do
    if init_fun == nil do
      File.read!(filename) |> :erlang.binary_to_term
    else
      with {:ok, raw_data} <- File.read(filename) do
        raw_data |> :erlang.binary_to_term
      else
        _ -> init_fun.()
      end
    end
  end

  def save_db_file(data, db_file, backup_file) do
    # Rename the current database file to serve as a backup.
    # This will overwrite an existing, previous backup.
    File.rename(db_file, backup_file)

    # Save.
    File.write!(db_file, :erlang.term_to_binary(data))
    Logger.notice("Database saved to #{db_file}!")

    # Return the data in case the caller wants to chain function calls.
    data
  end

  def find_max_id(list) do
    list
    |> Enum.reduce(0, fn item, max_id ->
      if item.id > max_id, do: item.id, else: max_id end)
  end

  def find_and_replace([], acc, _), do: acc
  def find_and_replace([head | rest], acc, nil) do
    # This variant will be called AFTER we found the entry to be replaced
    # Just keep building the list
    find_and_replace(rest, [head | acc], nil)
  end
  def find_and_replace([head | rest], acc, item) do
    # This variant will be called BEFORE we find the item to be replaced
    if head.id == item.id do
      # We found it! Recursively call find_and_replace with item set to nil
      # to prevent unnecessary comparisons
      find_and_replace(rest, [item | acc], nil)
    else
      # We haven't found it yet. Keep going!
      find_and_replace(rest, [head | acc], item)
    end
  end
end
