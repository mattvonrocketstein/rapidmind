
  defmodule WebPage do
    defstruct [
      {:url, ""},       # ::url::      base URL for the page
      {:comments, ""},  # ::comments:: a comment URL if relevant (probably only reddit)
      {:source, ""},    # ::source::   the URL we got this URL from, if relevant
      {:body, ""},      # ::body::     page contents (empty before download and deleted after it's used)
      {:matches, []},   # ::matches::  regexes that matched this page
      {:rules, []}      # ::rules::    regexes used to test this page
    ]
    
    @spec clean(WebPage) :: WebPage
    def clean(webpage) do 
      IO.puts "#{inspect webpage}"
      if Map.has_key?(webpage, :body) do
        webpage = webpage|>Map.delete(:body)
      end
      if Map.has_key?(webpage, :rules) do
        webpage = webpage|>Map.delete(:rules)
      end
      if Map.has_key?(webpage,:url) && 
         Map.has_key?(webpage,:comments) && 
         webpage.url == webpage.comments do
          webpage = webpage|>Map.drop([:comments])
      end
    end

    def download(item_info) do
      HTTPoison.start # don't move
      IO.puts item_info.url
      #output = State.get(:output)
      case HTTPoison.get(item_info.url, [], [follow_redirect: true, hackney: [:insecure]]) do
       {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
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
    
    @spec process_page(WebPage) :: WebPage
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
