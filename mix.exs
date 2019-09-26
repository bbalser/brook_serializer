defmodule Brook.Serializer.MixProject do
  use Mix.Project

  def project do
    [
      app: :brook_serializer,
      version: "2.0.0",
      elixir: "~> 1.8",
      description: description(),
      package: package(),
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
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
      {:jason, "~> 1.1"},
      {:ex_doc, "~> 0.20.2", only: [:dev]},
      {:placebo, "~> 1.2", only: [:dev, :test]},
      {:checkov, "~> 0.4.0", only: [:test]}
    ]
  end

  defp elixirc_paths(env) when env in [:test, :integration], do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp description do
    "Serializer and Deserializer protocol used by brook to serialize and deserialize event"
  end

  defp package do
    [
      maintainers: ["Brian Balser"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/bbalser/brook_serializer"}
    ]
  end
end
