defmodule Helpers do

  def write_to_mongo(connection_string, result) do
    [host, port] = String.split(connection_string, ":")
    mongo = Mongo.connect!(host, port)
    IO.puts "not implemented yet"
  end

  def string_to_regex(x) do elem(Regex.compile(x), 1) end
  
  def extract_links_and_comments(body) do
    # returns [ [link_url, comment_url], .. ]
    # TODO: use struct http://elixir-lang.org/getting-started/structs.html
    links = Floki.find(body, "div.entry a.title") |> Floki.attribute("href")
    comments = Floki.find(body, "div.entry a.comments") |> Floki.attribute("href")
    links_and_comments = Enum.zip(links, comments)
  end

  def read_config_file(rules_file) do
    {:ok, body} = File.read(rules_file)
    result = Poison.Parser.parse!(body)
    #subreddits = result["reddits"] |> Dict.keys()
    subreddits = result
    |> Dict.get("reddits")
    |> Dict.keys()
    num_reddits = subreddits |> Enum.count()
    IO.puts "Crawling #{num_reddits} subreddits: #{Enum.join(subreddits, ",")}"
    result
  end
end