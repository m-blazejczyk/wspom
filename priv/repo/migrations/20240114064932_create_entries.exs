defmodule Wspom.Repo.Migrations.CreateEntries do
  use Ecto.Migration

  def change do
    create table(:entries) do
      add :description, :string
      add :title, :string
      add :year, :integer
      add :month, :integer
      add :day, :integer
      add :weekday, :integer
      add :importance, :integer
      add :fuzzy, :integer
      add :needs_review, :integer
      add :tags, :string

      timestamps(type: :utc_datetime)
    end
  end
end
