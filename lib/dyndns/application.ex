defmodule Dyndns.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Dyndns.Wan, []},
      {Dyndns.Amazon, Application.get_env(:dyndns, :amazon)},
      {Dyndns.Timer, []},
      {Bandit, plug: Dyndns.Admin.Plug}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Dyndns.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
