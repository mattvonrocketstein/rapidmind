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
    num_rules = Enum.count(result)
    tmp = Enum.join(result,",")
    print "Read #{num_rules} rules: #{tmp}"
    result
  end
end