defmodule Wspom.Books.Context do

  # import Ecto.Changeset

  alias Wspom.Book

  @doc """
  Returns all records from the database.

  ## Examples

      iex> get_all_records()
      [%Book{}]
  """
  def get_all_records do
    # Database.get_all_records()
    [%Book{id: 1, title: "Singularity is Nearer", short_title: "Singularity",
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
      started_date: ~D[2025-03-28], finished_date: nil}]
  end
end
