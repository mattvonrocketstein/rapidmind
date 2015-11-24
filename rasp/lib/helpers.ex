defmodule RegexList do
  @moduledoc """

  Example usage:

    RegexList.all_matches(["foo", "baz"], "foobar") :: ["foo"]
  
  """
  @spec string_to_regex(String) :: Regex
  def string_to_regex(x) do elem(Regex.compile(x), 1) end
  
  @spec all_matches(Array, String) :: Array
  def all_matches(regex_list, string) do
    match_list = regex_list 
    |> Enum.map(
      fn(regex_string) -> 
        regex = string_to_regex(regex_string)
        match =  Regex.match?(regex, string)
        cond do 
          match -> regex_string 
          !match -> false
        end
      end)
    match_list = match_list
    |> Enum.filter(fn(x)-> x end )
  end
end

defmodule Config do
  def start_link(rules_file) do
    Agent.start_link(
      fn -> 
        {:ok, body} = File.read(rules_file)
        result = Poison.Parser.parse!(body)
        subreddits = result
        |> Dict.get("reddits")
        |> Dict.keys()
        num_reddits = subreddits |> Enum.count()
        IO.puts "Crawling #{num_reddits} subreddits: #{Enum.join(subreddits, ",")}"
        result
      end, 
      name: __MODULE__)
  end
  
  def get_subreddit_config(subreddit_name) do
    Config.reddits() |> Dict.get(subreddit_name)
  end

  def get() do
    Agent.get(__MODULE__, fn map -> map end)
  end
  def reddits() do
    Config.get()|>Dict.get("reddits")
  end
  
  def subreddits() do

    Config.reddits() |> Dict.keys()
  end
end

defmodule Helpers do

  def write_to_mongo(connection_string, result) do
    [host, port] = String.split(connection_string, ":")
    mongo = Mongo.connect!(host, port)
    IO.puts "not implemented yet"
  end
  
  
  @spec extract_links_and_comments(String) :: Enum
  def extract_links_and_comments(body) do
    # returns [ [link_url, comment_url], .. ]
    # TODO: use struct http://elixir-lang.org/getting-started/structs.html
    links = Floki.find(body, "div.entry a.title") |> Floki.attribute("href")
    comments = Floki.find(body, "div.entry a.comments") |> Floki.attribute("href")
    links_and_comments = Enum.zip(links, comments)
  end
end