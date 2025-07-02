defmodule Wspom.Books.Context do

  alias Wspom.Book
  alias Wspom.Books.Database

  @doc """
  Returns all books from the database.

  ## Examples

      iex> get_all_books()
      [%Book{}]
  """
  def get_all_books do
    Database.get_all_books()
  end

  @doc """
  Gets a single book by id. the id can be a string.

  Raises `Ecto.NoResultsError`if the Book does not exist.

  ## Examples

      iex> get_book!(123)
      %Entry{}

      iex> get_book!(456)
      ** (Ecto.NoResultsError)

  """
  def get_book!(id) when is_binary(id) do
    get_book!(String.to_integer(id))
  end
  def get_book!(id) when is_integer(id) do
    case book = Database.get_book(id) do
      %Book{} ->
        book
      _ ->
        raise Ecto.NoResultsError, message: "No book with id #{id}"
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking book changes.
  This function is invoked every time a field in the form changes.

  ## Examples

      iex> change_book(book)
      %Ecto.Changeset{data: %Book{}}

  """
  def change_book(book, attrs \\ %{}) do
    Book.changeset(book, attrs)
  end
end
