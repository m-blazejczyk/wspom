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
end
