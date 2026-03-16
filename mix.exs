defmodule Contracts.Mixfile do
  use Mix.Project

  def project do
    [
      app: Contracts,
      version: "1.0.0",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
    ]
  end

  defp deps do
    [
      {:poison, "~> 3.0"},
      {:ex_sha3, "~> 0.1.5"}
    ]
  end
end
