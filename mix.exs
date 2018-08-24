defmodule VayneMetricKsy.MixProject do
  use Mix.Project

  def project do
    [
      app: :vayne_metric_ksy,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:timex, "~> 3.3"},
      {:httpotion, "~> 3.1"},
      {:aws_auth, "~> 0.6.4"},
      {:sweet_xml, "~> 0.6.5"},
      {:vayne, github: "mon-suit/vayne_core", only: [:dev, :test], runtime: false},
    ]
  end
end
