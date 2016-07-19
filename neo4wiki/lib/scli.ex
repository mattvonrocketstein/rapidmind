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
      main_loop()
  end

  @doc """
  """
  def parse_args(args) do
      {options, _, _} = OptionParser.parse(args,
        switches: [file: :string])
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
      options[:file] == nil ->
        IO.puts("--file was not passed")
        System.halt(1)
      true ->
        IO.puts("escript commandline entry")
        WikiParser.start(:cli, [options[:file]])
    end
  end
end
import Supervisor.Spec, warn: false

defmodule WikiParser do
  @moduledoc """
  """
  use Application

  @doc """
  """
  def starter(children, extra_opts \\ []) do
    # See http://elixir-lang.org/docs/stable/elixir/Application.html
    # for more information on OTP Applications
    unconditonal_children = [
      # Define workers and child supervisors to be supervised
    ]
    IO.puts("Children (#{Enum.count(children)} total): #{inspect(children)}")
    opts = extra_opts ++ [
      strategy: :one_for_one,
      name: WikiParser.Supervisor]
    Supervisor.start_link(
      unconditonal_children ++ children, opts)
  end

  @doc """
  """
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

  # function-clauses that work with pattern matching
  @doc """
  """
  def sstart(:test, []) do
      IO.puts("entry from 'mix test'?")
      starter([])
  end

  @doc """
  """
  def sstart(:dev, start_args) do
    Application.ensure_all_started(:quantum)
    Application.ensure_all_started(:erlcloud)
    Application.ensure_all_started(:logger)
    starter(
      [
        #supervisor(HostTable, start_args),
        #supervisor(HostMon, [])
        ])
  end

  @doc """
  """
  def sstart(:cli, config_file) do
    IO.puts("CLI entry: #{config_file}")
    sstart(:dev, [config_file])
  end
end
