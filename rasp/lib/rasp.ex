require IEx

defmodule Rasp do
  @moduledoc """
  Things and stuff.....
  """
  require Logger
  use Application
  import Apex
  import Helpers
  #import FizzBuzz
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
    print """
      Usage:

        ./rasp --reddit [subreddit] --rules [rules]

      Options:
        --rules  specify rules to use (a file containing JSON)
        --reddit Specify subreddit to use 
        --help   Show this help message
    """
  end

  def process(options) do
    #ap options
    cond do
      options[:help] ->
        process(:help)
      
      options[:reddit] && options[:rules] ->
        do_process(options, options[:reddit], options[:rules])
      
      options[:reddit] || options[:rules] ->
        # incorrect usage
        process([]) 
      
      true ->
        process([])
      end
  end
  def extract_links_and_comments(body) do
    links = Floki.find(body, "div.entry a.title") |> Floki.attribute("href")
    comments = Floki.find(body, "div.entry a.comments") |> Floki.attribute("href")
    links_and_comments = Enum.zip(links, comments)
  end
  def do_process(options, reddit, rules_file) do
    HTTPoison.start
    ap "Scanning subreddit: #{reddit}"
    source = "https://www.reddit.com/r/#{reddit}"
    rules = Helpers.read_config_file(rules_file)
    case HTTPoison.get(source) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        4..6 |> Enum.map(&FizzBuzz.print/1)
        links_and_comments = extract_links_and_comments(body)
        out = links_and_comments
        |> Enum.map(fn {url, comments} -> get_page(source, comments, url, rules) end)
        |> Enum.filter(fn(x)->x end)
        post_process(options, out)
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        :ok #print "#{url}: Not found :("
      {:error, %HTTPoison.Error{reason: reason}} ->
        print "#{source}: error #{reason}"
      {:ok, %HTTPoison.Response{status_code: status_code, }} ->
        print "#{source}: unhandled code #{status_code}"
    end
  end

  def post_process(options, result) do
    ap result
    cond do
      options[:mongo] ->
        write_to_mongo(options[:mongo], result)
      true ->
        :ok
    end
  end

  def write_to_mongo(connection_string, result) do
    [host, port] = String.split(connection_string, ":")
    mongo = Mongo.connect!(host, port)
    print "not implemented yet"
  end

  def match_page(body, regex_rule) do
    regex = Helpers.string_to_regex(regex_rule)
    struct = [
      {:regex,  regex},
      {:match,  Regex.match?(regex, body)},
      {:string, regex_rule} ]
    if struct[:match] do struct[:string] end
  end

  def process_page(source, comments, url, body, rules) do
    match_list = rules
    |> Enum.map( fn(rule) -> match_page(body, rule) end )
    |> Enum.filter( fn(x)-> x end )
    if ! Enum.empty?(match_list) do
      print match_list
      [ {:url, url},
        {:source, source},
        {:comments, comments},
        {:matches, match_list} ]
    end
  end

  def get_page(source, comments, url, rules) do
    print url
    # fixme: this rereads the config unnecessarily >:/
    #rules = read_config_file(rules)
    case HTTPoison.get(url, [], [follow_redirect: true]) do
     {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
       process_page(source, comments, url, body, rules)
     {:ok, %HTTPoison.Response{status_code: 404}} ->
       print ".. #{url}: Not found :("
     {:error, %HTTPoison.Error{reason: reason}} ->
       print ".. #{url}: error #{inspect reason}"
     {:ok, %HTTPoison.Response{status_code: status_code}} ->
       print ".. #{url}: unhandled code #{status_code}"
    end
  end

  #def process(:help) do
    #
  #  System.halt(0)
  #end
 #end
end
