defmodule Wspom.DbBase do
  require Logger

  def load_db_file(filename, init_fun \\ nil) do
    with {:ok, raw_data} <- File.read(filename) do
      raw_data |> :erlang.binary_to_term
    else
      _ ->
        if init_fun == nil do
          raise "ERROR: file #{filename} does not exist and the initialization function was not provided"
        else
          init_fun.()
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

  @doc """
  Returns the largest `id` of the given collection of items.
  Assumes that the items are maps or structs with a field named `id`.
  Will return 0 if the list is empty.

  ## Examples

      iex> find_max_id(items)
      252
  """
  def find_max_id(list) do
    list
    |> Enum.reduce(0, fn item, max_id ->
      if item.id > max_id, do: item.id, else: max_id end)
  end

  @doc """
  Goes over the list of items and replaces the one with `item.id`
  equal to `new_item.id` with `new_item`.
  Returns the collection of items with the item replaced.
  Assumes that the items are maps or structs with a field named `id`.
  The second argument should always be an empty list - or omitted.

  ## Examples

      iex> find_and_replace(items, new_item)
      new_items
  """
  def find_and_replace(old_items, new_items \\ [], new_item)
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
