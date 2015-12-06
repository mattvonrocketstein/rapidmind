defmodule Reddit do
    @moduledoc """
      Things and stuff.....
    """  
  
  @spec extract_links_and_comments(String) :: Enum
  def extract_links_and_comments(body) do
    # returns [ [link_url, comment_url], .. ]
    # TODO: use struct http://elixir-lang.org/getting-started/structs.html
    links = Floki.find(body, "div.entry a.title") |> Floki.attribute("href")
    comments = Floki.find(body, "div.entry a.comments") |> Floki.attribute("href")
    links_and_comments = Enum.zip(links, comments)
  end
  def crawl_one_sub(subreddit_name) do
    subreddit_config = Config.get_subreddit_config(subreddit_name)
    HTTPoison.start
    source = "https://www.reddit.com/r/#{subreddit_name}"
    IO.puts "Scanning subreddit: #{source}"
    rules = subreddit_config |> Dict.get("keywords")
    case HTTPoison.get(source) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        links_and_comments = extract_links_and_comments(body)
        pids = Enum.map(
          links_and_comments,
          fn {url, comments} ->
            cond do
              String.at(url, 0)=="/" ->
                uri = URI.parse(source)
                url = uri.scheme <> "://" <> uri.host <> url
              true ->
                :ok
            end
            webpage = %WebPage{
              url: url,
              rules: rules,
              source: source,
              comments: comments}
            pid = spawn_link fn -> WebPage.download(webpage)  end
            pid
          end
        )
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        :ok #print "#{url}: Not found :("

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.puts "#{source}: error #{reason}"

      {:ok, %HTTPoison.Response{status_code: status_code, }} ->
        IO.puts "#{source}: unhandled code #{status_code}"
    end
  end
end
