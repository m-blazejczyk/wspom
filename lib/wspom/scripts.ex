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
  #   entries = Wspom.Scripts.read_text("/home/michal/Documents/Wspom/wspom2026.toimport.txt", 2026); 0
  #
  # This will produce a list of error messages or a statement that the data is ok.
  # Then call:
  #   Wspom.Entries.Database.append_entries_and_save(entries)
  #
  # IMPORTANT:
  # - The file must not start with "------"
  # - Weekday abbreviations must be removed from entry headers
  # - Combining multiple days into an entry is not allowed
  # - After deleting wspom.dat and starting the app, the database will be
  #   seeded with 5 random entries
  #
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

  def yearly_book_stats(year) do
    books = Wspom.Books.Context.get_all_books()

    {_len_per_type, _total_book_cnt} = books
    |> Enum.reduce({%{}, 0}, fn book, {types, book_cnt} ->
      {new_types, this_year?, _} = one_book_stats(book, year, types)
      if this_year? do
        key = {book.medium, book.is_fiction}
        {
          new_types
          |> Map.update!(key, fn {len, c} -> {len, c + 1} end),
          book_cnt + 1
        }
      else
        {new_types, book_cnt}
      end
    end)
  end

  defp one_book_stats(%Wspom.Book{} = book, year, start_types) do
    start_acc = {start_types, false, BookPos.new_empty(book.length.type)}

    book.history
    |> Enum.reverse
    |> Enum.reduce(start_acc, fn rec, {types, this_year?, prev_pos} ->
      if rec.date.year == year and rec.type != :skipped and rec.position.type != :percent do
        key = {book.medium, book.is_fiction}
        amount = BookPos.subtract(rec.position, prev_pos)
        new_types = types
        |> Map.update(key, {amount, 0}, fn {prev_len, v} ->
          {BookPos.add(prev_len, amount), v}
        end)
        {new_types, true, rec.position}
      else
        {types, this_year?, rec.position}
      end
    end)
  end
end
