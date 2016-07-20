
defmodule Common do
  @spec user_msg(String) :: any
  def user_msg(msg) do
    msg = IO.ANSI.blue() <> msg <> IO.ANSI.reset()
    IO.puts(msg)
  end
end

defmodule Saxy.CommandLine do
  @moduledoc """
  """

  @doc """
  it's not really clear to me why, but without a block-forever
   call such as the one below the main process will exit, taking
   all the supervision trees with it.  see also:
   https://groups.google.com/forum/#!topic/elixir-lang-talk/N9RZd_8y0sk
  """
  @spec main_loop :: any
  def main_loop do
    IO.puts("entering main-loop")
    :timer.sleep(:infinity) # prevent the main process from exiting
  end

  @doc """
  Entry-point for CLI invocations of wikiparser (escript entry)
  """
  def main(args) do
      args |> parse_args |> process
      #main_loop()
  end

  @doc """
  """
  def parse_args(args) do
      {options, _, _} = OptionParser.parse(args,
        switches: [
          file: :string,
          wipedb: :boolean])
      options
  end

  @doc """
  """
  def process([]) do
      Common.user_msg("No arguments given")
      System.halt(1)
  end

  @doc """
  """
  def process(options) do
    cond do
      options[:file] == nil and options[:wipedb]==nil ->
        IO.puts("no arguments given")
        System.halt(1)
      options[:file] ->
        IO.puts("escript commandline entry")
        WikiParser.start(:cli, [options[:file]])
      options[:wipedb] ->
        IO.puts("escript commandline entry")
        WikiParser.sstart(:cli, :wipedb)
    end
  end
end
import Supervisor.Spec, warn: false

defmodule WikiParser do
  alias Neo4j.Sips, as: Neo4j

  use Application

  def starter(children, extra_opts \\ []) do
    unconditonal_children = [
    ]
    IO.puts("Children (#{Enum.count(children)} total): #{inspect(children)}")
    opts = extra_opts ++ [
      strategy: :one_for_one,
      name: WikiParser.Supervisor]
    Supervisor.start_link(
      unconditonal_children ++ children, opts)
  end

  def start(start_type, [mix_env | start_args]) do
      Common.user_msg(
        "Application entry: #{inspect({mix_env, start_type, start_args})}")
      cond do
        is_atom(mix_env) ->
          sstart(mix_env, start_args)
        is_binary(mix_env) ->
          sstart(start_type, mix_env)
      end
  end

  # function-header, so no do/ends are needed
  def sstart(mix_env_or_mode, args \\ [])
  def sstart(:test, []) do
      IO.puts("entry from 'mix test'?")
      starter([])
  end
  def sstart(:cli, :wipedb) do
    start_sub()
    Common.user_msg "wipedb!"
    cypher = """
    MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n,r
    """
    {:ok, []} = Neo4j.query(Neo4j.conn, cypher)
  end
  def sstart(:cli, config_file) do
    IO.puts("CLI entry: #{config_file}")
    start_sub()
    #{:ok, john} = Person.create(
    #  name: "John DOE", email: "john.doe@example.com",
    #  age: 30, doe_family: true, enable_validations: true)
    Saxy.run(config_file)
  end

  def start_sub() do
    {:ok, _} = Application.ensure_all_started(:logger)
    {:ok, _} = Application.ensure_all_started(:neo4j_sips_models)
  end
end
