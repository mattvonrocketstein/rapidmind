defmodule Automata.Mixfile do
  use Mix.Project

  def project do
    [app: :automata,
     version: "0.0.1",
     elixir: "~> 1.0",
     escript: escript,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [ applications: [:logger],
      mod: { Automata, [] } ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      { :colors, git: "https://github.com/lidashuang/colors"  },
      { :charm, git: "https://github.com/tomgco/elixir-charm" },
      { :exactor, "~> 2.2.0"},
      { :apex, "~>0.3.2"},
      { :random, git: "https://github.com/mururu/elixir-random.git"}
    ]
  end
  # Configuration for the escript build process
  #
  # Type `mix help escript.build` for more information
  defp escript do
    [ main_module: Automata,
      embedd_elixir: true ]
  end  
end

#testing, run with "mix hello", not "mix run hello"
defmodule Mix.Tasks.Hello do
  use Mix.Task
   
  def run(_) do
    Mix.shell.info "hello"
  end
end
