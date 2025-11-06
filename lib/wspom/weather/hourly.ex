defmodule Wspom.Weather.Hourly do

  alias Wspom.Weather.Context

  @doc """
  Returns the start date & time of the first full week's range of data.
  The returned DateTime is at midnight in our local time zone.

  ## Example

      iex> get_first_weekly_start()
      #DateTime<2025-09-20 00:00:00-04:00 EDT America/Montreal>
  """
  def get_first_weekly_start() do
    Context.get_hourly_earliest().time
    |> DateTime.to_date
    |> DateTime.new!(Time.new!(0, 0, 0), "America/Montreal")
  end

  @doc """
  Returns the start date & time of the last full week's range of data.
  The returned DateTime is at midnight in our local time zone.

  ## Example

      iex> get_last_weekly_start()
      #DateTime<2025-09-20 00:00:00-04:00 EDT America/Montreal>
  """
  def get_last_weekly_start() do
    Context.get_hourly_latest().time
    |> DateTime.to_date
    |> Date.add(-6)
    |> DateTime.new!(Time.new!(0, 0, 0), "America/Montreal")
  end

  @doc """
  Returns the timestamp range representing a full week starting at the
  specified date & time. It should be assumed that the first timestamp
  belongs to the range, but the last one does not; mathematically the
  range can be written as [start, end).

  ## Example

      iex> get_weekly_range(#DateTime<2025-09-20 00:00:00-04:00 EDT America/Montreal>)
      {1758340800, 1758945600}
  """
  def get_weekly_range(start) do
    {
      start |> DateTime.to_unix(),
      start |> DateTime.add(7, :day) |> DateTime.to_unix()
    }
  end

  def get_hourly_from(start) do
    {ts_start, ts_end} = get_weekly_range(start)

    Context.get_hourly_filtered(fn record ->
      record.ts >= ts_start and record.ts < ts_end
    end)
  end
end
