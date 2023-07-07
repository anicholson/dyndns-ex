defmodule Dyndns.Admin do
  alias Plug.Conn
  defmodule Plug do
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
