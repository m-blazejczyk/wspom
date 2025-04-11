defmodule Wspom.Book do
  alias Wspom.Book

  import Ecto.Changeset

  defstruct [:id, :title, :author, :length1, :length2, :length_type,
    :medium, :started_date, :finished_date, :status]

  # These types are only used for changeset validation.
  # These are the types that will be visible and editable in the form.
  # See https://hexdocs.pm/ecto/Ecto.Schema.html#module-types-and-castin
  @types %{id: :integer, title: :string, author: :string,
    length1: :integer, length2: :integer, length_type: :string,
    medium: :string, started_date: :date, finished_date: :date, status: :string}

end
