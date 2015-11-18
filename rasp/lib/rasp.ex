require IEx
require Logger

defmodule Rasp do
  @moduledoc """
  Things and stuff.....
  """
  use Application
  import Apex
  
  def start(_type, _args) do
    Rasp.Supervisor.start_link
  end

  def main(args) do
    args |> parse_args |> process
  end

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

        ./rasp --reddit [subreddit] --rules [rules]

      Options:
        --rules  specify rules to use (a file containing JSON)
        --reddit Specify subreddit to use 
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
      
      options[:reddit] && options[:rules] ->
        crawler(record)
      
      options[:reddit] || options[:rules] ->
        # incorrect usage
        process([]) 
      
      true ->
        process([])
      end
  end
  
  def crawler(record) do
    HTTPoison.start
    input = State.get( :input)
    #options = Dict.get(input, :options)
    reddit = input[:options][:reddit]
    rules_file = input[:options][:rules]
    source = "https://www.reddit.com/r/#{reddit}"
    ap "Scanning subreddit: #{source}"
    State.put( :input, Map.put(input, :rules, Helpers.read_config_file(rules_file)))
    case HTTPoison.get(source) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        #4..6 |> Enum.map(&FizzBuzz.print/1)
        links_and_comments = Helpers.extract_links_and_comments(body)
        |>Enum.slice(0,2)
        #out = 
        Enum.map(
          links_and_comments, 
          fn {url, comments} ->
            cond do
              String.at(url,0)=="/" ->
                url=comments
                #IO.puts "Ignoring #{url} since it's relative"
                #almost works but makes strings like
                #http://www.reddit.com/r/python/r/Python/comments/3t8fgn/help_interget_input_and_print_problem/
                #url = source <> url 
              true ->
                :ok
            end
            pid = spawn_link fn -> get_page({source, comments, url}, record)  end
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
    cleaned_output = State.get()
    |>Dict.drop([:input,:output,:pids])
    |>Dict.keys()
    |>Enum.map(fn x->Dict.delete(State.get(x),:body) end)
    Apex.ap cleaned_output
    options = Map.get(State.get( :input), :options)
    cond do
      #options[:json] ->
      options[:mongo] ->
        #Helpers.write_to_mongo(options[:mongo], %{}cleaned_output)
        :ok
      true ->
        :ok
    end
  end

  def match_page(body, regex_rule) do
    regex = Helpers.string_to_regex(regex_rule)
    struct = [
      {:regex,  regex},
      {:match,  Regex.match?(regex, body)},
      {:string, regex_rule} ]
    if struct[:match] do struct[:string] end
  end

  def process_page(url) do
    #output = State.get(:output)
    #url_record = output[url]
    #Apex.ap url_record
    rules = State.get(:input)[:rules]
    match_list = Enum.map(rules, fn(rule) -> match_page(State.get(url)[:body], rule) end )
    match_list = Enum.filter(match_list, fn(x)-> x end )
    if ! Enum.empty?(match_list) do
      #output = State.get( :output)
      #item_info = Dict.get(output, url)
      #item_info = Dict.put(url_record, :matches, match_list)
      item_info = State.get(url)
      State.put(url, Dict.put(item_info,:matches,match_list))
      #output = State.put_output(url, item_info)
      #State.put( :output, output)
    end
  end

  def get_page({source, comments, url}, record) do
    HTTPoison.start # don't move
    IO.puts url
    output = State.get( :output)
    case HTTPoison.get(url, [], [follow_redirect: true]) do
     {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        item_data = %{
          :body=>body, 
          :source=>source, 
          :comments=>comments 
        }
        State.put(url, item_data)
        #State.put(:output, output)
        process_page(url)
     {:ok, %HTTPoison.Response{status_code: 404}} ->
       IO.puts ".. #{url}: Not found :("
     {:error, %HTTPoison.Error{reason: reason}} ->
       IO.puts ".. #{url}: error #{inspect reason}"
     {:ok, %HTTPoison.Response{status_code: status_code}} ->
       IO.puts ".. #{url}: unhandled code #{status_code}"
    end

  end

  #def process(:help) do
    #
  #  System.halt(0)
  #end
 #end
end
