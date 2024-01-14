defmodule Wspom.Repo do
  use Ecto.Repo,
    otp_app: :wspom,
    adapter: Ecto.Adapters.SQLite3
end
