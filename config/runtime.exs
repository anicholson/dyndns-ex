import Config

defmodule Helpers do
  def require_env_key(keyname) do
    case System.get_env(keyname) do
      key when not is_nil(key) ->
        key

      _ ->
        raise """
          #{keyname} is not set.
          Please set it in your environment or in config/runtime.exs
        """
    end
  end
end

aws_access_key_id = Helpers.require_env_key("AWS_ACCESS_KEY_ID")
aws_secret_access_key = Helpers.require_env_key("AWS_SECRET_ACCESS_KEY")
hosted_zone_id = Helpers.require_env_key("HOSTED_ZONE_ID")

config :dyndns, :aws, %{
  access_key_id: aws_access_key_id,
  secret_access_key: aws_secret_access_key,
  hosted_zone_id: hosted_zone_id,
  region: "ap-southeast-2"
}

hostname = Helpers.require_env_key("HOSTNAME")
config :dyndns, :hostname, hostname

config :ex_aws,
  access_key_id: [aws_access_key_id],
  secret_access_key: [aws_secret_access_key],
  region: "us-east-1"
