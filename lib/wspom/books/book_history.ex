defmodule Wspom.BookHistory do

  alias Wspom.BookHistory
  alias Wspom.BookLen

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
  # See https://hexdocs.pm/ecto/Ecto.Schema.html#module-types-and-castin
  @types %{id: :integer, book_id: :integer, date: :string,
    type: :string, position: :string}

  # Creates and validates a changeset - only used to validate the form.
  def changeset(history, attrs) do
    {history, @types}
    |> cast(attrs, [:id, :book_id, :date, :type, :position])
    |> validate_required([:book_id, :date, :type, :position])
    |> validate_inclusion(:type, ["read", "updated", "skipped"])
    |> BookLen.validate(:position)
  end

  # Returns a new book progress object with a `nil` id and with `date`
  # defaulted to today, formatted as string. The position defaults to ""
  # to make it easier on the form. This is the data structure expected
  # by the form component - not the data structure to be saved in the database.
  def new_form_data() do
    %BookHistory{id: nil, book_id: nil, date: Utils.date_now(),
      type: :read, position: ""}
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
        # At this point, new_book_history.position is a string -
        # but it's already been validated so it should have no errors
        case BookLen.parse_str(new_book_history.position) do
          {:ok, position_parsed} ->
            {:ok, %BookHistory{new_book_history | position: position_parsed}}
          {:error, error} ->
            # We should never get to this code (because the record
            # should have already been validated) but I will include it
            # for completness sake
            {:error, changeset |> Ecto.Changeset.add_error(:position, error)}
        end
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
    # Safe to do because the values of :type have already been validated
    {:continue, book_history |> Map.put(:type, String.to_atom(field_value))}
  end
  defp update_field({field_name, field_value}, {:continue, %BookHistory{} = book_history}) do
    {:continue, book_history |> Map.put(field_name, field_value)}
  end
end
