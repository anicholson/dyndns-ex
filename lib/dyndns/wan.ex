defmodule Dyndns.Wan do
  @moduledoc """
  Looks up the WAN IP address for the running system.

  This module is a GenServer that is started by the application supervisor.
  When this module starts, it will initialize an HTTP client.

  When calling this module, you can ask it to:
    * `:update` the IP address by making a request to an external service (currently static, see `config/confix.exs`)
    * `:state` the current state of the module (for visibility purposes, see `Dyndns.Admin`)
  """
  use Logs
  use GenServer

  @module "WAN"

  @typedoc """
  The state of the WAN IP module.
  """
  @type state :: %{
          ip: String.t() | nil,
          next_check: DateTime.t(),
          checks_since_last_change: non_neg_integer()
        }

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @spec init(nil) :: {:ok, state()}
  def init(nil) do
    HTTPoison.start()
    Process.send_after(self(), :check, 50)
    {:ok, %{ip: nil, next_check: DateTime.utc_now(), checks_since_last_change: 0}}
  end

  def handle_info(:check, state) do
    now = DateTime.utc_now()

    info("Checking WAN IP")
    headers = ["User-Agent": "curl/7.81.0"]

    case state do
      %{ip: ip, next_check: next_check} when ip != nil and next_check > now ->
        info("Using cached IP")
        {:noreply, state}

      _ ->
        info("Updating IP")
        {:ok, response} = HTTPoison.get(wan_ip_server(), headers)
        ip = response.body

        case ip == state.ip do
          true ->
            wait = time_to_wait(state.checks_since_last_change)
            next_check = DateTime.add(now, wait, :second)

            new_state = %{
              state
              | checks_since_last_change: state.checks_since_last_change + 1,
                next_check: next_check
            }

            info("IP unchanged, next check in #{wait} seconds")
            schedule_next_check(wait)
            {:noreply, new_state}

          false ->
            next_check = DateTime.add(now, 60, :second)
            new_state = %{ip: ip, next_check: next_check, checks_since_last_change: 0}
            info("IP changed, next update in 60 seconds")
            schedule_next_check(60)
            {:noreply, new_state}
        end
    end
  end

  def handle_call(:status, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, state}
  end

  defp wan_ip_server do
    Application.get_env(:dyndns, :wan_ip_server)
  end

  defp max_wait do
    Application.get_env(:dyndns, :max_wan_wait)
  end

  defp time_to_wait(checks_since_last_change) do
    min(max_wait(), 60 * (checks_since_last_change + 1))
  end

  defp schedule_next_check(seconds) do
    Process.send_after(self(), :check, seconds * 1000)
  end
end
