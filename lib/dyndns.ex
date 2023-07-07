defmodule Dyndns do
  @moduledoc """
  Documentation for `Dyndns`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Dyndns.hello()
      :world

  """
  def hello do
    :world
  end

  def wan_ip do
    GenServer.call Dyndns.Wan, :update
  end
end
