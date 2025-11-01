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

  ## Examples

      iex> get_hourly_data()
      [%{}, …]
  """
  def get_hourly_data do
    Database.get_hourly_data()
  end
end
