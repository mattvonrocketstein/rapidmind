alias Callisto.{Query, Vertex}

defmodule WikiPage do
  #use Neo4j.Model
  #field :page_id, type: :integer, required: false
  #field :title, required: true, unique: true
  #field :text, required: false

  def skip?(title) do
    title==nil or title=="" or
    String.starts_with?(title, "Talk:") or
    String.starts_with?(title, "File:") or
    String.starts_with?(title, "User") or
    String.starts_with?(title, "MediaWiki:") or
    String.starts_with?(title, "Category:") or
    String.starts_with?(title, "Template:") or
    String.starts_with?(title, "Wikipedia") or
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
        PageEvents.created(title, nil)
        title
      end
  end
  def get_subpages(text) do
    Common.user_msg("extracting linked pages from text")
    link_regex = ~r/\[\[([\w\d\s])+\]\]/
    text_links = Enum.map(
      Regex.scan(link_regex, text),
      fn ([match, _]) ->
        match
        |> String.replace("[[","")
        |> String.replace("]]","")
      end)
    text_links = Enum.reject(
        text_links,
        &WikiPage.skip?/1)
    linked_pages = Enum.map(
      text_links,
      &get_or_create_sub_from_title/1)
    linked_pages = Enum.reject(linked_pages, fn(x)->x==nil end)
    linked_pages
  end

  def get_or_create_sub_from_title(title) do
    Common.user_msg("  creating sub-page: #{title}")
    #Task.start_link(fn -> get_or_create_from_title(title) end)
    get_or_create_from_title(title)
    title
  end
  def get_vertex(title) do
    Vertex.cast("WikiPage", %{'title' => to_string(title),})
  end
  def create_or_update_from_state(state) do
    title = get_or_create_from_title(state.title)
    if title != nil do
        subpages = get_subpages(state.text)
        IO.puts("#{Enum.count(subpages)} outgoing links for #{state.title}")
        u1 = get_vertex(state.title)
        page_id = String.to_integer(state.id)
        cypher=
          to_string(
            Query.merge(u1: u1)) <>
            " on match set u1.page_id=#{page_id} " <>
            to_string(Query.returning("ID(u1)"))
        IO.puts cypher
        {:ok, [result]} = DB.run(cypher)
        IO.puts inspect(result)
        Enum.map(
            subpages,
            fn(subpage_title) ->
              make_link(title, subpage_title)
            end)
        PageEvents.updated(title, state)
    end
  end
  def make_link(title,subpage_title) do
    q = %Query{}
    u1 = get_vertex(title)
    u2 = get_vertex(subpage_title)
    cypher = [
      Query.merge(u1: u1),
      Query.merge(u2: u2),
      Query.create("UNIQUE u1-[r:links_to]-u2"),
      Query.returning("r")
    ]
    cypher = cypher
    |> Enum.map(&to_string/1)
    |> Enum.join("\n")
    IO.puts cypher
    {:ok, [result]} = DB.run(cypher)
    #IO.puts "#{inspect result}"
    PageEvents.linked(title, subpage_title)
  end
end
