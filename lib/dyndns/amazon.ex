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
  def init({hostname, aws}) do
    Logger.warn(
      "Initializing AWS: [hostname = #{hostname}, access_key = #{aws.access_key_id}, region = #{aws.region}]"
    )

    client = AWS.Client.create(aws.access_key_id, aws.secret_access_key, aws.region)

    {:ok, %{config: aws, client: client, hostname: hostname, ip: nil, last_lookup: nil}}
  end

  def handle_call(:lookup, _from, s) do
    case s do
      %{ip: ip} when not is_nil(ip) ->
        {:reply, ip, s}

      _ ->
        Logger.info("Looking up hostname")
        %{client: client, config: %{hosted_zone_id: hosted_zone_id}, hostname: hostname} = s

        case lookup_ip(client, hosted_zone_id, hostname) do
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

  def handle_cast(:new_ip, _from, s) do
    # TODO: create a record set and upload to Route53
  end

  defp lookup_ip(client, zone_id, hostname) do
    case AWS.Route53.list_resource_record_sets(client, zone_id, nil, nil, "#{hostname}.", "A") do
      {:ok, resp, _raw} ->
        record_set =
          get_in(resp, [
            "ListResourceRecordSetsResponse",
            "ResourceRecordSets",
            "ResourceRecordSet"
          ])
          |> find_record_set(hostname)

        Logger.debug("Found record set: #{inspect(record_set)}")

        {:ok,
         %{
           ip: get_in(record_set, ["ResourceRecords", "ResourceRecord", "Value"]),
           ttl: get_in(record_set, ["TTL"]),
           raw: record_set
         }}

      _ ->
        {:error, "Record Sets not found [#{zone_id}]"}
    end
  end

  defp find_record_set(record_sets, hostname) do
    Enum.find(record_sets, fn record_set ->
      record_set["Name"] == "#{hostname}." and record_set["Type"] == "A"
    end)
  end

  defp update_record(record_set, new_value) do
    put_in(record_set, ["ResourceRecords", "ResourceRecord", "Value"], new_value)
  end
end
