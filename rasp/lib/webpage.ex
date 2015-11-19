  defmodule WebPage do
    defstruct [
      {:url, ""},       # ::url::      base URL for the page
      {:comments, ""},  # ::comments:: a comment URL if relevant (probably only reddit)
      {:source, ""},    # ::source::   the URL we got this URL from, if relevant
      {:body, ""},      # ::body::     page contents (empty before download and deleted after it's used)
      {:matches, []},   # ::matches::  regexes that matched this page
      {:rules, []}      # ::rules::    regexes used to test this page
    ]
    def download(item_info) do
      HTTPoison.start # don't move
      IO.puts item_info.url
      output = State.get(:output)
      case HTTPoison.get(item_info.url, [], [follow_redirect: true]) do
       {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          item_info = %{item_info|body: body}
          State.put(item_info.url, item_info)
          process_page(item_info)
       {:ok, %HTTPoison.Response{status_code: 404}} ->
         IO.puts ".. #{item_info.url}: Not found :("
       {:error, %HTTPoison.Error{reason: reason}} ->
         IO.puts ".. #{item_info.url}: error #{inspect reason}"
       {:ok, %HTTPoison.Response{status_code: status_code}} ->
         IO.puts ".. #{item_info.url}: unhandled code #{status_code}"
      end
    end
    def process_page(item_info) do
      match_list = item_info.rules|>Enum.map(fn(rule) -> match_page(item_info.body, rule) end )
      match_list = Enum.filter(match_list, fn(x)-> x end )
      if ! Enum.empty?(match_list) do
        State.put(item_info.url, %{State.get(item_info.url)|matches: match_list})
      end
    end
    def match_page(body, regex_rule) do
      regex = Helpers.string_to_regex(regex_rule)
      struct = [
        {:match,  Regex.match?(regex, body)},
        {:string, regex_rule} ]
      if struct[:match] do struct[:string] end
    end
  end # end webpage
