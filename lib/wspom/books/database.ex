defmodule Wspom.Books.Database do
  use Agent
  require Logger

  alias Wspom.DbBase
  alias Wspom.Book

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
    [
      %Book{id: 1, title: "Singularity is Nearer", short_title: "Singularity",
      author: "Kurtzweil", length: {:time, 9, 36},
      medium: :audiobook, is_fiction: false, status: :finished,
      started_date: ~D[2025-02-10], finished_date: ~D[2025-04-21]},
      %Book{id: 2, title: "There is Hope", short_title: "There is Hope",
      author: "Chomsky", length: {:pages, 228},
      medium: :book, is_fiction: false, status: :abandoned,
      started_date: ~D[2025-01-10], finished_date: ~D[2025-03-06]},
      %Book{id: 3, title: "Folly of Realism", short_title: "Folly of Realism",
      author: "Some Guy", length: {:pages, 180},
      medium: :book, is_fiction: false, status: :finished,
      started_date: ~D[2024-12-28], finished_date: ~D[2025-03-21]},
      %Book{id: 4, title: "Havana Connection", short_title: "Havana",
      author: "Viau", length: {:pages, 240},
      medium: :book, is_fiction: true, status: :active,
      started_date: ~D[2025-05-02], finished_date: nil},
      %Book{id: 5, title: "Sad Planets", short_title: "Sad Planets",
      author: "Eugene Thacker", length: {:pages, 325},
      medium: :book, is_fiction: false, status: :active,
      started_date: ~D[2025-03-28], finished_date: nil}
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

  # Will return nil if the book is not found.
  def get_book(id) do
    Agent.get(__MODULE__, fn %{books: books} ->
      books |> Enum.find(fn book -> book.id == id end)
    end)
  end

  def get_all_books() do
    Agent.get(__MODULE__, fn %{books: books} -> books end)
  end
end
