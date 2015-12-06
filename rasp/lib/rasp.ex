require IEx
require Logger

defmodule Rasp do
  @moduledoc """
  Things and stuff.....
  """

  use Application
  import Apex

  def start(_type, _args) do Rasp.Supervisor.start_link end

  def main(args) do args |> parse_args |> process end
  
  @spec parse_args(Enum) :: Map
  defp parse_args(args) do
    switches = [
      help:   :boolean,
      debug:  :boolean,
      reddit: :string,
      rules:  :string ]
    {options, _, _} = OptionParser.parse(args, switches: switches)
    options
  end

  @spec process(Enum) :: any
  defp process([]) do IO.puts "Incorrect usage (use --help for help)" end
  
  @spec process(any) :: any
  defp process(:help) do
    IO.puts """
      Usage:
        rasp --rules [rules_file]

      Options:
        --rules  specify rules to use (a file containing JSON)
        --help   Show this help message
    """
  end
  
  defp process(:rules) do
    rules = State.get(:input)[:options][:rules]
    debug = State.get(:input)[:options][:debug]
    {:ok, pid} = Config.start_link(rules)
    subreddits = Config.subreddits()
    pages = Config.pages()
    if debug do 
      IO.puts "limiting requests since --debug is true"
      subreddits = subreddits |> Enum.slice(0, 1)
      pages = pages |> Enum.slice(0, 1)
    end

    pids = pages
    |> Enum.map(&WebPage.select_and_match/1)
    |> List.flatten
    |> PidList.join

    pids = subreddits
    |> Enum.map(&Reddit.crawl_one_sub/1)
    |> List.flatten
    |> PidList.join

    State.get()
    |>Dict.drop([:input, :options, :output])
    |>post_process()
  end 
  defp process(options) do
    {:ok, record} = State.start_link(options)
    State.put(:output, %{})
    State.put(:input, %{:options => options})
    cond do
      options[:help]  -> process(:help)
      options[:rules] -> process(:rules) 
      true            -> process([])
      end
  end

  defp post_process(data_so_far) do
    options = State.get(:input)[:options]
    # and unset `body` / `rules` items from the struct
    # (processing is finished now so they are no longer used)
    cleaned_output = data_so_far
    |>Dict.keys()
    |>Enum.map(
        fn url ->
          webpage = State.get(url)
          if webpage do WebPage.clean(webpage) end
        end)
    |>Enum.filter(fn webpage -> webpage && !Enum.empty?(webpage.matches) end)
    State.put(:output, cleaned_output)
    Apex.ap cleaned_output
    cond do
      options[:mongo] -> :ok
      true            -> :ok
      #Helpers.write_to_mongo(options[:mongo], %{}cleaned_output)
    end
  end
end
