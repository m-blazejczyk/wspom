defmodule Wspom.Book do
  alias Ecto.Changeset
  alias Wspom.{Book, BookPos, BookStats}

  import Ecto.Changeset

  # For the explanation of the :length field, see book_len.ex.
  # :medium can be: :book, :audiobook, :ebook, :comics.
  # :status can be: :active, :finished, :abandoned.
  # :history is a list containing the reading history.
  # See reading_pos.ex for more information.
  # It is assumed (and enforced) that the :history field is sorted by
  # reading position, i.e. the most recently reading record is the first
  # element of the list. The list is sorted this way when saving a book.
  # The date fields are calculated, not directly editable; they can both
  # be nil; :started_date will be nil in the rare cases of books that
  # were started being read before they were added to the database.
  defstruct [:id, :title, :short_title, :author, length: nil,
    medium: :book, is_fiction: true, status: :active,
    started_date: nil, finished_date: nil, history: []]

  # These types are only used for changeset validation.
  # These are the types that will be visible and editable in the form.
  # They are different that what will be saved to the database.
  # See https://hexdocs.pm/ecto/Ecto.Schema.html#module-types-and-castin
  @types %{id: :integer, title: :string, short_title: :string, author: :string,
    length: BookPos, medium: :string, is_fiction: :boolean, status: :string}

  # Creates and validates a changeset - only used to validate the form.
  def changeset(book, attrs) do
    {book, @types}
    |> cast(attrs, [:id, :title, :short_title, :author, :length, :medium, :is_fiction])
    |> validate_required([:title, :short_title, :author, :length, :medium, :is_fiction])
    |> validate_inclusion(:medium, ["book", "audiobook", "ebook", "comics"])
    |> validate_book_length()
  end

  # defp validate_book_length(%Ecto.Changeset{valid?: false} = cs), do: cs
  # Validate the book length in the context of reading history:
  # * Can't change the length of a finished / abandoned book
  # * Can't change length to be smaller or equal than the farthest
  #   position read
  # * Can't change length type if there is any reading history
  defp validate_book_length(%Ecto.Changeset{} = changeset) do
    case changeset |> Changeset.fetch_change(:length) do
      :error ->
        changeset
      {:ok, new_length} ->
        if changeset.data.status != :active do
          changeset |> Changeset.add_error(:length,
            "Not allowed to modify the length of completed books")
        else
          if changeset.data.length && changeset.data.length.type != new_length.type do
            changeset |> Changeset.add_error(:length,
              "Not allowed to modify the length type of books with reading histories")
          else
            furthest_pos_int = changeset.data |> furthest_position_int()

            if BookPos.to_comparable_int(new_length) <= furthest_pos_int do
              changeset |> Changeset.add_error(:length,
                "Length must be greater than the furthest reading position")
            else
              changeset
            end
          end
        end
    end
  end

  def new() do
    %Book{title: "", short_title: "", author: "", length: nil}
  end

  def furthest_position_int(%Book{history: []}), do: 0
  def furthest_position_int(%Book{history: [latest | _rest]}) do
    latest.position |> BookPos.to_comparable_int()
    # Enum.reduce(0, fn record, max_pos -> max(max_pos, record.position |> BookPos.to_comparable_int()) end)
  end

  def percent_finished(%Book{status: :finished}), do: 100.0
  def percent_finished(%Book{status: :abandoned}), do: 100.0
  def percent_finished(%Book{length: length} = book) do
    furthest_position_int(book) / BookPos.to_comparable_int(length) * 100.0
  end

  def find_reading_record(%Book{} = book, record_id) when is_binary(record_id) do
    find_reading_record(book, String.to_integer(record_id))
  end
  def find_reading_record(%Book{} = book, record_id) when is_integer(record_id) do
    book.history |> Enum.find(&(&1.id == record_id))
  end

  def last_read_date(%Book{history: []}), do: "Never"
  def last_read_date(%Book{history: [last | _]}), do: last.date

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
  defp update_field({:medium, field_value}, {:continue, %Book{} = book}) do
    # Safe to do because the values of :medium have already been validated
    {:continue, book |> Map.put(:medium, String.to_atom(field_value))}
  end
  defp update_field({field_name, field_value}, {:continue, %Book{} = book}) do
    {:continue, book |> Map.put(field_name, field_value)}
  end

  def delete_reading_record(%Book{history: []}, _record_id) do
    {:error, "Can't delete a reading record from a book with no reading history ;)"}
  end
  def delete_reading_record(%Book{history: [last | rest]} = book, record_id) do
    # Check if this record id exists and if it's the last one in the book
    if last.id == record_id do
      {:ok, %{book | history: rest}}
    else
      {:error, "Only allowed to delete the last record from the reading history"}
    end
  end

  def maybe_complete_book(%Book{history: []} = book), do: book
  def maybe_complete_book(%Book{status: status} = book)
    when status != :active, do: book
  def maybe_complete_book(%Book{history: [last | _rest]} = book) do
    if BookPos.to_comparable_int(last.position) >= BookPos.to_comparable_int(book.length) do
      new_status = case last.type do
        :read -> :finished
        :updated -> :finished
        :skipped -> :abandoned
      end
      %{book | status: new_status, finished_date: last.date}
    else
      book
    end
  end

  def maybe_start_book(%Book{status: :active, history: [first]} = book) do
    %{book | started_date: first.date}
  end
  def maybe_start_book(%Book{} = book), do: book

  @doc """
  Returns: Wspom.BookStats or :empty.

  Definitions:
  * :days - number of days between the earliest record of type :read
    and the latest record NOT of type :skipped, plus 1
  * :sessions - number of reading records of type :read
  * :per_day - excludes :skipped
  * :per_session - excludes :skipped and :updated
  """
  def calculate_stats(%Book{history: []}), do: :empty
  def calculate_stats(%Book{history: history} = book) do
    history_ordered = history |> Enum.reverse

    # history_ordered |> Enum.find(fn rec -> rec.type == :read end)  # Check nil!
    first_day = book.started_date
    last_day = book.finished_date || Utils.date_now
    days = Date.diff(first_day, last_day) + 1

    {sessions, sessions_length, longest, _prev_pos} = history_ordered
    |> Enum.reduce({0, 0, 0, 0}, fn rec, {cnt, len, max_len, prev} ->
      pos = rec.position |> BookPos.to_comparable_int
      if rec.type == :read do
        {cnt + 1, len + pos - prev, Enum.max([max_len, pos - prev]), pos}
      else
        {cnt, len, max_len, pos}
      end
    end)

    per_session = sessions_length / sessions

    %BookStats{
      days: days,
      sessions: sessions,
      per_session: per_session,
      longest: longest
    }
  end
end
