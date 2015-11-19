defmodule Reddit do
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
        {:pids, State.get(:pids)}
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        :ok #print "#{url}: Not found :("

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.puts "#{source}: error #{reason}"

      {:ok, %HTTPoison.Response{status_code: status_code, }} ->
        IO.puts "#{source}: unhandled code #{status_code}"
    end
  end
end
