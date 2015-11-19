defmodule Rasp.Mixfile do
  use Mix.Project

  def project do
    [app: :rasp,
     version: "0.0.1",
     elixir: "> 1.0.0",
     escript: escript,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [ applications: [:logger],
      mod: { Rasp, [] } ]
  end

    # Type `mix help deps` for more examples and options
    defp deps do
    [
        { :floki, git: "https://github.com/philss/floki.git", tag: "v0.7.0" },
        { :mongo, git: "https://github.com/checkiz/elixir-mongo.git", tag: "0.5.2" },
        { :httpoison, "~> 0.8.0"},
        { :poison, "~> 1.5"},
        { :apex, "~>0.3.2"},
        { :ex_json_schema, "~> 0.3.0"}
    ]
  end

  # Configuration for the escript build process
  #
  # Type `mix help escript.build` for more information
  defp escript do
    [ main_module: Rasp,
      embedd_elixir: true ]
  end

end
