defmodule Wspom.Books.Context do

  alias Wspom.ReadingRecord
  alias Wspom.Book
  alias Wspom.Books.Database

  @doc """
  Returns a map with database stats.
  """
  def get_stats do
    Database.get_stats()
  end

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

  @doc """
  Creates a new book based on a map of changes made in a form,
  then saves it in the database.

  ## Examples

      iex> create_book(%{field: new_value, …})
      {:ok, %Book{...}}

      iex> create_book(%{field: bad_value, …})
      {:error, %Ecto.Changeset{}}
  """
  def create_book(params \\ %{}) do
    case Book.new()
    |> Book.changeset(params)
    |> Book.update_book() do
      {:error, _changeset} = err ->
        err
      {:ok, updated_book} ->
        saved_book = Database.add_book_and_save(updated_book)
        {:ok, saved_book}
    end
  end

  @doc """
  Updates a book and saves it in the database.
  The `book` argument is the original, unmodified book (%Book{}).
  The `params` argument is a map containing all the values from the form.

  ## Examples

      iex> update_book(book, %{field: new_value})
      {:ok, %Book{...}}

      iex> update_book(book, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_book(book, params) do
    case book
    |> Book.changeset(params)
    |> Book.update_book() do
      {:error, _changeset} = err ->
        err
      {:ok, updated_book} ->
        saved_book = Database.replace_book_and_save(updated_book)
        {:ok, saved_book}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking changes to reading records.
  This function is invoked every time a field in the form changes.
  `book` is the book that this reading record will be a part of.

  ## Examples

      iex> change_reading_record(record, book)
      %Ecto.Changeset{data: %ReadingRecord{}}

  """
  def change_reading_record(%ReadingRecord{} = record, %Book{} = book, attrs \\ %{}) do
    ReadingRecord.changeset(record, book, attrs)
  end

  @doc """
  Creates a new reading record based on a map of changes made in a form,
  then saves it in the database.
  `book` is the book that this record will be a part of.

  ## Examples

      iex> create_reading_record(%{field: new_value, …})
      {:ok, %ReadingRecord{...}}

      iex> create_reading_record(%{field: bad_value, …})
      {:error, %Ecto.Changeset{}}
  """
  def create_reading_record(%Book{} = book, params \\ %{}) do
    ReadingRecord.new_form_data(book.id)
    |> ReadingRecord.changeset(book, params)
    |> save_reading_record(book, &Database.add_reading_record_and_save/2)
  end

  @doc """
  Updates an existing reading record and saves it in the database.
  `record` is the original, unmodified record (of type %ReadingRecord{}).
  `book` is the book that this record will be a part of.
  `params` is a map containing all the values from the form.

  ## Examples

      iex> update_reading_record(record, book, %{field: new_value})
      {:ok, %ReadingRecord{}}

      iex> update_reading_record(record, book, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_reading_record(%ReadingRecord{} = record, %Book{} = book, params) do
    record
    |> ReadingRecord.changeset(book, params)
    |> save_reading_record(book, &Database.replace_reading_record_and_save/2)
  end

  defp save_reading_record(%Ecto.Changeset{} = changeset, %Book{} = book, save_fn) do
    case changeset |> ReadingRecord.update() do
      {:error, _changeset} = err ->
        err
      {:ok, updated_record, changeset} ->
        # We are not validating if the reading position fits into the
        # reading history every time the user types a character in the
        # form. It's too calculation-intensive. Instead, we're doing it
        # here, when the user clicks the Save button.
        case updated_record |> ReadingRecord.validate_with_book_history(book) do
          :ok ->
            saved_record = save_fn.(updated_record, book)
            {:ok, saved_record}
          {:error, error} ->
            {:error, changeset |> Ecto.Changeset.add_error(:position, error)}
        end
    end
  end
end
