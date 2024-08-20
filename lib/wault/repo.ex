defmodule Wault.Repo do
  use Ecto.Repo,
    otp_app: :wault,
    adapter: Ecto.Adapters.Postgres
end
