defmodule Wspom.Scripts do
  alias Wspom.{Book, ReadingRecord, BookPos}

  @doc """
  The code in this module should be executed from inside an iex session (iex -S mix)

  Examples:
  Wspom.Scripts.create_empty_entries_db("wspom2023.dat")
  entries = Wspom.Scripts.entries_from_json("wspom2023.json")
  Wspom.Database.append_entries_and_save(entries)
  """

  def entries_from_json(filename) do
    # We expect `json` to be a list of maps
    {:ok, json} = read_json(filename)

    json |> Enum.map(&entry_from_json(&1))
  end

  defp read_json(filename) do
    with {:ok, body} <- File.read(filename), {:ok, json} <- Poison.decode(body), do: {:ok, json}
  end

  defp entry_from_json(%{} = entry) do
    [from, to] = entry["dateRange"]
    {:ok, dt_from, _} = DateTime.from_iso8601(from)
    {:ok, dt_to, _} = DateTime.from_iso8601(to)
    date_from = dt_from |> DateTime.to_date()
    date_to = dt_to |> DateTime.to_date()

    %Wspom.Entry{
      # The id will be set by the database, not here
      id: nil,
      description: entry["entry"] |> String.trim(),
      title: entry["rawDate"],
      year: date_from.year,
      month: date_from.month,
      day: date_from.day,
      weekday: date_from |> Timex.weekday(),
      date: date_from,
      importance: :normal,
      fuzzy: Date.diff(date_to, date_from),
      needs_review: false,
      tags: MapSet.new([])
    }
  end

  def create_empty_entries_db(filename) do
    if File.exists?(filename) do
      IO.puts("File #{filename} already exists; skipping")
    else
      File.write!(
        filename,
        :erlang.term_to_binary(%{
          entries: [],
          version: Wspom.Entries.Migrations.current_version(),
          is_production: true
        })
      )

      IO.puts("File #{filename} created")
    end
  end

  @roman_lookup %{
    "i" => 1,
    "ii" => 2,
    "iii" => 3,
    "iv" => 4,
    "v" => 5,
    "vi" => 6,
    "vii" => 7,
    "viii" => 8,
    "ix" => 9,
    "x" => 10,
    "xi" => 11,
    "xii" => 12
  }

  # Create an empty database if needed:
  #   Wspom.Scripts.create_empty_entries_db("wspom.dat")
  #
  # Then:
  #   entries = Wspom.Scripts.read_text("/home/michal/Documents/Wspom/test.txt", 2025)
  # or:
  #   entries = Wspom.Scripts.read_text("/home/michal/Documents/Wspom/wspom2023.toimport.txt", 2023)
  #
  # Then call:
  #   Wspom.Entries.Database.append_entries_and_save(entries)
  def read_text(filename, year) do
    {entries_raw, _} =
      File.read!(filename)
      |> String.split("\n")
      |> Enum.map(&String.trim/1)
      |> Enum.chunk_while([], &chunker/2, &wrapup/1)
      |> Enum.map_reduce(year, &validate_entry/2)

    errors = entries_raw |> Enum.filter(&find_errors/1)

    if length(errors) > 0 do
      IO.puts("Errors encountered:")

      errors
      |> Enum.map(fn {:error, error} -> error end)
      |> Enum.each(&IO.puts/1)

      nil
    else
      IO.puts("Data is valid")

      entries_raw
      |> Enum.map(fn {date, title, description} -> Wspom.Entry.new(title, description, date) end)
    end
  end

  defp chunker(elem, acc) do
    # This looks for a line composed of two or more dashes;
    # when it finds one, the accumulator is emitted as a chunk
    # and a new, empty list is returned as the new accumulator
    if elem |> String.match?(~r/^-[-]+$/) do
      {:cont, Enum.reverse(acc), []}
    else
      # If it's not the dashes then add the line to the accumulator
      # but only if it is not empty
      if String.length(elem) > 0 do
        {:cont, [elem | acc]}
      else
        {:cont, acc}
      end
    end
  end

  # This function is called at the very end of the file
  # It simply emits the accumulator
  defp wrapup(acc), do: {:cont, Enum.reverse(acc), []}

  defp validate_entry([date_str | [title_raw | content]], year) do
    with {:ok, date} <- convert_roman_date(date_str, year),
         {:ok, title} <- validate_title(title_raw) do
      {{date, title, Enum.join(content, "\n\n")}, year}
    else
      {:error, error} -> {{:error, error}, year}
    end
  end

  # Returns a {:ok, Date} or {:error, "Error message"}
  defp convert_roman_date(date_str, year) do
    # This will throw an exception if `date_str` is not
    [day_str | [month_roman | []]] = date_str |> String.split(" ")

    with {day, ""} <- Integer.parse(day_str),
         {:ok, month} <- @roman_lookup |> Map.fetch(month_roman |> String.downcase()),
         {:ok, date} <- Date.new(year, month, day) do
      {:ok, date}
    else
      _ -> {:error, "Incorrect date: #{date_str}"}
    end
  end

  defp validate_title(title) do
    if String.length(title) > 60 do
      {:error, "Title too long: #{title}"}
    else
      {:ok, title}
    end
  end

  defp find_errors({:error, _}), do: true
  defp find_errors(_), do: false

  def load_books() do
    f = File.read!("books.json")
    {:ok, data} = Jason.decode(f)

    data
    |> Enum.map(fn raw ->
      %Book{
        id: raw["id"],
        title: raw["title"],
        short_title: raw["short_title"],
        author: raw["author"],
        length: handle_pos(raw["length"]),
        medium: handle_medium(raw["type"]),
        is_fiction: handle_bool(raw["is_fiction"]),
        status: handle_status(raw["status"]),
        started_date: handle_date(raw["start_date"]),
        finished_date: handle_date(raw["finish_date"])
      }
    end)
  end

  defp handle_date(""), do: nil
  defp handle_date(date_str), do: Date.from_iso8601!(date_str)

  defp handle_bool("TRUE"), do: true
  defp handle_bool("FALSE"), do: false

  defp handle_status("abandoned"), do: :abandoned
  defp handle_status("finished"), do: :finished
  defp handle_status("active"), do: :active

  defp handle_medium("Audiobook"), do: :audiobook
  defp handle_medium("Graphic Novel"), do: :comics
  defp handle_medium("Book"), do: :book
  defp handle_medium("Ebook"), do: :ebook

  defp handle_pos(pos) when is_integer(pos), do: BookPos.new_pages(pos)

  defp handle_pos(pos) when is_binary(pos) do
    {:ok, pos} = BookPos.parse_str(pos)
    pos
  end

  def load_reading_records() do
    f = File.read!("books-reading.json")
    {:ok, data} = Jason.decode(f)

    data
    |> Enum.map(fn raw ->
      %ReadingRecord{
        id: raw["record_id"],
        book_id: raw["book_id"],
        date: handle_date(raw["date"]),
        type: handle_type(raw["type"]),
        position: handle_pos(raw["position"])
      }
    end)
    |> Enum.group_by(& &1.book_id)
  end

  # -  - :position should contain the current position in the book
  # -  - same as above but this one is used to bulk-advance the
  #   current reading position in situations when detailed reading history
  #   is not available; in other words, the pages were read but not
  #   on the date indicated but over time
  # -  - same as above but to advance the current reading position
  defp handle_type("read"), do: :read
  defp handle_type("abandoned"), do: :skipped
  defp handle_type("skipped"), do: :updated

  def process_books() do
    books = load_books()
    rrs = load_reading_records()

    books_with_histories =
      books
      |> Enum.map(fn book ->
        %{book | history: Enum.reverse(rrs[book.id])}
      end)

    state = %{
      books: books_with_histories,
      version: 1,
      is_production: true
    }

    File.write!("books.dat", :erlang.term_to_binary(state))
  end

  def download_weather_data() do
    api_key = System.get_env("WL_KEY")
    api_secret = System.get_env("WL_SECRET")
    # {list, i} = Enum.map_reduce(1758340800..1758599999//86400, 1, fn ts, i ->
    {list, i} =
      Enum.map_reduce(1_621_031_400..1_758_855_600//86400, 1, fn ts, i ->
        data =
          HTTPoison.get!(
            "https://api.weatherlink.com/v2/historic/111045?api-key=" <>
              api_key <>
              "&start-timestamp=#{ts}&end-timestamp=#{ts + 86400}",
            [{"X-Api-Secret", api_secret}]
          )

        {:ok, json} = Poison.decode(data.body)
        data = atomize(json)

        :timer.sleep(150)
        if rem(i, 10) == 0, do: IO.write(".")
        {data, i + 1}
      end)

    IO.puts("")
    IO.puts("Data for #{i - 1} days was downloaded successfully.")
    list
  end

  def atomize(m) when is_map(m) do
    for {key, val} <- m, into: %{} do
      {String.to_atom(key), atomize(val)}
    end
  end
  def atomize(l) when is_list(l) do
    for item <- l, do: atomize(item)
  end
  def atomize(v), do: v

  def get_dates(day) do
    data = hd(day.sensors).data
    {hd(data).ts |> DateTime.from_unix!(), List.last(data).ts |> DateTime.from_unix!()}
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
      rain_size: data.rain_size,
      rainfall_in: data.rainfall_in,
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

  def check_linearity(days) do
    # The timestamps here should be the same as in download_weather_data()
    tss = 1_621_031_400..(1_758_855_600 + 86400)//900 |> Range.to_list() |> Map.from_keys(0)

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

  def linearize(days) do
    # Generate a list of timestamps where we expect data (every 15 minutes)
    # Make a map with those timestamps as keys
    tss = 1_621_031_400..(1_758_855_600 + 86400)//900 |> Range.to_list() |> Map.from_keys(%{})
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

    # The first timestamp will be 1621034100 (Friday, 14 May 2021 19:15:00 local time)
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
    data
    |> Enum.group_by(
      fn {k, _v} -> div(div(k - 1_621_034_100, 900), 4) end,
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

  # File.write!("../weather_6.dat", :erlang.term_to_binary(data))
  # data = File.read!("../weather_6.dat") |> :erlang.binary_to_term(); length(data)
end
