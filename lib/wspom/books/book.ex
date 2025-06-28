defmodule Wspom.Book do
  alias Wspom.Book

  # import Ecto.Changeset

  # :length_type is either :pages, :time or :percent.
  # If :length_type is :time, :hours and :minutes should be set,
  # and :pages should be nil.
  # For the other values of :length_type, it's the opposite.
  # :medium can be: :book, :audiobook, :ebook, :comics.
  # :status can be: :active, :finished, :on_hold, :abandoned.
  # :history is a list containing both reading history and status history.
  # See book_history.ex for more information.
  # The date fields are calculated, not directly editable; they can both
  # be nil; :started_date will be nil in the rare cases of books that
  # were started being read before they were added to the database.
  defstruct [:id, :title, :short_title, :author, length: {:pages, 0},
    medium: :book, is_fiction: true, status: :active,
    started_date: nil, finished_date: nil, history: []]

  # These types are only used for changeset validation.
  # These are the types that will be visible and editable in the form.
  # They are different that what will be saved to the database.
  # See https://hexdocs.pm/ecto/Ecto.Schema.html#module-types-and-castin
  @types %{id: :integer, title: :string, short_title: :string, author: :string,
    length: :string, medium: :string, is_fiction: :boolean, status: :string}

end
