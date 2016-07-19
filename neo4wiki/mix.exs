defmodule Saxy.Mixfile do
  use Mix.Project

  def project do
    [app: :saxy,
     version: "0.0.1",
     elixir: "~> 1.3",
     deps: deps,
     package: package,
     test_coverage: [
       tool: Coverex.Task,
       console_log: true],
     escript: [
       main_module: Saxy.CommandLine,
       app: nil
       ],
     aliases: aliases,
   ]
  end

  def application do
    [applications: [
      :logger,
    ]]
  end

  defp deps do
    [
      {:erlsom,
       git: "git@github.com:willemdj/erlsom.git"},

      # git@github.com:florinpatrascu/neo4j_sips.git
      {:neo4j_sips, path: "./neo4j_sips"},

      # a linter for elixir code
      {:dogma, "~> 0.1", only: :dev},

      # NB: 0.1.4 is available on github but not hex currently
      {:mock, "~> 0.1.4",
       git: "https://github.com/jjh42/mock.git"},

      # meck is required by mock, but version collides with ercloud,
      # so it is required to be explicit here explicit
      { :meck, ~r/.*/,
          [ env: :prod,
            git: "https://github.com/eproxus/meck.git",
            tag: "0.8.4",
            manager: :rebar,
            override: true]},

      # a static analysis tool
      {:dialyxir, "~> 0.3", only: [:dev]},

      # coverage tool for tests
      # https://github.com/alfert/coverex
      {:coverex, "~> 1.4.9", only: :test},

    ]
  end
  # Some command line aliases
  def aliases do
   [serve: ["run", &Proxy.start/1]]
  end

  defp package do
    [
      files: [],
      contributors: [
        "",
      ],
      maintainers: [""],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "",
        "Docs"   => ""
      }
    ]
  end

end
