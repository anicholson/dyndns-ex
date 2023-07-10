defmodule Dyndns.Admin do
  @moduledoc """
  Provides a very simple JSON admin API for inspecting the application state.

  Listening on port 4000 by default (not currently configurable)
  """
  alias Plug.Conn
  defmodule Plug do
    @moduledoc false
    import Conn

    def init(opts), do: opts

    def call(conn, _opts) do
      current_state = Dyndns.wan_state()

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, Jason.encode!(current_state))
    end
  end
end
