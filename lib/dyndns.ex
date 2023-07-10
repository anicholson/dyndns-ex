defmodule Dyndns do
  @moduledoc """
  Helper functions for debugging and testing during development.
  """

  def wan_ip do
    GenServer.call Dyndns.Wan, :update
  end

  def wan_state do
    GenServer.call Dyndns.Wan, :state
  end

  def aws_config do
    Application.get_env(:dyndns, :aws)
  end

  def lookup_zone do
    GenServer.call Dyndns.Amazon, :lookup
  end

  def hostname do
    Application.get_env(:dyndns, :hostname)
  end
end
