alias Callisto.{Query, Vertex}

defmodule WikiPage do
  use Retry

  def skip?(title) do
    title==nil or title=="" or
    String.starts_with?(title, "Talk:") or
    String.starts_with?(title, "File:") or
    String.starts_with?(title, "User") or
    String.starts_with?(title, "Wikivoyage:") or
    String.starts_with?(title, "MediaWiki:") or
    String.starts_with?(title, "Category:") or
    String.starts_with?(title, "Template:") or
    String.starts_with?(title, "Wiki") or
    String.starts_with?(title, "Help")
  end

  def get_or_create_from_title(title) do
    case WikiPage.skip?(title) do
      true ->
        nil
      false ->
        u1 = get_vertex(title)
        cypher = Query.merge(node: u1)
        |> Query.returning("ID(node)")
        |> to_string
        {:ok, [%{"ID(node)" => node_id}]} = DB.run(cypher)
        title
      end
  end

  def get_linked_pages(text) do
    link_regex = ~r/\[\[([\w\d\s])+\]\]/
    text_links = Enum.map(
      Regex.scan(link_regex, text),
      fn ([match, _]) ->
        Regex.replace(~r/(\[\[|\]\])/, match, "")
      end)
    text_links = Enum.reject(
        text_links,
        &WikiPage.skip?/1)
    linked_pages = Enum.map(
      text_links,
      &get_or_create_from_title/1)
    linked_pages = Enum.reject(
      linked_pages,
      fn(x) -> x==nil end)
    linked_pages
  end

  def get_vertex(title) do
    Vertex.cast("WikiPage", %{'title' => to_string(title),})
  end

  def create_or_update_from_state(state) do
    #retry_args = lin_backoff(10, 2) |> cap(1_000) |> Stream.take(10)
    retry with: [100,200,500,1000] do
      create_or_update_from_state_retry(state) 
    end
  end
  def create_or_update_from_state_retry(state) do
    title = get_or_create_from_title(state.title)
    if title != nil do
      Common.user_msg("extracting linked pages for `#{title}`")
        linked_pages = get_linked_pages(state.text)
        IO.puts("#{Enum.count(linked_pages)} outgoing links for #{state.title}")
        page_id = String.to_integer(state.id)
        txt = String.replace(
          String.replace(state.text,"\\",""),
          "\"","")
        cypher = [
          Query.merge(u1: get_vertex(state.title)),
          " on match set u1.page_id=#{page_id}, u1.body=\"#{txt}\" ",
          Query.returning("ID(u1)") ]
          cypher = cypher
          |> Enum.map(&to_string/1)
          |> Enum.join
        {:ok, [result]} = DB.run(cypher)
        Enum.map(
            linked_pages,
            fn(subpage_title) ->
              make_link(title, subpage_title)
            end)
        title
    end
  end
  def make_link(title, subpage_title, relationship\\"links_to") do
    q = %Query{}
    u1 = get_vertex(title)
    u2 = get_vertex(subpage_title)
    cypher = [
      Query.merge(u1: u1),
      Query.merge(u2: u2),
      Query.create("UNIQUE (u1)-[r:"<>relationship<>"]-(u2)"),
      Query.returning("r")
    ]
    cypher = cypher
    |> Enum.map(&to_string/1)
    |> Enum.join("\n")
    {:ok, [result]} = DB.run(cypher)
  end
end
