defmodule Wspom.Weather.Fetcher do
  @doc """
  Downloads all raw weather data between the two specified timestamps.

  The starting timestamp will NOT be incluced, as per the API.

  Both timestamps must fall on a full hour.

  The data is returned raw but has atoms instead of strings as map keys.

  This function may take a long time to run for long periods because
  the API enforces throttling (10 requests per second, max).

  ## Example:
    download_weather_data(1_758_927_600, 1_764_630_000)
    download_weather_data(1_758_927_600, 1_759_143_600)  # only 2.5 days
  """
  def download_weather_data(start_ts, end_ts) do
    if end_ts <= start_ts do
      raise ArgumentError, message: "End time stamp is before start time stamp"
    end
    if start_ts |> ts_full_hour? do
      raise ArgumentError, message: "Start time stamp does not fall on full hour"
    end
    if end_ts |> ts_full_hour? do
      raise ArgumentError, message: "End time stamp does not fall on full hour"
    end

    days = walk_period(start_ts, end_ts, 1, [])

    IO.puts("\nData for #{length(days)} days was downloaded successfully.")

    # CAREFUL: The data returned by the API may contain surprises
    # when compared to the timestamp range. Best not to make assumptions
    # in terms of what exact range of timestamps was returned by the API.
    days |> Enum.reverse
  end

  @doc """
  Returns true if the given time stamp falls on a full hour.
  """
  def ts_full_hour?(ts) do
    rem(ts, 3600) != 0
  end

  @doc """
  "Walks" the entire period between `start_ts` and `end_ts`, breaking it up
  into sub-periods of duration not more than 86400 seconds (the maximum
  supported by the API).

  The last sub-period may be shorter than 86400.

  This function does not check the arguments!
  """
  def walk_period(start_ts, end_ts, n, days)
  when start_ts + 86400 >= end_ts do
    # The last iteration
    day = call_weather_api_batch(start_ts, end_ts, n)
    [day | days]
  end
  def walk_period(start_ts, end_ts, n, days) do
    day = call_weather_api_batch(start_ts, start_ts + 86400, n)
    walk_period(start_ts + 86400, end_ts, n + 1, [day | days])
  end

  @doc """
  A version of `call_weather_api` to be used to doanload data in larger
  batches. Will print a dot every 10 downloads (when n is divisible by 10)
  and will sleep 150 ms between API calls.
  """
  def call_weather_api_batch(start_ts, end_ts, n) do
    data = call_weather_api(start_ts, end_ts)

    if rem(n, 10) == 0, do: IO.write(".")

    # The API has built-in throttling so we can't go too fast
    :timer.sleep(150)

    data
  end

  @doc """
    API docs: https://weatherlink.github.io/v2-api/

    Here, the starting timestamp can be anything, as long as the ending
    timestamp is no more than 86400 seconds later (but it can be a full 86400).

    From the docs: "the WeatherLink v2 API uses the start-timestamp and
    end-timestamp parameters to look for data records where timestamps fall
    into an interval that can be expressed as (start-timestamp, end-timestamp].
    This is equivalent to looking for data records with a
    timestamp > start-timestamp and <= end-timestamp."

    To cover larger periods, we should produce the following:
    {start-timestamp=1621031400, end-timestamp=1621117800},
    {start-timestamp=1621117800, end-timestamp=1621204200},
    {start-timestamp=1621204200, end-timestamp=1621290600}, …
  """
  def call_weather_api(start_ts, end_ts) do
    if end_ts - start_ts > 86400 do
      raise ArgumentError, message: "Period too long (#{start_ts} - #{end_ts})"
    end

    # IO.puts("Downloading between #{start_ts} and #{end_ts}")

    api_key = System.get_env("WL_KEY")
    api_secret = System.get_env("WL_SECRET")

    data =
      HTTPoison.get!(
        "https://api.weatherlink.com/v2/historic/111045?api-key=" <>
          api_key <>
          "&start-timestamp=#{start_ts}&end-timestamp=#{end_ts}",
        [{"X-Api-Secret", api_secret}]
      )

    {:ok, json} = Poison.decode(data.body)

    # Convert string keys to atoms - they are much easier to work with
    atomize(json)
  end

  @doc """
  Recursively convert string keys to atoms in a map or a list.
  """
  def atomize(m) when is_map(m) do
    for {key, val} <- m, into: %{} do
      {String.to_atom(key), atomize(val)}
    end
  end
  def atomize(l) when is_list(l) do
    for item <- l, do: atomize(item)
  end
  def atomize(v), do: v

  @doc """
  Get the earliest and latest timestamps from the given raw data,
  as returned by `download_weather_data()`.
  """
  def get_ts_range(data) do
    {
      hd(hd(hd(data).sensors).data).ts,
      List.last(hd(List.last(data).sensors).data).ts
    }
  end

  @doc """
  The complete pipeline to process all data. The input should come from
  `download_weather_data()`. The output should be ready to be appended
  to hourly data in the database!
  """
  def process_raw_data(data) do
    {start_ts, end_ts} = get_ts_range(data)

    data
    |> delete_sensor
    |> flatten
    |> filter_fields
    |> convert_data
    |> linearize(start_ts, end_ts)
    |> aggregate_hours
  end

  def get_sensor_stats(days) do
    days
    |> Enum.reduce(%{}, fn day, acc ->
      day.sensors
      |> Enum.reduce(acc, fn sensor, s_acc ->
        key = {sensor.lsid, sensor.sensor_type, sensor.data_structure_type}
        Map.update(s_acc, key, 1, fn cnt -> cnt + 1 end)
      end)
    end)
  end

  # Result:
  # iex(4)> Wspom.Scripts.get_sensor_stats(data)
  # %{
  #   {407504, 504, 15} => 1596,  <- Station info; dropped
  #   {407505, 242, 13} => 1596,  <- barometer
  #   {407506, 243, 13} => 1596,  <- inside
  #   {419423, 50, 11} => 1596    <- outside
  # }

  def delete_sensor(days) do
    days
    |> Enum.map(fn day ->
      new_sensors =
        day.sensors
        |> Enum.filter(fn sensor -> sensor.sensor_type != 504 end)

      %{day | sensors: new_sensors}
    end)
  end

  def flatten(days) do
    days
    |> Enum.map(fn day ->
      day.sensors
      |> Enum.reduce(%{}, fn sensor, acc ->
        convert_for_flattening(acc, sensor.data, sensor.sensor_type)
      end)
    end)
  end

  def convert_for_flattening(acc, data, 243 = _sensor_type), do: Map.put(acc, :inside, data)
  def convert_for_flattening(acc, data, 242 = _sensor_type), do: Map.put(acc, :pressure, data)
  def convert_for_flattening(acc, data, 50 = _sensor_type), do: Map.put(acc, :outside, data)

  def filter_fields(days) do
    # C = F x 5 / 9
    # bar = inches of mercury
    # 33.8639 * inhg
    # wind speed: mph
    allowed_pressure = [:bar_hi, :bar_lo, :ts]
    allowed_inside = [:hum_in_hi, :hum_in_lo, :temp_in_hi, :temp_in_lo, :ts]

    allowed_outside = [
      :dew_point_hi,
      :dew_point_lo,
      :heat_index_hi,
      :hum_hi,
      :hum_lo,
      :rainfall_mm,
      :solar_rad_avg,
      :solar_rad_hi,
      :temp_avg,
      :temp_hi,
      :temp_lo,
      :thsw_index_hi,
      :thsw_index_lo,
      :thw_index_hi,
      :thw_index_lo,
      :wet_bulb_hi,
      :wet_bulb_lo,
      :wind_chill_lo,
      :wind_dir_of_prevail,
      :wind_speed_avg,
      :wind_speed_hi,
      :ts
    ]

    days
    |> Enum.map(fn day ->
      %{
        inside: filter_fields_one_day(day.inside, allowed_inside),
        pressure: filter_fields_one_day(day.pressure, allowed_pressure),
        outside: filter_fields_one_day(day.outside, allowed_outside)
      }
    end)
  end

  def filter_fields_one_day(data, allowed) do
    data
    |> Enum.map(fn record ->
      for {key, val} <- record, key in allowed, into: %{} do
        {key, val}
      end
    end)
  end

  def convert_data(days) do
    days
    |> Enum.map(fn day ->
      %{
        inside: day.inside |> Enum.map(&convert_inside/1),
        pressure: day.pressure |> Enum.map(&convert_pressure/1),
        outside: day.outside |> Enum.map(&convert_outside/1)
      }
    end)
  end

  def convert_pressure(data) do
    %{pressure: (data.bar_hi + data.bar_lo) / 2.0 * 33.8639, ts: data.ts}
  end

  def convert_inside(data) do
    %{
      hum_in: (data.hum_in_hi + data.hum_in_lo) / 2.0,
      temp_in: ((data.temp_in_hi + data.temp_in_lo) / 2.0 - 32.0) / 1.8,
      ts: data.ts
    }
  end

  def convert_outside(data) do
    # if data.wind_speed_hi == nil, do: IO.inspect(data)

    %{
      dew_point_avg: ((data.dew_point_hi + data.dew_point_lo) / 2.0 - 32.0) / 1.8,
      thsw_index_avg:
        if data.thsw_index_hi == nil or data.thsw_index_lo == nil do
          nil
        else
          ((data.thsw_index_hi + data.thsw_index_lo) / 2.0 - 32.0) / 1.8
        end,
      thw_index_avg:
        if data.thw_index_hi == nil or data.thw_index_lo == nil do
          nil
        else
          ((data.thw_index_hi + data.thw_index_lo) / 2.0 - 32.0) / 1.8
        end,
      wet_bulb_avg: ((data.wet_bulb_hi + data.wet_bulb_lo) / 2.0 - 32.0) / 1.8,
      hum_avg: (data.hum_hi + data.hum_lo) / 2.0,
      heat_index_hi: (data.heat_index_hi - 32.0) / 1.8,
      # rain_size: data.rain_size,
      # rainfall_in: data.rainfall_in,
      rainfall_mm: data.rainfall_mm,
      solar_rad_avg: data.solar_rad_avg,
      solar_rad_hi: data.solar_rad_hi,
      temp_avg: (data.temp_avg - 32.0) / 1.8,
      temp_hi: (data.temp_hi - 32.0) / 1.8,
      temp_lo: (data.temp_lo - 32.0) / 1.8,
      wind_chill_lo:
        if(data.wind_chill_lo == nil, do: nil, else: (data.wind_chill_lo - 32.0) / 1.8),
      wind_dir_of_prevail: data.wind_dir_of_prevail,
      wind_speed_avg: data.wind_speed_avg * 1.609344,
      wind_speed_hi: if(data.wind_speed_hi == nil, do: nil, else: data.wind_speed_hi * 1.609344),
      ts: data.ts
    }
  end

  def check_linearity(days, start_ts, end_ts) do
    tss = start_ts..end_ts//900 |> Range.to_list() |> Map.from_keys(0)

    days
    |> Enum.reduce(tss, fn day, acc ->
      new_acc = Enum.reduce(day.inside, acc, &count_timestamp/2)
      new_acc = Enum.reduce(day.pressure, new_acc, &count_timestamp/2)
      new_acc = Enum.reduce(day.outside, new_acc, &count_timestamp/2)
      new_acc
    end)
    |> Map.to_list()
    |> Enum.frequencies_by(fn {_k, v} -> v end)

    # Result on the test dataset:
    # iex(13)> Wspom.Scripts.check_linearity(data)
    # %{0 => 161, 3 => 153074}
  end

  def count_timestamp(record, acc) do
    # if record.ts exists in "acc" -> increase the count (the value in the map)
    # If record.ts does not exist in "acc" -> …print an error? (this case means
    # that the dataset contains a timestamp not aligned at the 15-minute boundary)
    if acc |> Map.has_key?(record.ts) do
      acc |> Map.update!(record.ts, fn v -> v + 1 end)
    else
      IO.puts("Incorrect timestamp: #{record.ts |> DateTime.from_unix!()}")
      acc
    end
  end

  @doc """
  The complete pipeline to process all data. The input should come from
  `download_weather_data()`. `start_ts` and `end_ts` should be the actual
  timestamps from the dataset.
  """
  def linearize(days, start_ts, end_ts) do
    # Generate a list of timestamps where we expect data (every 15 minutes)
    # Make a map with those timestamps as keys and empty maps as values
    tss = start_ts..end_ts//900
    |> Range.to_list()
    |> Map.from_keys(%{})

    # Go over all data and merge it with those maps at the right timestamps
    days
    |> Enum.reduce(tss, fn day, acc ->
      new_acc = Enum.reduce(day.inside, acc, &merge_record/2)
      new_acc = Enum.reduce(day.pressure, new_acc, &merge_record/2)
      new_acc = Enum.reduce(day.outside, new_acc, &merge_record/2)
      new_acc
    end)
    # Convert the map back to a list and sort it
    |> Map.to_list()
    |> Enum.sort_by(fn {k, _v} -> k end)
  end

  def merge_record(record, acc) do
    # if record.ts exists in "acc" -> increase the count (the value in the map)
    # If record.ts does not exist in "acc" -> …print an error? (this case means
    # that the dataset contains a timestamp not aligned at the 15-minute boundary)
    if acc |> Map.has_key?(record.ts) do
      acc |> Map.update!(record.ts, fn m -> Map.merge(m, record) end)
    else
      IO.puts("Incorrect timestamp: #{record.ts} (#{record.ts |> DateTime.from_unix!()})")
      acc
    end
  end

  # iex(40)> tssi = tss |> Enum.map(&(div(div(&1 - 1621034100, 900), 4)))
  # [0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3]
  def aggregate_hours(data) do
    # Here, the input is a list of tuples like this: {1621034100, %{…}},
    # sorted by the timestamp and beggining at the full hour boundary
    # It means that, for example, data with timestamp 2021-05-14 20:00
    # contains data from the following "raw" timestamps:
    # 19:15, 19:30, 19:45 and 20:00.
    # This follows the same specification as the WeatherLink API.
    {earliest, _} = hd(data)
    data
    |> Enum.group_by(
      fn {k, _v} -> div(div(k - earliest, 900), 4) end,
      fn {k, v} -> v |> Map.put(:ts, k) end)
    |> Map.to_list()
    |> Enum.map(&aggregate_one_hour/1)
    |> Enum.sort_by(fn record -> record.ts end)
  end

  def aggregate_one_hour({_k, data}) do
    # Here, the input are tuples representing the map created by the group_by()
    # call in aggregate_hours; the keys are "indices" af each group (they can
    # be ignored - we don't need them); the values are lists of data records
    # (measurements taken at 15-minute intervals during the specific hour).
    # These data records must be aggregated with functions like average, min or max.
    # We need our own copies of the aggregating functions because we need to be able
    # to handle `nil` values properly.
    ts = data |> Enum.map(&(&1.ts)) |> max()
    %{
      dew_point_avg: data |> Enum.map(&(Map.get(&1, :dew_point_avg))) |> mean(),
      heat_index_hi: data |> Enum.map(&(Map.get(&1, :heat_index_hi))) |> max(),
      hum_avg: data |> Enum.map(&(Map.get(&1, :hum_avg))) |> mean(),
      hum_in: data |> Enum.map(&(Map.get(&1, :hum_in))) |> mean(),
      pressure: data |> Enum.map(&(Map.get(&1, :pressure))) |> mean(),
      rainfall_mm: data |> Enum.map(&(Map.get(&1, :rainfall_mm))) |> sum(),
      solar_rad_avg: data |> Enum.map(&(Map.get(&1, :solar_rad_avg))) |> mean(),
      solar_rad_hi: data |> Enum.map(&(Map.get(&1, :solar_rad_hi))) |> max(),
      temp_avg: data |> Enum.map(&(Map.get(&1, :temp_avg))) |> mean(),
      temp_hi: data |> Enum.map(&(Map.get(&1, :temp_hi))) |> max(),
      temp_lo: data |> Enum.map(&(Map.get(&1, :temp_lo))) |> min(),
      temp_in: data |> Enum.map(&(Map.get(&1, :temp_in))) |> mean(),
      thsw_index_avg: data |> Enum.map(&(Map.get(&1, :thsw_index_avg))) |> mean(),
      thw_index_avg: data |> Enum.map(&(Map.get(&1, :thw_index_avg))) |> mean(),
      wet_bulb_avg: data |> Enum.map(&(Map.get(&1, :wet_bulb_avg))) |> mean(),
      wind_chill_lo: data |> Enum.map(&(Map.get(&1, :wind_chill_lo))) |> min(),
      wind_dir_of_prevail: data |> Enum.map(&(Map.get(&1, :wind_dir_of_prevail))) |> mean(),
      wind_speed_avg: data |> Enum.map(&(Map.get(&1, :wind_speed_avg))) |> mean(),
      wind_speed_hi: data |> Enum.map(&(Map.get(&1, :wind_speed_hi))) |> max(),
      ts: ts,
      time: ts |> DateTime.from_unix!() |> DateTime.shift_zone!("America/Montreal")
    }
  end

  def mean([]), do: nil
  def mean(l), do: l |> Enum.filter(&(&1 != nil)) |> mean_non_nil()
  defp mean_non_nil([]), do: nil
  defp mean_non_nil(l), do: Enum.sum(l) / length(l)

  def max([]), do: nil
  def max(l), do: l |> Enum.filter(&(&1 != nil)) |> max_non_nil()
  defp max_non_nil([]), do: nil
  defp max_non_nil(l), do: Enum.max(l)

  def min([]), do: nil
  def min(l), do: l |> Enum.filter(&(&1 != nil)) |> min_non_nil()
  defp min_non_nil([]), do: nil
  defp min_non_nil(l), do: Enum.min(l)

  def sum([]), do: nil
  def sum(l), do: l |> Enum.filter(&(&1 != nil)) |> sum_non_nil()
  defp sum_non_nil([]), do: nil
  defp sum_non_nil(l), do: Enum.sum(l)

  # File.write!("../weather_a1.dat", :erlang.term_to_binary(data))
  # data = File.read!("../weather_a1.dat") |> :erlang.binary_to_term(); length(data)

end
