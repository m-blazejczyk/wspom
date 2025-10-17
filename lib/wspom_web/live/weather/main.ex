defmodule WspomWeb.Live.Weather.Main do

  use WspomWeb, :live_view

  alias Wspom.Charts.{TickY, Series, Subchart}

  # API documentation: https://weatherlink.github.io/v2-api/tutorial

  @impl true
  def mount(_params, _session, socket) do
    # The test dataset happens to include full days at the end
    IO.puts("Loading weather data from weather_6.dat...")
    data = File.read!("../weather_6.dat")
    |> :erlang.binary_to_term()
    |> Enum.take(-(24*7))
    series = data |> get_all_series
    subcharts = series |> make_subcharts
    {:ok, socket
      |> assign(:data, data)
      |> assign(:series, series)
      |> assign(:subcharts, subcharts),
      layout: {WspomWeb.Layouts, :data_app}}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :main, _params) do
    socket
    |> assign(:page_title, "Weather")
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
    %{
      temperature: make_one_subchart(
        [series.temp_avg, series.temp_hi, series.temp_lo,
          series.dew_point_avg, series.thsw_index_avg, series.wind_chill_lo],
        "Temperature"),

      indoor_temp: make_one_subchart(
        [series.temp_in], "Indoor temperature"),

      humidity: make_one_subchart(
        [series.hum_avg, series.hum_in], "Humidity"),

      pressure: make_one_subchart(
        [series.pressure], "Barometric pressure"),

      rainfall: make_one_subchart(
        [series.rainfall_mm], "Rainfall"),

      solar_rad: make_one_subchart(
        [series.solar_rad_avg, series.solar_rad_hi], "Solar radiation"),

      wind_dir: make_one_subchart(
        [series.wind_dir_of_prevail], "Prevailing wind direction"),

      wind_speed: make_one_subchart(
        [series.wind_speed_avg, series.wind_speed_hi], "Wind speed")
    }
  end

  # [
  #   {"Humidity", 36.4875, 94.3125},           20, 10  -> [25, 50, 75, 100] - 3 section
  #   {"Indoor temperature", 19.25, 23.125},    10, 5   -> [15, 25] - 1
  #   {"Barometric pressure", 1004.3, 1028.6},  20, 10  -> [1000, 1020, 1040] - 2
  #   {"Rainfall", 0, 7.2},                     6,  2   -> [0, 5, 10] - 2
  #   {"Solar radiation", 0.0, 603},            400,200 -> [0, 250, 500, 750] - 3
  #   {"Temperature", 0.7, 26.9},               10, 5   -> [0, 10, 20, 30] - 4
  #   {"Prevailing wind direction", 0.0, 355.75}, --
  #   {"Wind speed", 0.0, 28.9}                 20, 10  ->
  # ]

  defp make_one_subchart(series, name) do
    {min, max} = series
    |> Enum.reduce({nil, nil},
      fn %Series{min: this_min, max: this_max}, {old_min, old_max} ->
        {new_min(old_min, this_min), new_max(old_max, this_max)}
      end)
    %Subchart{name: name, series: series, min: min, max: max}
  end

  def axis_limits(min, max, tick_len) do
    {
      Float.floor(min / tick_len) * tick_len,
      Float.ceil(max / tick_len) * tick_len
    }
  end

  def ticks(min, max, major_tick, minor_tick) do
    {min_limit, max_limit} = axis_limits(min, max, minor_tick)

    build_ticks(min_limit, minor_tick, max_limit, [min_limit])
    |> Enum.reverse
    |> Enum.map(fn tick_pos ->
      %TickY{
        pos: tick_pos,
        text: if tick_pos / major_tick == Float.floor(tick_pos / major_tick) do
            Integer.to_string(trunc(tick_pos))
          else
            nil
          end
      }
    end)
  end

  def build_ticks(val, step, stop, acc) do
    next_val = val + step
    if next_val == stop do
      [next_val | acc]
    else
      build_ticks(next_val, step, stop, [next_val | acc])
    end
  end
end
