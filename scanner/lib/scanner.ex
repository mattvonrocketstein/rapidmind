require IEx

defmodule Helpers do

  defmacro print(thing) do
      if String.valid?(thing) do
          quote bind_quoted: binding() do
           IO.puts thing
          end
      else
         quote bind_quoted: binding() do
           IO.puts("#{inspect thing}")
          end
      end
  end
  
  def string_to_regex(x) do elem(Regex.compile(x), 1) end

  def read_config_file(rules_file) do
    {:ok, body} = File.read(rules_file)
    result = Poison.Parser.parse!(body)
    num_rules = Enum.count(result)
    tmp = Enum.join(result,",")
    print "Read #{num_rules} rules: #{tmp}"
    result
  end  
end

defmodule ScannerCli do
  @moduledoc """
  Things and stuff.....
  """

  use Application
  import Helpers

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    ScannerCli.Supervisor.start_link
  end

  def main(args) do
    args |> parse_args |> process
  end

  def parse_args(args) do
    switches = [
      help: :boolean, 
      reddit: :string, 
      rules: :string ]
    {options, _, _} = OptionParser.parse(args, switches: switches)  
    options
  end

  def process([]) do IO.puts "Incorrect usage (use --help for help)" end
    
  def process(:help) do 
    print """
      Usage:
      ./scanner --reddit [subreddit] --rules [rules]

      Options:
      --help  Show this help message.  
    """
  end
  
  def process(options) do
    print options
    cond do
      options[:help] ->
        process(:help)
      options[:reddit] && options[:rules] ->
        do_process(options, options[:reddit], options[:rules])
      options[:reddit] || options[:rules] ->
        process([])
      true ->
        process([])
      end
  end
 
  def do_process(options, reddit, rules_file) do
    HTTPoison.start
    print "Scanning subreddit: #{reddit}"
    source = "https://www.reddit.com/r/#{reddit}"
    rules = Helpers.read_config_file(rules_file)
    case HTTPoison.get(source) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        #print "#{source}: retrieved"
        links = Floki.find(body, "div.entry a.title") |> Floki.attribute("href")
        comments = Floki.find(body, "div.entry a.comments") |> Floki.attribute("href")
        links_and_comments = Enum.zip(links, comments)
        out = links_and_comments 
        |> Enum.map(fn {url,comments} -> get_page(source, comments, url, rules) end) 
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
    print result  
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
       print ".. #{url}: error #{reason}"
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
