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
    HTTPoison.start
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
    record = State.new
    State.put(record, :input, %{:options => options})
    State.put(record, :output, %{})
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
    input = State.get(record, :input)
    #options = Dict.get(input, :options)
    reddit = input[:options][:reddit]
    rules_file = input[:options][:rules]
    source = "https://www.reddit.com/r/#{reddit}"
    ap "Scanning subreddit: #{source}"
    State.put(record, :input, Map.put(input, :rules, Helpers.read_config_file(rules_file)))
    case HTTPoison.get(source) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        #4..6 |> Enum.map(&FizzBuzz.print/1)
        links_and_comments = Helpers.extract_links_and_comments(body)
        |>Enum.slice(0,2)
        out = Enum.map(
          links_and_comments, 
          fn {url, comments} -> get_page({source, comments, url}, record) 
        end)
        out = Enum.filter(out, fn(x)->x end)
        post_process(record)

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        :ok #print "#{url}: Not found :("

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.puts "#{source}: error #{reason}"

      {:ok, %HTTPoison.Response{status_code: status_code, }} ->
        IO.puts "#{source}: unhandled code #{status_code}"
    end
  end

  def post_process(record) do
    cleaned_output = State.get(record, :output) 
    urls = Dict.keys(cleaned_output)
    vals = Enum.map(
      Dict.values(cleaned_output),
      fn x -> Dict.delete(x, :body) end)
    cleaned_output = Enum.zip(urls, vals)
    cleaned_output = Enum.into(cleaned_output, %{})
    IEx.pry
    ap cleaned_output
    options = Map.get(State.get(record, :input), :options)
    cond do
      #options[:json] ->
      options[:mongo] ->
        write_to_mongo(options[:mongo], cleaned_output)
      true ->
        :ok
    end
  end

  def write_to_mongo(connection_string, result) do
    [host, port] = String.split(connection_string, ":")
    mongo = Mongo.connect!(host, port)
    IO.puts "not implemented yet"
  end

  def match_page(body, regex_rule) do
    regex = Helpers.string_to_regex(regex_rule)
    struct = [
      {:regex,  regex},
      {:match,  Regex.match?(regex, body)},
      {:string, regex_rule} ]
    if struct[:match] do struct[:string] end
  end

  def process_page(url, record) do
    output = State.get(record, :output)
    url_record = output[url]
    rules = State.get(record, :input)[:rules]
    match_list = Enum.map(rules, fn(rule) -> match_page(url_record[:body], rule) end )
    match_list = Enum.filter(match_list, fn(x)-> x end )
    if ! Enum.empty?(match_list) do
      output = State.get(record, :output)
      item_info = Dict.get(output, url)
      item_info = Dict.put(item_info, :matches, match_list)
      output = Dict.put(output, url, item_info)
      State.put(record, :output, output)
    end
  end

  def get_page({source, comments, url}, record) do
    IO.puts url
    output = State.get(record, :output)
    case HTTPoison.get(url, [], [follow_redirect: true]) do
     {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        item_data = %{
          :body=>body, 
          :source=>source, 
          :comments=>comments 
        }
        output = Map.put(output, url, item_data)
        State.put(record, :output, output)
        process_page(url, record)
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
