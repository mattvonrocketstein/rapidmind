defmodule Config do
  def start_link(rules_file) do
    Agent.start_link(
      fn -> 
        {:ok, body} = File.read(rules_file)
        result = Poison.Parser.parse!(body)
        pages = result
        |> Dict.get("pages")
        |> Dict.keys()
        num_pages = pages |> Enum.count()
        IO.puts "Crawling #{num_pages} pages: #{Enum.join(pages, ",")}"
        subreddits = result
        |> Dict.get("reddits")
        |> Dict.keys()
        num_reddits = subreddits |> Enum.count()
        IO.puts "Crawling #{num_reddits} subreddits: #{Enum.join(subreddits, ",")}"
        result
      end, 
      name: __MODULE__)
  end
  
  def get_subreddit_config(subreddit_name) do Config.reddits() |> Dict.get(subreddit_name) end
    
  def get() do
    Agent.get(__MODULE__, fn map -> map end)
  end
  def reddits() do
    Config.get()|>Dict.get("reddits")
  end
  
  def pages() do Config.get()|>Dict.get("pages") end 
     
  def subreddits() do
    Config.reddits() |> Dict.keys()
  end
end