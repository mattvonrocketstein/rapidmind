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

  def parse_args(args) do
    switches = [
      help:   :boolean,
      reddit: :string,
      rules:  :string ]
    {options, _, _} = OptionParser.parse(args, switches: switches)
    options
  end

  def process([]) do IO.puts "Incorrect usage (use --help for help)" end
  def process(:help) do
    IO.puts """
      Usage:

        ./rasp --rules [rules]

      Options:
        --rules  specify rules to use (a file containing JSON)
        --help   Show this help message
    """
  end

  def process(options) do
    {:ok, record} = State.start_link
    State.put(:input, %{:options => options})
    State.put(:output, %{})
    State.put(:pids, [])
    cond do
      options[:help] ->
        process(:help)

      options[:rules] ->
        config_json = Helpers.read_config_file(options[:rules])
        #State.put( :input, Map.put(input, :rules, config_json))
        reddits_config_json = config_json|>Dict.get("reddits")
        subreddits = reddits_config_json |> Dict.keys()
        #|> Enum.slice(0, 1)
        processed_subreddits = subreddits
        |> Enum.map(fn subreddit_name ->
            subreddit_config = Dict.get(reddits_config_json, subreddit_name)
            Reddit.crawl_one_sub(subreddit_name, subreddit_config)
          end)
        State.wait_on(State.get(:pids))
        post_process()

      true ->
        process([])
      end
  end

  def post_process() do
    # remove everything except the keys which are urls,
    # and unset `body` / `rules` items from the struct
    # (processing is finished now so they are no longer used)
    cleaned_output = State.get()
    |>Dict.drop([:input, :output, :pids])
    |>Dict.keys()
    |>Enum.map(
        fn x->
          %{%{State.get(x)|body: nil}|rules: nil}
        end)
    |>Enum.filter(fn x -> !Enum.empty?(x.matches) end)
    State.put(:output, cleaned_output)
    Apex.ap cleaned_output
    options = Map.get(State.get(:input), :options)
    cond do
      options[:mongo] ->
        #Helpers.write_to_mongo(options[:mongo], %{}cleaned_output)
        :ok
      true -> :ok
    end
  end
end
