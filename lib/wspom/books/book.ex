defmodule Wspom.Book do
  alias Wspom.Book
  alias Wspom.BookLen

  import Ecto.Changeset

  # For the explanation of the :length field, see book_len.ex.
  # :medium can be: :book, :audiobook, :ebook, :comics.
  # :status can be: :new, :active, :finished, :on_hold, :abandoned.
  # :history is a list containing both reading history and status history.
  # See book_history.ex for more information.
  # The date fields are calculated, not directly editable; they can both
  # be nil; :started_date will be nil in the rare cases of books that
  # were started being read before they were added to the database.
  defstruct [:id, :title, :short_title, :author, length: BookLen.new_pages(0),
    medium: :book, is_fiction: true, status: :active,
    started_date: nil, finished_date: nil, history: []]

  # These types are only used for changeset validation.
  # These are the types that will be visible and editable in the form.
  # They are different that what will be saved to the database.
  # See https://hexdocs.pm/ecto/Ecto.Schema.html#module-types-and-castin
  @types %{id: :integer, title: :string, short_title: :string, author: :string,
    length: :string, medium: :string, is_fiction: :boolean, status: :string}

  # Creates and validates a changeset - only used to validate the form.
  def changeset(book, attrs) do
    {book, @types}
    |> cast(attrs, [:id, :title, :short_title, :author, :length, :medium, :is_fiction])
    |> validate_required([:title, :short_title, :author, :length, :medium, :is_fiction])
    |> validate_book_length(:length, :valid_length)
  end

  # In addition to validating the length field (entered as a string),
  # this function will also put the value as %BookLen{} into field
  # `db_field` of the changeset.
  defp validate_book_length(%Ecto.Changeset{} = changeset, str_field, db_field) do
    with {:ok, length_str} <- changeset |> Ecto.Changeset.fetch_change(str_field) do
      case BookLen.parse_str(length_str) do
        {:ok, length_parsed} ->
          changeset |> Ecto.Changeset.put_change(db_field, length_parsed)
        {:error, error} ->
          changeset |> Ecto.Changeset.add_error(str_field, error)
      end
    else
      _ -> changeset
    end
  end

  def new() do
    %Book{title: "", short_title: "", author: "", length: BookLen.new_pages(0)}
  end

  @doc """
  Updates a book if the changeset is valid.
  Returns {:ok, %Book{}} or {:error, %Ecto.Changeset{}}.
  Notes:
   - changeset.data contains the original book (type: %Book{})
   - changeset.changes contains a map containing the changes,
     e.g. %{title: "Kajko i Kokosz", author: "Christa"}
  """
  def update_book(%Ecto.Changeset{valid?: false} = cs) do
    {:error, cs}
  end
  def update_book(%Ecto.Changeset{data: book, changes: changes} = changeset) do
    # Go over all changes and update the book for each of them - or throw an error
    case Enum.reduce(changes, {:continue, book}, &update_field/2) do
      {:error, {field, error}} ->
        {:error, changeset |> Ecto.Changeset.add_error(field, error)}
      {:continue, new_book} ->
        # We may need to handle length here… We'll see.
        # new_book = %Book{new_book | date: new_date, weekday: Timex.weekday(new_date)}
        {:ok, new_book}
    end
  end

  # Used by Enum.reduce() to go over a map of field changes.
  # The first argument is a tuple with {field_name, new_value}.
  # The second argument is the accumulator - one of:
  #   {:continue, %Book{}}
  #   {:error, message} (where 'message' is a string)
  # Returns the new accumulator.
  defp update_field(_, {:error, _} = error) do
    # Once an error has been encountered, ignore all subsequent changes.
    error
  end
  # "Enum" fields will require special handling; skip for now
  defp update_field({field_name, field_value}, {:continue, %Book{} = book}) do
    {:continue, book |> Map.put(field_name, field_value)}
  end
end
