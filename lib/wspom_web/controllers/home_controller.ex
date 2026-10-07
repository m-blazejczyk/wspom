defmodule WspomWeb.HomeController do
  use WspomWeb, :controller

  def home(conn, _params) do
    entry_stats = Wspom.Entries.Context.get_stats()
    weight_stats = Wspom.Weight.Context.get_stats()
    books_stats = Wspom.Books.Context.get_stats()
    weather_stats = Wspom.Weather.Context.get_stats()
    render(
      conn, :home,
      layout: false,  # Skip the default app layout.
      entries: "#{entry_stats.entries} entries",
      days: "#{weight_stats.days} days",
      books: "#{books_stats.books} books",
      weather: "#{weather_stats.days} days (#{:io_lib.format("~.1f", [weather_stats.years])} years)"
    )
  end

  def entries(conn, _params) do
    stats = Wspom.Entries.Context.get_landing_page_stats()
    render(
      conn, :entries,
      layout: false,  # Skip the default app layout.
      stats: stats
   )
  end
end
