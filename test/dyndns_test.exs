defmodule DyndnsTest do
  use ExUnit.Case
  doctest Dyndns

  test "greets the world" do
    assert Dyndns.hello() == :world
  end
end
