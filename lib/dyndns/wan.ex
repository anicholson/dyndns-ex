defmodule Dyndns.Wan do
  require Logger
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

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
      {:ok, response} = HTTPoison.get("https://api.ipify.org", headers)
      ip = response.body

      case ip == state.ip do
        true ->
          diff = 60 * (state.updates_since_last_change + 1)
          next_update = DateTime.add(now, diff, :second)
          new_state = %{state | updates_since_last_change: state.updates_since_last_change + 1 , next_update: next_update}
          Logger.info("IP unchanged, next update in #{next_update - now} seconds")
          {:reply, state.ip, new_state}

        false ->
          next_update = DateTime.add(now, 60, :second)
          new_state = %{ip: ip, next_update: next_update, updates_since_last_change: 0}
          Logger.info("IP changed, next update in 60 seconds")
          {:reply, ip, new_state}
      end
    end
  end
end
