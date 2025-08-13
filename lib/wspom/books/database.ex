defmodule Wspom.Books.Database do
  use Agent
  require Logger

  alias Wspom.ReadingRecord
  alias Wspom.DbBase
  alias Wspom.Book
  alias Wspom.BookPos

  @db_file "books.dat"
  @db_file_backup "books.bak.dat"


  def start_link([is_production: is_production]) do
    Agent.start_link(fn -> init_state(is_production) end, name: __MODULE__)
  end

  defp init_state(is_production) do
    if is_production do
      DbBase.load_db_file(@db_file, &init_db/0)
      |> maybe_migrate_and_save()
      |> summarize_db()
    else
      books = fake_data()
      %{
        books: books,
        version: 1,
        is_production: false,
      }
      |> summarize_db()
    end
  end

  defp init_db() do
    %{
      books: [],
      version: 1,
      is_production: true,
    }
  end

  defp fake_data do
    singularity_history = [
      %ReadingRecord{id: 1, book_id: 1, date: ~D[2025-02-10], type: :read,
        position: BookPos.new_time(3, 11)},
      %ReadingRecord{id: 2, book_id: 1, date: ~D[2025-03-17], type: :read,
        position: BookPos.new_time(6, 25)},
      %ReadingRecord{id: 3, book_id: 1, date: ~D[2025-04-21], type: :read,
        position: BookPos.new_time(9, 36)},
    ] |> Enum.reverse()
    hope_history = [
      %ReadingRecord{id: 1, book_id: 2, date: ~D[2025-01-10], type: :read,
        position: BookPos.new_pages(21)},
      %ReadingRecord{id: 2, book_id: 2, date: ~D[2025-01-12], type: :read,
        position: BookPos.new_pages(36)},
      %ReadingRecord{id: 3, book_id: 2, date: ~D[2025-01-15], type: :read,
        position: BookPos.new_pages(47)},
      %ReadingRecord{id: 4, book_id: 2, date: ~D[2025-03-06], type: :skipped,
        position: BookPos.new_pages(228)},
    ] |> Enum.reverse()
    realism_history = [
      %ReadingRecord{id: 1, book_id: 3, date: ~D[2024-12-28], type: :read,
        position: BookPos.new_pages(18)},
      %ReadingRecord{id: 2, book_id: 3, date: ~D[2025-01-01], type: :read,
        position: BookPos.new_pages(27)},
      %ReadingRecord{id: 3, book_id: 3, date: ~D[2025-01-28], type: :updated,
        position: BookPos.new_pages(92)},
      %ReadingRecord{id: 4, book_id: 3, date: ~D[2025-02-18], type: :updated,
        position: BookPos.new_pages(161)},
      %ReadingRecord{id: 5, book_id: 3, date: ~D[2025-03-02], type: :read,
        position: BookPos.new_pages(180)},
    ] |> Enum.reverse()
    havana_history = [
      %ReadingRecord{id: 1, book_id: 4, date: ~D[2025-05-02], type: :read,
        position: BookPos.new_percent(12)},
      %ReadingRecord{id: 2, book_id: 4, date: ~D[2025-05-03], type: :read,
        position: BookPos.new_percent(19)},
      %ReadingRecord{id: 3, book_id: 4, date: ~D[2025-05-04], type: :read,
        position: BookPos.new_percent(30)},
      %ReadingRecord{id: 4, book_id: 4, date: ~D[2025-05-05], type: :read,
        position: BookPos.new_percent(41)},
      %ReadingRecord{id: 5, book_id: 4, date: ~D[2025-05-07], type: :read,
        position: BookPos.new_percent(55)},
    ] |> Enum.reverse()
    sad_planets_history = [
      %ReadingRecord{id: 1, book_id: 5, date: ~D[2025-04-10], type: :read,
        position: BookPos.new_pages(112)},
      %ReadingRecord{id: 2, book_id: 5, date: ~D[2025-04-09], type: :read,
        position: BookPos.new_pages(95)},
      %ReadingRecord{id: 3, book_id: 5, date: ~D[2025-04-08], type: :updated,
        position: BookPos.new_pages(82)},
      %ReadingRecord{id: 4, book_id: 5, date: ~D[2025-03-30], type: :read,
        position: BookPos.new_pages(29)},
      %ReadingRecord{id: 5, book_id: 5, date: ~D[2025-03-29], type: :read,
        position: BookPos.new_pages(18)},
      %ReadingRecord{id: 6, book_id: 5, date: ~D[2025-03-28], type: :read,
        position: BookPos.new_pages(12)},
    ]

    [
      %Book{id: 1, title: "Singularity is Nearer", short_title: "Singularity",
      author: "Kurtzweil", length: BookPos.new_time(9, 36),
      medium: :audiobook, is_fiction: false, status: :finished,
      started_date: ~D[2025-02-10], finished_date: ~D[2025-04-21],
      history: singularity_history},
      %Book{id: 2, title: "There is Hope", short_title: "There is Hope",
      author: "Chomsky", length: BookPos.new_pages(228),
      medium: :book, is_fiction: false, status: :abandoned,
      started_date: ~D[2025-01-10], finished_date: ~D[2025-03-06],
      history: hope_history},
      %Book{id: 3, title: "Folly of Realism", short_title: "Folly of Realism",
      author: "Some Guy", length: BookPos.new_pages(180),
      medium: :book, is_fiction: false, status: :finished,
      started_date: ~D[2024-12-28], finished_date: ~D[2025-03-02],
      history: realism_history},
      %Book{id: 4, title: "Havana Connection", short_title: "Havana",
      author: "Viau", length: BookPos.new_percent(100),
      medium: :book, is_fiction: true, status: :active,
      started_date: ~D[2025-05-02], finished_date: nil,
      history: havana_history},
      %Book{id: 5, title: "Sad Planets", short_title: "Sad Planets",
      author: "Eugene Thacker", length: BookPos.new_pages(325),
      medium: :book, is_fiction: false, status: :active,
      started_date: ~D[2025-03-28], finished_date: nil,
      history: sad_planets_history}
    ]
  end

  defp maybe_migrate_and_save(%{version: _current_version} = state) do
    state
  end

  defp summarize_db(%{books: books, version: version} = state) do
    Logger.notice("### Books database version #{version} ###")
    Logger.notice("### #{length(books)} books ###")
    state
  end

  def get_stats do
    Agent.get(__MODULE__, fn %{books: books} ->
      %{books: length(books)}
    end)
  end

  # Will return nil if the book is not found.
  def get_book(id) do
    Agent.get(__MODULE__, fn %{books: books} ->
      books |> Enum.find(fn book -> book.id == id end)
    end)
  end

  def get_all_books() do
    Agent.get(__MODULE__, fn %{books: books} -> books end)
  end

  def add_book_and_save(created_book) do
    Logger.notice("Saving a new book…")
    modify_and_save_data(created_book, fn books, book ->
      max_id = DbBase.find_max_id(books)
      new_book = %{book | id: max_id + 1}
      {[new_book | books], new_book}
    end)
  end

  def replace_book_and_save(updated_book) do
    Logger.notice("Saving the modified book…")
    modify_and_save_data(updated_book, fn books, book ->
      {books |> DbBase.find_and_replace([], book), book}
    end)
  end

  def add_reading_record_and_save(new_record) do
    Logger.notice("Saving the new reading record…")
    IO.inspect(new_record, label: "NEW READING RECORD")
    # modify_and_save_data(new_record, fn records, record ->
    #   max_id = DbBase.find_max_id(records)
    #   new_record = %{record | id: max_id + 1}
    #   {[new_record | records], new_record}
    # end)
  end

  def replace_reading_record_and_save(updated_record) do
    Logger.notice("Saving the modified reading record…")
    IO.inspect(updated_record, label: "UPDATED READING RECORD")
    # modify_and_save_data(updated_record, fn records, record ->
    #   {records |> DbBase.find_and_replace([], record), record}
    # end)
  end

  def modify_and_save_data(book, update_fun) do
    Agent.get_and_update(__MODULE__,
      fn %{books: books, is_production: is_prod} = state ->
        {new_books, new_book} = update_fun.(books, book)
        new_state = %{state | books: new_books}

        if is_prod do
          new_state |> DbBase.save_db_file(@db_file, @db_file_backup)
        end

        {new_book, new_state}
      end)
  end
end
