defmodule Wspom.Books.Database do
  use Agent
  require Logger

  alias Wspom.BookHistory
  alias Wspom.DbBase
  alias Wspom.Book
  alias Wspom.BookLen

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
    fake_history = [
      %BookHistory{id: 1, book_id: 5, date: ~D[2025-03-28], type: :read,
        position: BookLen.new_pages(12)},
      %BookHistory{id: 2, book_id: 5, date: ~D[2025-03-29], type: :read,
        position: BookLen.new_pages(18)},
      %BookHistory{id: 3, book_id: 5, date: ~D[2025-03-30], type: :read,
        position: BookLen.new_pages(29)},
      %BookHistory{id: 4, book_id: 5, date: ~D[2025-04-08], type: :updated,
        position: BookLen.new_pages(82)},
      %BookHistory{id: 5, book_id: 5, date: ~D[2025-04-09], type: :read,
        position: BookLen.new_pages(95)},
      %BookHistory{id: 6, book_id: 5, date: ~D[2025-04-10], type: :read,
        position: BookLen.new_pages(112)},
    ]

    [
      %Book{id: 1, title: "Singularity is Nearer", short_title: "Singularity",
      author: "Kurtzweil", length: BookLen.new_time(9, 36),
      medium: :audiobook, is_fiction: false, status: :finished,
      started_date: ~D[2025-02-10], finished_date: ~D[2025-04-21]},
      %Book{id: 2, title: "There is Hope", short_title: "There is Hope",
      author: "Chomsky", length: BookLen.new_pages(228),
      medium: :book, is_fiction: false, status: :abandoned,
      started_date: ~D[2025-01-10], finished_date: ~D[2025-03-06]},
      %Book{id: 3, title: "Folly of Realism", short_title: "Folly of Realism",
      author: "Some Guy", length: BookLen.new_pages(180),
      medium: :book, is_fiction: false, status: :finished,
      started_date: ~D[2024-12-28], finished_date: ~D[2025-03-21]},
      %Book{id: 4, title: "Havana Connection", short_title: "Havana",
      author: "Viau", length: BookLen.new_percent(100),
      medium: :book, is_fiction: true, status: :active,
      started_date: ~D[2025-05-02], finished_date: nil},
      %Book{id: 5, title: "Sad Planets", short_title: "Sad Planets",
      author: "Eugene Thacker", length: BookLen.new_pages(325),
      medium: :book, is_fiction: false, status: :active,
      started_date: ~D[2025-03-28], finished_date: nil,
      history: fake_history}
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
    IO.inspect(updated_book, label: "BOOK")
    modify_and_save_data(updated_book, fn books, book ->
      {books |> DbBase.find_and_replace([], book), book}
    end)
  end

  def add_book_history_and_save(new_book_history) do
    Logger.notice("Saving the new book history record…")
    IO.inspect(new_book_history, label: "RECORD")
    # modify_and_save_data(new_book_history, fn book_historys, book_history ->
    #   max_id = DbBase.find_max_id(book_historys)
    #   new_book_history = %{book_history | id: max_id + 1}
    #   {[new_book_history | book_historys], new_book_history}
    # end)
  end

  def replace_book_history_and_save(updated_book_history) do
    Logger.notice("Saving the modified book history record…")
    IO.inspect(updated_book_history, label: "RECORD")
    # modify_and_save_data(updated_book_history, fn book_historys, book_history ->
    #   {book_historys |> DbBase.find_and_replace([], book_history), book_history}
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
