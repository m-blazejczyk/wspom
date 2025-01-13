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
end
