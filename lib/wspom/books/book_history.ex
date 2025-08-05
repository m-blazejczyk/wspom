defmodule Wspom.BookHistory do

  alias Ecto.Changeset
  alias Wspom.{BookHistory, BookLen, Book}, warn: false

  import Ecto.Changeset

  # This data type is extremely simple but flexible in order to
  # accomodate any type of information that would need to be tracked.
  # This may be an overkill but, hey…
  #
  # We need the id because these records will be editable in a form.
  # :id is unique within the book's reading history, not globally.
  #
  # :book_id is not strictly necessary but it will allow us to build
  # forms where the book will be selectable from a dropdown.
  #
  # :date is a Date object.
  #
  # :type can be one of:
  # - :read - :position should contain the current position in the book
  # - :updated - same as above but this one is used to bulk-advance the
  #   current reading position in situations when detailed reading history
  #   is not available; in other words, the pages were read but not
  #   on the date indicated but over time
  # - :skipped - same as above but to advance the current reading position
  #   to indicate pages that were not read, i.e. that were skipped
  # - We do not track any other changes to the book, e.g. statuses.
  defstruct [:id, :book_id, :date, :type, :position]

  # These types are only used for changeset validation for forms.
  # These are the types that will be visible and editable in the form.
  # They are different that what will be saved to the database.
  # Marking a field as type :date kicks off the appropriate vallidation
  # in `cast()`.
  # See https://hexdocs.pm/ecto/Ecto.Schema.html#module-types-and-castin
  @types %{id: :integer, book_id: :integer, date: :date,
    type: :string, position: BookLen}

  # Creates and validates a changeset - only used to validate the form.
  # `book` is the book that this history record will be a part of.
  def changeset(%BookHistory{} = history, %Book{} = book, attrs) do
    {history, @types}
    |> cast(attrs, [:id, :book_id, :date, :type, :position])
    |> validate_required([:book_id, :date, :type, :position])
    |> validate_inclusion(:type, ["read", "updated", "skipped"])
    |> validate_with_book(book)
    |> validate_with_book_history(book)
  end

  def validate_with_book(%Ecto.Changeset{valid?: false} = changeset, _) do
    changeset
  end
  def validate_with_book(%Ecto.Changeset{} = changeset, %Book{} = book) do
    # At this stage, we have no access to the updated history record.
    # We have to rely on what's in the `changes` field.
    if book.status in [:finished, :abandoned] do
      # Book status validation
      changeset |> Ecto.Changeset.add_error(:position,
        "Not allowed to log progress on a book that is finished or abandoned.")
    else
      case changeset |> Changeset.fetch_change(:position) do
        {:ok, new_position} ->
          if new_position.len_type != book.length.len_type do
            # Position type must be the same as the books
            changeset |> Ecto.Changeset.add_error(:position,
              "Please enter the position as #{BookLen.type_to_string(book.length.len_type)}.")
          else
            if BookLen.to_comparable_int(new_position) > BookLen.to_comparable_int(book.length) do
              # Position must be less than book length
              changeset |> Ecto.Changeset.add_error(:position,
                "Position is located past the length of this book (#{BookLen.to_string(book.length)}).")
            else
              changeset
            end
          end
        :error ->
          # Position hasn't changed - assume it's correct
          changeset
      end
    end
  end

  def validate_with_book_history(%Ecto.Changeset{valid?: false} = changeset, _) do
    changeset
  end
  def validate_with_book_history(%Ecto.Changeset{} = changeset, %Book{} = book) do
    # At this stage, we have no access to the updated history record.
    # We have to rely on what's in the `changes` field.

    # Get the BookHistory record representing the new / changed record.
    {:ok, position} = changeset |> update()

    monotonous = position
    # Integrate it into the history list of the book.
    |> add_to_history(book.history)
    # Sort by position. The given function should compare two arguments, and return true if
    # the first argument precedes or is in the same place as the second one.
    |> Enum.sort(fn h1, h2 ->
      BookLen.to_comparable_int(h1.position) <= BookLen.to_comparable_int(h2.position) end)
    # Check if the dates are monotonous.
    |> monotonous?()

    if monotonous do
      changeset
    else
      changeset |> Ecto.Changeset.add_error(:position,
        "Invalid date for this position.")
    end
  end

  # This gets called when a new history record is added.
  defp add_to_history(%BookHistory{id: nil} = position, history) do
    [position | history]
  end
  # This gets called when a history record is edited.
  defp add_to_history(%BookHistory{id: id} = position, history) do
    idx = history |> Enum.find_index(&(&1.id == id))
    history |> List.replace_at(idx, position)
  end

  defp monotonous?(history) do
    {_, is_monotonous} = history
    |> Enum.reduce({List.first(history).date, true}, &monotonous_reducer/2)

    is_monotonous
  end

  defp monotonous_reducer(_position, {_prev_date, false} = acc) do
    acc
  end
  defp monotonous_reducer(%BookHistory{} = position, {prev_date, true}) do
    # `compare` returns :gt if first date is later than the second.
    # If that happens, we'll set the second element of the tuple to `false`.
    {position.date, Date.compare(prev_date, position.date) != :gt}
  end

  # Returns a new book progress object with a `nil` id and with `date`
  # defaulted to today, formatted as string. The position defaults to ""
  # to make it easier on the form. This is the data structure expected
  # by the form component - not the data structure to be saved in the database.
  def new_form_data() do
    %BookHistory{id: nil, book_id: nil, date: Utils.date_now(),
      type: :read, position: nil}
  end

  @doc """
  Updates a book history record if the changeset is valid.
  Returns {:ok, %BookHistory{}} or {:error, %Ecto.Changeset{}}.
  Notes:
   - changeset.data contains the original record (type: %BookHistory{})
   - changeset.changes contains a map containing the changes,
     e.g. %{date: "2025-05-16", type: :skipped}
  """
  def update(%Ecto.Changeset{valid?: false} = cs) do
    {:error, cs}
  end
  def update(%Ecto.Changeset{data: book_history, changes: changes} = changeset) do
    # Go over all changes and update the record for each of them -
    # or add an error to the changeset
    case Enum.reduce(changes, {:continue, book_history}, &update_field/2) do
      {:error, {field, error}} ->
        {:error, changeset |> Ecto.Changeset.add_error(field, error)}
      {:continue, new_book_history} ->
        {:ok, new_book_history}
    end
  end

  # Used by Enum.reduce() to go over a map of field changes.
  # The first argument is a tuple with {field_name, new_value}.
  # The second argument is the accumulator - one of:
  #   {:continue, %BookHistory{}}
  #   {:error, message} (where 'message' is a string)
  # Returns the new accumulator.
  defp update_field(_, {:error, _} = error) do
    # Once an error has been encountered, ignore all subsequent changes.
    error
  end
  defp update_field({:type, field_value}, {:continue, %BookHistory{} = book_history}) do
    # Safe to call `to_atom` because the values of :type have already
    # been validated
    {:continue, book_history |> Map.put(:type, String.to_atom(field_value))}
  end
  defp update_field({field_name, field_value}, {:continue, %BookHistory{} = book_history}) do
    {:continue, book_history |> Map.put(field_name, field_value)}
  end
end
