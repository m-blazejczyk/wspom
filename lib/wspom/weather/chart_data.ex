defmodule Wspom.Weather.ChartData do

  alias Wspom.Charts.{TickY, Series, Subchart}

  def process_data() do
    # The test dataset happens to include full days at the end
    IO.puts("Loading weather data from weather_6.dat...")
    data = File.read!("../weather_6.dat")
    |> :erlang.binary_to_term()
    |> Enum.take(-(24*7))
    series = data |> get_all_series
    {subcharts, total_height} = series |> make_subcharts |> set_chart_positions
    # 45 will be the bottom margin under the last subchart
    {subcharts, total_height + 45}
  end

  def get_all_series(data) do
    # Input to this function is raw data from the file (a list of records)
    # Output is a map of tuples: {name, min, max, data}, keys being series ids
    # `data` is just a list of numbers or nil values for now
    %{
      dew_point_avg: get_one_series(data, :dew_point_avg, "Dew point"),
      # heat_index_hi: get_one_series(data, :heat_index_hi, "Max heat index"),
      hum_avg: get_one_series(data, :hum_avg, "Humidity"),
      hum_in: get_one_series(data, :hum_in, "Indoor humidity"),
      pressure: get_one_series(data, :pressure, "Air pressure"),
      rainfall_mm: get_one_series(data, :rainfall_mm, "Rainfall [mm]"),
      solar_rad_avg: get_one_series(data, :solar_rad_avg, "Avg solar rad"),
      solar_rad_hi: get_one_series(data, :solar_rad_hi, "Max solar rad"),
      temp_avg: get_one_series(data, :temp_avg, "Temp"),
      temp_hi: get_one_series(data, :temp_hi, "Max temp"),
      temp_lo: get_one_series(data, :temp_lo, "Min temp"),
      temp_in: get_one_series(data, :temp_in, "Indoor temp"),
      thsw_index_avg: get_one_series(data, :thsw_index_avg, "THSW"),
      # thw_index_avg: get_one_series(data, :thw_index_avg, "THW"),
      # wet_bulb_avg: get_one_series(data, :wet_bulb_avg, "Wet bulb"),
      wind_chill_lo: get_one_series(data, :wind_chill_lo, "Min wind chill"),
      wind_dir_of_prevail: get_one_series(data, :wind_dir_of_prevail, "Prev ailing wind dir"),
      wind_speed_avg: get_one_series(data, :wind_speed_avg, "Avg wind speed"),
      wind_speed_hi: get_one_series(data, :wind_speed_hi, "Max wind speed")
    }
  end

  def get_one_series(data, index, name) do
    starting_series = %Series{name: name, min: nil, max: nil, data: []}
    data
    |> Enum.reduce(starting_series,
      fn record, %Series{name: name, min: old_min, max: old_max, data: old_data} ->
        val = Map.get(record, index)
        %Series{
          name: name,
          min: new_min(old_min, val),
          max: new_max(old_max, val),
          data: [val | old_data]
        }
      end)
  end

  defp new_min(nil, nil), do: nil
  defp new_min(nil, val), do: val
  defp new_min(old_min, nil), do: old_min
  defp new_min(old_min, val), do: (if val < old_min, do: val, else: old_min)

  defp new_max(nil, nil), do: nil
  defp new_max(nil, val), do: val
  defp new_max(old_max, nil), do: old_max
  defp new_max(old_max, val), do: (if val > old_max, do: val, else: old_max)

  def make_subcharts(series) do
    # The input here is the output from get_all_series()
    [
      make_one_subchart(
        [ series.thsw_index_avg, series.wind_chill_lo, series.dew_point_avg,
          series.temp_hi, series.temp_lo, series.temp_avg],
        "Temperature", :top, 5, 10),
      make_one_subchart([series.hum_avg],
        "Humidity", :middle, 10, 20),
      make_one_subchart([series.pressure],
        "Barometric pressure", :middle, 10, 20),
      make_one_subchart([series.rainfall_mm],
        "Rainfall", :middle, 2, 10),
      make_one_subchart([series.solar_rad_hi, series.solar_rad_avg],
        "Solar radiation", :middle, 200, 400),
      make_one_subchart([series.wind_speed_hi, series.wind_speed_avg],
        "Wind speed", :middle, 10, 20),
      %Subchart{series: [series.wind_dir_of_prevail],
        name: "Prevailing wind direction", position: :middle,
        chart_height: 90, graph_height: 30},
      make_one_subchart([series.temp_in],
        "Indoor temperature", :middle, 5, 10),
      make_one_subchart([series.hum_in],
        "Indoor humidity", :bottom, 10, 20)
    ]
  end

  defp make_one_subchart(series, name, position, minor_tick, major_tick) do
    {min, max} = series
    |> Enum.reduce({nil, nil},
      fn %Series{min: this_min, max: this_max}, {old_min, old_max} ->
        {new_min(old_min, this_min), new_max(old_max, this_max)}
      end)
    y_ticks = ticks(min, max, major_tick, minor_tick)
    graph_height = (length(y_ticks) - 1) * 30
    %Subchart{name: name, position: position, series: series,
      min: min, max: max,
      minor_tick: minor_tick, major_tick: major_tick, ticks: y_ticks,
      graph_height: graph_height,
      chart_height: graph_height + 30 + padding(position)}
  end

  def axis_limits(min, max, tick_len) do
    {
      Float.floor(min / tick_len) * tick_len,
      Float.ceil(max / tick_len) * tick_len
    }
  end

  def ticks(min, max, major_tick, minor_tick) do
    {min_limit, max_limit} = axis_limits(min, max, minor_tick)

    temp = build_ticks(min_limit, minor_tick, max_limit, [min_limit])
    |> Enum.reverse

    height = (length(temp) - 1) * 30

    temp
    |> Enum.map(fn tick_pos ->
      pixel_perc = (tick_pos - min_limit) / (max_limit - min_limit)
      pixel_pos = round(height * (1.0 - pixel_perc))
      %TickY{
        pos: pixel_pos,
        raw_pos: tick_pos,
        text: Integer.to_string(trunc(tick_pos))
      }
    end)
  end

  defp padding(:top), do: 0
  defp padding(:bottom), do: 30
  defp padding(:middle), do: 30

  def build_ticks(val, step, stop, acc) do
    next_val = val + step
    if next_val == stop do
      [next_val | acc]
    else
      build_ticks(next_val, step, stop, [next_val | acc])
    end
  end

  def set_chart_positions(subcharts) do
    subcharts
    |> Enum.map_reduce(0, fn sc, cur_pos ->
      {
        %{sc |
          chart_pos: cur_pos,
          graph_pos: cur_pos + sc.chart_height - sc.graph_height},
        cur_pos + sc.chart_height
      }
    end)
  end
end
