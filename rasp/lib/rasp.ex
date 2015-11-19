require IEx
require Logger


defmodule Rasp do
  @moduledoc """
  Things and stuff.....
  """
  use Application
  import Apex

defmodule WebPage do
    defstruct [
      {:url, ""},       # ::url::      base URL for the page
      {:comments, ""},  # ::comments:: a comment URL if relevant (probably only reddit)
      {:source, ""},    # ::source::   the URL we got this URL from, if relevant
      {:body, ""},      # ::body::     page contents (empty before download and deleted after it's used)
      {:matches, []},   # ::matches::  regexes that matched this page
      {:rules, []}      # ::rules::    regexes used to test this page
    ]

  def download(item_info) do
    HTTPoison.start # don't move
    IO.puts item_info.url
    output = State.get(:output)
    case HTTPoison.get(item_info.url, [], [follow_redirect: true]) do
     {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        item_info = %{item_info|body: body}
        State.put(item_info.url, item_info)
        process_page(item_info)
     {:ok, %HTTPoison.Response{status_code: 404}} ->
       IO.puts ".. #{item_info.url}: Not found :("
     {:error, %HTTPoison.Error{reason: reason}} ->
       IO.puts ".. #{item_info.url}: error #{inspect reason}"
     {:ok, %HTTPoison.Response{status_code: status_code}} ->
       IO.puts ".. #{item_info.url}: unhandled code #{status_code}"
    end
  end
  def process_page(item_info) do
    match_list = item_info.rules|>Enum.map(fn(rule) -> match_page(item_info.body, rule) end )
    match_list = Enum.filter(match_list, fn(x)-> x end )
    if ! Enum.empty?(match_list) do
      State.put(item_info.url, %{State.get(item_info.url)|matches: match_list})
    end
  end
  def match_page(body, regex_rule) do
    regex = Helpers.string_to_regex(regex_rule)
    struct = [
      {:match,  Regex.match?(regex, body)},
      {:string, regex_rule} ]
    if struct[:match] do struct[:string] end
  end
end
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
            crawl_one_sub(subreddit_name, subreddit_config)
          end)
      true ->
        process([])
      end
  end
  
  def crawl_one_sub(subreddit_name, subreddit_config) do
    HTTPoison.start
    source = "https://www.reddit.com/r/#{subreddit_name}"
    IO.puts "Scanning subreddit: #{source}"
    rules = subreddit_config|>Dict.get("keywords")
    case HTTPoison.get(source) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        #4..6 |> Enum.map(&FizzBuzz.print/1)
        links_and_comments = Helpers.extract_links_and_comments(body)
        #|> Enum.slice(0, 2)
        Enum.map(
          links_and_comments, 
          fn {url, comments} ->
            cond do
              String.at(url,0)=="/" ->
                uri = URI.parse(source)
                url = uri.scheme <> "://" <> uri.host <> url
              true ->
                :ok
            end
            item_info = %WebPage{
              url: url,
              rules: rules,
              source: source, 
              comments: comments}

            pid = spawn_link fn -> WebPage.download(item_info)  end
            State.put( :pids, [pid | State.get( :pids)])
            #get_page({source, comments, url}, record) 
          end
        )
        #out = Enum.filter(out, fn(x)->x end)
        State.wait_on(State.get( :pids))
        post_process()

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        :ok #print "#{url}: Not found :("

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.puts "#{source}: error #{reason}"

      {:ok, %HTTPoison.Response{status_code: status_code, }} ->
        IO.puts "#{source}: unhandled code #{status_code}"
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
