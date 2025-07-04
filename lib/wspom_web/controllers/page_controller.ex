defmodule WspomWeb.PageController do
  use WspomWeb, :controller

  def home(conn, _params) do
    entry_stats = Wspom.Entries.Context.get_stats()
    weight_stats = Wspom.Weight.Context.get_stats()
    books_stats = Wspom.Books.Context.get_stats()
    render(
      conn, :home,
      # The home page is often custom made - skip the default app layout.
      layout: false,
      entries: "#{entry_stats.entries} entries",
      days: "#{weight_stats.days} days",
      books: "#{books_stats.books} books"
    )
  end
end
