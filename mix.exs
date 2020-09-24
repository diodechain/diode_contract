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
      {:keccakf1600, "~> 2.0", hex: :keccakf1600_orig}
    ]
  end
end
