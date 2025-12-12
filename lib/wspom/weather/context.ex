defmodule Wspom.Weather.Context do

  alias Wspom.Weather.Database

  @doc """
  Returns a map with database stats.
  """
  def get_stats do
    Database.get_stats()
  end

  @doc """
  Returns all hourly weather data from the database.

  ## Example

      iex> get_hourly_all()
      [%{}, …]
  """
  def get_hourly_all do
    Database.get_hourly_all()
  end

  @doc """
  Returns hourly weather data filtered by the given function.

  ## Example

      iex> get_hourly_filtered(fn record -> true end)
      [%{}, …]
  """
  def get_hourly_filtered(func), do: Database.get_hourly_filtered(func)

  @doc """
  Returns the count of all hourly weather records from the database.

  ## Example

      iex> get_hourly_count()
      38308
  """
  def get_hourly_count(), do: Database.get_hourly_count

  @doc """
  Returns the earlliest (oldest) hourly weather record from the database.

  ## Example

      iex> get_hourly_earliest()
      %{…}
  """
  def get_hourly_earliest(), do: Database.get_hourly_earliest

  @doc """
  Returns the latest (newest) hourly weather record from the database.

  ## Example

      iex> get_hourly_latest()
      %{…}
  """
  def get_hourly_latest(), do: Database.get_hourly_latest

  @doc """
  Gets the full description of the status of fetch and save operations.
  Returns a string separated with \n.
  """
  def get_status_description(), do: Database.get_status_description
end
