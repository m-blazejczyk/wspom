defmodule Wspom.Weather.ChartData do

  alias Wspom.Weather.Context
  alias Wspom.Charts.{TickX, TickY, Series, Subchart}

  def process_data() do
    # The test dataset happens to include full days at the end
    data = Context.get_hourly_data |> Enum.take(-(24*7))
    series = data |> get_all_series
    {subcharts, total_height} = series |> make_subcharts |> set_chart_positions
    subcharts = subcharts |> Enum.map(&position_points/1)
    xticks = make_xticks(series.timestamps)
    # 45 will be the bottom margin under the last subchart
    {subcharts, total_height + 45, xticks}
  end

  def get_all_series(data) do
    # Input to this function is raw data from the file (a list of records)
    # Output is a map of tuples: {name, min, max, data}, keys being series ids
    # `data` is just a list of numbers or nil values for now
    %{
      temp_hi: get_one_series(data, :temp_hi, "Max temp", "rgba(255, 27, 27, 1)"),
      temp_lo: get_one_series(data, :temp_lo, "Min temp", "rgba(255, 174, 174, 1)"),
      temp_avg: get_one_series(data, :temp_avg, "Temp", "rgba(255, 110, 110, 1)"),
      dew_point_avg: get_one_series(data, :dew_point_avg, "Dew point", "rgba(34, 138, 28, 1)"),

      thsw_index_avg: get_one_series(data, :thsw_index_avg, "THSW", "rgba(255, 27, 27, 1)"),
      wind_chill_lo: get_one_series(data, :wind_chill_lo, "Min wind chill", "rgba(82, 126, 188, 1)"),

      temp_in: get_one_series(data, :temp_in, "Indoor temp", "rgba(255, 110, 110, 1)"),

      hum_avg: get_one_series(data, :hum_avg, "Humidity", "rgba(82, 126, 188, 1)"),

      hum_in: get_one_series(data, :hum_in, "Indoor humidity", "rgba(82, 126, 188, 1)"),

      pressure: get_one_series(data, :pressure, "Air pressure", "rgba(114, 114, 114, 1)"),

      rainfall_mm: get_one_series(data, :rainfall_mm, "Rainfall [mm]", "rgba(18, 95, 202, 1)"),

      solar_rad_avg: get_one_series(data, :solar_rad_avg, "Avg solar rad", "rgba(255, 226, 164, 1)"),
      solar_rad_hi: get_one_series(data, :solar_rad_hi, "Max solar rad", "rgba(255, 178, 11, 1)"),

      wind_dir_of_prevail: get_one_series_basic(data, :wind_dir_of_prevail, "Prevailing wind dir"),

      wind_speed_avg: get_one_series(data, :wind_speed_avg, "Avg wind speed", "rgba(176, 176, 176, 1)"),
      wind_speed_hi: get_one_series(data, :wind_speed_hi, "Max wind speed", "rgba(42, 42, 42, 1)"),

      timestamps: get_one_series_basic(data, :time, "Time")
      # heat_index_hi: get_one_series(data, :heat_index_hi, "Max heat index"),
      # thw_index_avg: get_one_series(data, :thw_index_avg, "THW"),
      # wet_bulb_avg: get_one_series(data, :wet_bulb_avg, "Wet bulb")
    }
  end

  def get_one_series(data, index, name, color) do
    starting_series = %Series{name: name, min: nil, max: nil, data: [], color: color}
    series_with_data = data
    |> Enum.reduce(starting_series,
      fn record, %Series{min: old_min, max: old_max, data: old_data} = series ->
        val = Map.get(record, index)
        %{
          series |
          min: new_min(old_min, val),
          max: new_max(old_max, val),
          data: [val | old_data]
        }
      end)
    %{series_with_data | data: series_with_data.data |> Enum.reverse}
  end

  def get_one_series_basic(data, index, name) do
    starting_series = %Series{name: name, data: []}
    series_with_data = data
    |> Enum.reduce(starting_series,
      fn record, %Series{data: old_data} = series ->
        val = Map.get(record, index)
        %{series | data: [val | old_data]}
      end)
    %{series_with_data | data: series_with_data.data |> Enum.reverse}
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
        [series.dew_point_avg, series.temp_hi, series.temp_lo, series.temp_avg],
        "Temperature", 5, 0),
      make_one_subchart([series.hum_avg],
        "Humidity", 20, 30),
      make_one_subchart([series.pressure],
        "Barometric pressure", 10, 30) |> add_xticks,
      make_one_subchart([series.rainfall_mm],
        "Rainfall", 2, 30),
      make_one_subchart([series.solar_rad_hi, series.solar_rad_avg],
        "Solar radiation", 200, 30),
      make_one_subchart([series.wind_speed_hi, series.wind_speed_avg],
        "Wind speed", 10, 30) |> add_xticks,
      %Subchart{series: [series.wind_dir_of_prevail],
        name: "Prevailing wind direction", chart_height: 90, graph_height: 30},
      make_one_subchart([series.temp_in],
        "Indoor temperature", 5, 30),
      make_one_subchart([series.hum_in],
        "Indoor humidity", 20, 30) |> add_xticks
    ]
  end

  def make_subcharts_test(series) do
    # The input here is the output from get_all_series()
    [
      make_one_subchart([series.thsw_index_avg],
        "thsw_index_avg", :top, 5),
      make_one_subchart([series.wind_chill_lo],
        "wind_chill_lo", :middle, 5),
      make_one_subchart([series.dew_point_avg],
        "dew_point_avg", :middle, 5),
      make_one_subchart([series.temp_hi],
        "temp_hi", :middle, 5),
      make_one_subchart([series.temp_lo],
        "temp_lo", :middle, 5),
      make_one_subchart([series.temp_avg],
        "temp_avg", :middle, 5),
      make_one_subchart([series.hum_avg],
        "hum_avg", :middle, 20),
      make_one_subchart([series.pressure],
        "pressure", :middle, 10),
      make_one_subchart([series.rainfall_mm],
        "rainfall_mm", :middle, 2),
      make_one_subchart([series.solar_rad_hi],
        "solar_rad_hi", :middle, 200),
      make_one_subchart([series.solar_rad_avg],
        "solar_rad_avg", :middle, 200),
      make_one_subchart([series.wind_speed_hi],
        "wind_speed_hi", :middle, 10),
      make_one_subchart([series.wind_speed_avg],
        "wind_speed_avg", :middle, 10),
      make_one_subchart([series.temp_in],
        "temp_in", :middle, 5),
      make_one_subchart([series.hum_in],
        "hum_in", :bottom, 20)
    ]
  end

  defp make_one_subchart(series, name, tick_len, top_padding) do
    {min, max} = series
    |> Enum.reduce({nil, nil},
      fn %Series{min: this_min, max: this_max}, {old_min, old_max} ->
        {new_min(old_min, this_min), new_max(old_max, this_max)}
      end)
    {y_ticks, min_limit, max_limit} = ticks(min, max, tick_len)
    graph_height = (length(y_ticks) - 1) * 30
    %Subchart{name: name, series: series,
      min: min, max: max,
      tick_len: tick_len, ticks: y_ticks,
      min_limit: min_limit, max_limit: max_limit,
      graph_height: graph_height,
      chart_height: graph_height + 30 + top_padding}
  end

  def axis_limits(min, max, tick_len) do
    {
      Float.floor(min / tick_len) * tick_len,
      Float.ceil(max / tick_len) * tick_len
    }
  end

  def ticks(min, max, tick_len) do
    {min_limit, max_limit} = axis_limits(min, max, tick_len)

    temp = build_ticks(min_limit, tick_len, max_limit, [min_limit])
    |> Enum.reverse

    height = (length(temp) - 1) * 30

    tick_list = temp
    |> Enum.map(fn tick_pos ->
      pixel_perc = (tick_pos - min_limit) / (max_limit - min_limit)
      pixel_pos = round(height * (1.0 - pixel_perc))
      %TickY{
        pos: pixel_pos,
        raw_pos: tick_pos,
        text: Integer.to_string(trunc(tick_pos))
      }
    end)

    {tick_list, min_limit, max_limit}
  end

  defp add_xticks(%Subchart{} = subchart) do
    %{subchart | xticks?: true}
  end

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

  def position_points(%Subchart{ticks: ticks} = subchart)
  when ticks != nil do
    %{subchart | series: subchart.series |> Enum.map(fn s ->
      position_points_one_series(s, subchart)
    end)}
  end
  def position_points(%Subchart{} = subchart) do
    # This variant will be called for the "prevailing wind direction" subchart
    subchart
  end

  defp position_points_one_series(series, subchart) do
    data_len = length(series.data)
    %{series |
      data: series.data
        |> Enum.zip(0..(data_len - 1))
        |> Enum.map(fn pt_with_idx ->
          position_one_point(pt_with_idx, subchart, data_len)
        end)}
  end

  defp position_one_point({nil, _idx}, _subchart, _data_len), do: nil
  defp position_one_point({pt, idx}, subchart, data_len) do
    {
      calculate_x(idx, data_len),
      subchart.graph_pos + subchart.graph_height -
        (pt - subchart.min_limit) / (subchart.max_limit - subchart.min_limit) *
        subchart.graph_height
    }
  end

  defp calculate_x(idx, data_len), do: 55 + (idx * 955 / (data_len - 1))

  defp make_xticks(timestamps) do
    # Timestamps should be a list looking like this:
    # [
    #   {#DateTime<2025-09-20 00:00:00-04:00 EDT America/Montreal>, 0},
    #   {#DateTime<2025-09-20 12:00:00-04:00 EDT America/Montreal>, 12},
    #   {#DateTime<2025-09-21 00:00:00-04:00 EDT America/Montreal>, 24},
    #   ...
    #   {#DateTime<2025-09-26 12:00:00-04:00 EDT America/Montreal>, 156}
    # ]
    data_len = length(timestamps.data)
    timestamps.data
    |> Enum.zip(0..(data_len - 1))
    |> Enum.take_every(12)
    |> Enum.map(fn {time, idx} ->
      x = calculate_x(idx, data_len)
      text = if time.hour == 0 do
        Calendar.strftime(time, "%a %b %-d")  # e.g. Mon, Jan 1
      else
        nil
      end
      %TickX{pos: x, text_up: text, text_down: nil}
    end)
  end
end
