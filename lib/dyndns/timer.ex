defmodule Dyndns.Timer do
  @moduledoc """
  A GenServer that periodically checks the WAN IP and compares it to the
  Route53 record. If the IP has changed, it will update the record.
  """
  use Logs
  use GenServer

  @module "Timer"

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(nil) do
    schedule_tick(10)
    {:ok, nil}
  end

  def handle_info(:tick, state) do
    %{ip: wan_ip, checks_since_last_change: checks} = wan_status()
    aws_ip = fetch_aws_ip()

    case {wan_ip, aws_ip, checks} do
      {wan, aws, c} when wan != aws and not is_nil(wan) ->
        warning =
          if c > 0 do
            " (#{c} checks since last change. Is Route53 updating?)"
          end

        info("IP changed from #{wan} to #{aws} #{warning}")
        update_aws_ip(wan)

      {nil, _, _} ->
        info("No WAN IP")

      {wan, aws, _} when wan == aws ->
        info("IP unchanged")
    end

    schedule_tick()
    {:noreply, state}
  end

  defp schedule_tick(delay \\ 60_000) do
    Process.send_after(self(), :tick, delay)
  end

  defp wan_status() do
    Dyndns.wan_status()
  end

  defp fetch_aws_ip() do
    Dyndns.lookup_record()
  end

  defp update_aws_ip(ip) do
    GenServer.cast(Dyndns.Amazon, {:new_ip, ip})
  end
end
