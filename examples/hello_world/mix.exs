defmodule HelloWorld.MixProject do
  use Mix.Project

  def project() do
    [
      app: :hello_world,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      compilers: compilers(Mix.env()),
      elixirc_paths: ["lib", "rpc"],
      erlc_paths: ["src", "rpc"],
      deps: deps()
    ]
  end

  defp compilers(:dev), do: [:twirp | Mix.compilers()]
  defp compilers(:test), do: [:twirp | Mix.compilers()]
  defp compilers(_), do: Mix.compilers()

  def application() do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps() do
    [
      {:twirp, path: "../..", only: [:dev, :test]},
      {:httpoison, ">= 0.0.0"},
      {:plug_cowboy, "~> 2.0"}
    ]
  end
end
