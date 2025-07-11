defmodule Wspom.BookProgress do
  alias Wspom.BookProgress
  alias Wspom.BookLen

  import Ecto.Changeset

  # :id is within the book's reading history (not global)
  # :position is of type BookLen
  # We have a field for the book id for the forms where the book is selectable
  defstruct [:id, :book_id, :date, :position]

  # These types are only used for changeset validation.
  # These are the types that will be visible and editable in the form.
  # They are different that what will be saved to the database.
  # See https://hexdocs.pm/ecto/Ecto.Schema.html#module-types-and-castin
  @types %{id: :integer, book_id: :integer, date: :string, position: :string}

  # Creates and validates a changeset - only used to validate the form.
  def changeset(progress, attrs) do
    {progress, @types}
    |> cast(attrs, [:id, :book_id, :date, :progress])
    |> validate_required([:book_id, :date, :progress])
    |> BookLen.validate(:progress)
  end

  # Returns a new book progress object with a `nil` id and with `date`
  # defaulted to today, formatted as string. The position defaults to ""
  # to make it easier on the form. This is the data structure expected
  # by the form component - not the data structure to be saved in the database.
  def new_form_data() do
    %BookProgress{id: nil, book_id: nil, date: Utils.date_now(), position: ""}
  end
end
