require IEx
defmodule Mix.Tasks.Shell do
  use Mix.Task

  def run(_) do
    IEx.pry
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

  def main(args) do
      args |> parse_args |> process
  end

  def parse_args(args) do
      {options, _, _} = OptionParser.parse(args,
        switches: [
          file: :string,
          wipedb: :boolean,
          ])
      options
  end

  def process([]) do
      Common.user_msg("No arguments given")
      System.halt(1)
  end

  def process(options) do
    noargs = options[:file] == nil and options[:wipedb]==nil
    cond do
      noargs ->
        IO.puts("no arguments given")
        System.halt(1)
      options[:file] ->
        IO.puts("escript commandline entry")
        WikiParser.start(:cli, [options[:file]])
      options[:wipedb] ->
        IO.puts("wipedb")
        DB.wipedb()
    end
  end
end
