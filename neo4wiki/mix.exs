defmodule Saxy.Mixfile do
  use Mix.Project

  def project do
    [app: :saxy,
     version: "0.0.1",
     elixir: "~> 1.3",
     deps: deps]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
   		{:erlsom, git: "git@github.com:willemdj/erlsom.git"},
      {:neo4j_sips, path: "../neo4j_sips"},
    ]
  end
end
