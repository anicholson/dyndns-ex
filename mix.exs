defmodule Dyndns.MixProject do
  use Mix.Project

  def project do
    [
      app: :dyndns,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Dyndns.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:aws, "~> 0.13.0"},
      {:hackney, "~> 1.18"},
      {:httpoison, "~> 2.1"},
      {:jason, "~> 1.4"}
    ]
  end
end
