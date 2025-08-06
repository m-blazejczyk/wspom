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
    case ReadingRecord.new_form_data()
    |> ReadingRecord.changeset(book, params)
    |> ReadingRecord.update() do
      {:error, _changeset} = err ->
        err
      {:ok, updated_record} ->
        saved_record = Database.add_reading_record_and_save(updated_record)
        {:ok, saved_record}
    end
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
    case record
    |> ReadingRecord.changeset(book, params)
    |> ReadingRecord.update() do
      {:error, _changeset} = err ->
        err
      {:ok, updated_record} ->
        saved_record = Database.replace_reading_record_and_save(updated_record)
        {:ok, saved_record}
    end
  end
end
