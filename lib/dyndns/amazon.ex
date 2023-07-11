defmodule Dyndns.Amazon do
  @moduledoc """
  Handles communication between dyndns and AWS's Route53 service.

  This module is a GenServer that is started by the application supervisor.
  When this module starts, it will initialize the AWS client using the configuration
  provided in `config/runtime.exs`.

  When calling this module, you can ask it to:
    * lookup the hosted zone ID for the configured hostname (see `config/runtime.exs`)

  When casting this module, you can ask it to:
    * update the IP address for the configured hostname (see `config/runtime.exs`)
  """
  require Logger
  use GenServer

  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  @type t :: %{access_key_id: String.t(), secret_access_key: String.t(), region: String.t()}

  @spec init({String.t(), t()}) :: {:ok, any()}
  def init({hostname}) do
    {:ok, %{hostname: hostname, ip: nil, last_lookup: nil}}
  end

  def handle_call(:lookup, _from, s) do
    case s do
      %{ip: ip} when not is_nil(ip) ->
        {:reply, ip, s}

      _ ->
        Logger.info("Looking up hostname")
        %{config: %{hosted_zone_id: hosted_zone_id}, hostname: hostname} = s

        case lookup_ip(hosted_zone_id, hostname) do
          {:ok, %{ip: ip, raw: raw}} ->
            Logger.info("Found IP: #{ip}")
            new_state = Map.merge(s, %{ip: ip, last_lookup: raw})
            {:reply, ip, new_state}

          {:error, reason} ->
            Logger.error("Failed to lookup IP: #{inspect(reason)}")
            {:reply, nil, s}
        end
    end
  end

  def handle_call(:last_lookup, _from, s) do
    {:reply, s[:last_lookup], s}
  end

  def handle_cast({:new_ip, new_ip}, s) do
    Process.send(self(), {:upsert_record_set, new_ip}, [:noconnect])

    {:noreply, s}
  end

  def handle_info({:upsert_record_set, new_ip}, state) do
    %{config: %{hosted_zone_id: hosted_zone_id}, hostname: hostname} = state

    request =
      ExAws.Route53.change_record_sets(hosted_zone_id,
        comment: "Updated by dyndns at #{DateTime.utc_now()}",
        batch: [
          %{
            action: :UPSERT,
            name: "#{hostname}",
            type: :A,
            ttl: 60,
            records: [new_ip]
          }
        ]
      )

    Logger.debug("Updating record set: #{inspect(request)}")

    case ExAws.request(request) do
      {:ok, %{body: body}} ->
        Logger.info("Updated record set: #{inspect(body)}")
        {:noreply, state}

      {:error, reason} ->
        Logger.error("Failed to update record set: #{inspect(reason)}")
        {:noreply, state}
    end
  end

  defp lookup_ip(zone_id, hostname) do
    case ExAws.Route53.list_record_sets(zone_id, name: "#{hostname}.", type: :A)
         |> ExAws.request() do
      {:ok, %{body: body}} ->
        record_set = body[:record_sets] |> find_record_set(hostname)
        Logger.debug("Found record set: #{inspect(record_set)}")

        {:ok,
         %{
           ip: record_set[:values] |> List.first(),
           ttl: record_set[:ttl],
           raw: record_set
         }}

      e ->
        Logger.error("Failed to lookup record set: #{inspect(e)}")
        {:error, "Record Sets not found [zone_id"}
    end
  end

  defp find_record_set(record_sets, hostname) do
    Enum.find(record_sets, fn record_set ->
      record_set[:name] == "#{hostname}." and record_set[:type] == "A"
    end)
  end
end
