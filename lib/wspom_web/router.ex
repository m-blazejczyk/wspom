defmodule WspomWeb.Router do
  use WspomWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {WspomWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", WspomWeb do
    pipe_through :browser

    get "/", PageController, :home

    live "/entries", Live.EntryView, :index
    live "/entries/new", Live.EntryView, :new
    live "/entries/:id/edit", Live.EntryView, :edit

    live "/weight", Live.Weight.WeightIndex, :index
    live "/weight/data", Live.Weight.WeightData, :data
    live "/weight/add", Live.Weight.WeightEdit, :add
    live "/weight/:id/edit", Live.Weight.WeightEdit, :edit
    live "/weight/charts", Live.Weight.WeightCharts, :charts
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:wspom, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: WspomWeb.Telemetry
    end
  end
end
