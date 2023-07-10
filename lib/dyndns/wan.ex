defmodule Dyndns.Wan do
  @moduledoc """
  Looks up the WAN IP address for the running system.

  This module is a GenServer that is started by the application supervisor.
  When this module starts, it will initialize an HTTP client.

  When calling this module, you can ask it to:
    * `:update` the IP address by making a request to an external service (currently static, see `config/confix.exs`)
    * `:state` the current state of the module (for visibility purposes, see `Dyndns.Admin`)
  """
  require Logger
  use GenServer

  @typedoc """
  The state of the WAN IP module.
  """
  @type state :: %{ip: String.t() | nil, next_update: DateTime.t(), updates_since_last_change: non_neg_integer()}

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @spec init(nil) :: {:ok, state()}
  def init(nil) do
    HTTPoison.start()
    {:ok, %{ip: nil, next_update: DateTime.utc_now(), updates_since_last_change: 0}}
  end

  def handle_call(:update, _from, state) do
    now = DateTime.utc_now()

    Logger.info("Checking WAN IP")
    headers = ["User-Agent": "curl/7.81.0"]

    case state do
    %{ip: ip, next_update: next_update} when ip != nil and next_update > now ->
      Logger.info("Using cached IP")
      {:reply, ip, state}


    _ ->
      Logger.info("Updating IP")
      {:ok, response} = HTTPoison.get(wan_ip_server(), headers)
      ip = response.body

      case ip == state.ip do
        true ->
          diff = 60 * (state.updates_since_last_change + 1)
          next_update = DateTime.add(now, diff, :second)
          new_state = %{state | updates_since_last_change: state.updates_since_last_change + 1 , next_update: next_update}
          Logger.info("IP unchanged, next update in #{DateTime.diff(next_update, now)} seconds")
          {:reply, state.ip, new_state}

        false ->
          next_update = DateTime.add(now, 60, :second)
          new_state = %{ip: ip, next_update: next_update, updates_since_last_change: 0}
          Logger.info("IP changed, next update in 60 seconds")
          {:reply, ip, new_state}
      end
    end
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  defp wan_ip_server do
    Application.get_env(:dyndns, :wan_ip_server)
  end
end
