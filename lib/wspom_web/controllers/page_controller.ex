defmodule WspomWeb.PageController do
  use WspomWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made - skip the default app layout.
    render(conn, :home, layout: false)
  end
end
