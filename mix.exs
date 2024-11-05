defmodule WatermarkDetector.MixProject do
  use Mix.Project

  def project do
    [
      app: :watermark_detector,
      version: "0.1.0",
      elixir: "~> 1.17",
      elixirc_paths: ["lib"],
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {WatermarkDetector.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nx, "~> 0.6.4"},
      {:bumblebee, "~> 0.4.2"},
      {:exla, "~> 0.6.4"},
      {:kino, "~> 0.11.3"},
      {:image, "~> 0.40.0"},
      {:req, "~> 0.5.6"},
      {:briefly, "~> 0.4.0"}
    ]
  end
end
