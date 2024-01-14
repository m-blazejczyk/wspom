defmodule Wspom.Context.Entry do
  use Ecto.Schema
  import Ecto.Changeset

  schema "entries" do
    field :description, :string
    field :title, :string
    field :month, :integer
    field :day, :integer
    field :year, :integer
    field :weekday, :integer
    field :importance, :integer
    field :fuzzy, :integer
    field :needs_review, :integer
    field :tags, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:description, :title, :year, :month, :day, :weekday, :importance, :fuzzy, :needs_review, :tags])
    |> validate_required([:description, :title, :year, :month, :day, :weekday, :importance, :fuzzy, :needs_review, :tags])
  end
end
