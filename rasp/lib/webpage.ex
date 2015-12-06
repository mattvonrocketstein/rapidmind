
  defmodule WebPage do
    @moduledoc """
      Things and stuff.....
    """  
    defstruct [
      {:url, ""},       # ::url::      base URL for the page
      {:comments, ""},  # ::comments:: a comment URL if relevant (probably only reddit)
      {:source, ""},    # ::source::   the URL we got this URL from, if relevant
      {:body, ""},      # ::body::     page contents (empty before download and deleted after it's used)
      {:matches, []},   # ::matches::  regexes that matched this page
      {:rules, []},     # ::rules::    regexes used to test this page
      {:select, []}     # ::select::   Floki selectors diminish the part of the page we're matching against
    ]
    def select_and_match(
      {nickname, %{"match" => match_list, "url" => url, "select" => select_list}}) do
      IO.puts("Select and match for \"#{nickname}\"")
      webpage = %WebPage{:url => url, :rules => match_list, :select => select_list}
      pid = spawn_link fn -> WebPage.download(webpage)  end
      pid
    end
    @spec clean(WebPage) :: WebPage
    def clean(webpage) do 
      #IO.puts "#{inspect webpage}"
      Enum.map(
        [:body, :rules, :select],
        fn x -> 
          if Map.has_key?(webpage, x) do
            webpage = webpage |> Map.delete(x)
          end
        end)
      if Map.has_key?(webpage, :url) && 
         Map.has_key?(webpage, :comments) && 
         webpage.url == webpage.comments do
          webpage = webpage|>Map.drop([:comments])
      end
      webpage
    end

    def download(item_info) do
      HTTPoison.start # don't move
      IO.puts item_info.url
      #output = State.get(:output)
      case HTTPoison.get(item_info.url, [], [follow_redirect: true, hackney: [:insecure]]) do
       {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          if item_info.select do 
            selections = Enum.map(
              item_info.select, 
              fn x -> 
                Floki.find(body, x)
                |> Enum.map(&Floki.raw_html/1)
              end)
            body = Enum.join(selections, "\n")
          end
          item_info = %{item_info|body: body}
          #State.put(item_info.url, item_info)
          State.put(item_info.url, process_page(item_info))
       {:ok, %HTTPoison.Response{status_code: 404}} ->
          IO.puts ".. #{item_info.url}: Not found :("
       {:tls_alert, 'bad certificate'} ->
          IO.puts ".. #{item_info.url}: bad certificate"
       {:invalid_redirection, _} ->
          IO.puts ".. #{item_info.url}: invalid redirection"
       {:error, %HTTPoison.Error{reason: reason}} ->
          IO.puts ".. #{item_info.url}: error #{inspect reason}"
       {:ok, %HTTPoison.Response{status_code: status_code}} ->
          IO.puts ".. #{item_info.url}: unhandled code #{status_code}"
      end
    end
    
    #@spec process_page(#{}) :: #{}
    def process_page(item_info) do
      match_list = item_info.rules|>RegexList.all_matches(item_info.body)
      #match_list = item_info.rules|>Enum.map(fn(rule) -> match_page(item_info.body, rule) end )
      #match_list = Enum.filter(match_list, fn(x)-> x end )
      if ! Enum.empty?(match_list) do
        #State.put(item_info.url, %{State.get(item_info.url) | matches: match_list})
        %{item_info|matches: match_list}
      end
    end
  end # end webpage








