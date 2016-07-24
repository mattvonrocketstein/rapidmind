
defmodule WikiPage do
  use Neo4j.Sips.Model
  field :page_id, type: :integer, required: false
  field :title, required: true, unique: true
  field :text, required: false

  def node_url(node) do
    WikiPage.base_url() <> "/db/data/node/#{node.id}"
  end

  def base_url() do
    Application.get_all_env(:neo4j_sips)[Neo4j][:url]
  end

  def relationships_url(node) do
    WikiPage.node_url() <> "/relationships"
  end
  #relationship :LINKED_FROM, WikiPage

  def skip?(title) do
    title==nil or title=="" or
    String.starts_with?(title, "Talk:") or
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
        case WikiPage.find(title: title) do
          {:ok, [ page | _ ]} ->
            Events.page_retrieved(page)
          {:ok, []} ->
            {:ok, page} = WikiPage.create(title: title)
            Events.Events.page_created(page)
        end
      end
  end
  def get_subpages(text) do
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
    Common.user_msg("creating sub-page")
    get_or_create_from_title(title)
  end
  def create_or_update_from_state(state) do
    page = get_or_create_from_title(state.title)
    if page != nil do
        subpages = get_subpages(state.text)
        IO.puts("#{Enum.count(subpages)} outgoing links for #{state.title}")
        WikiPage.update(
          page,
          page_id: String.to_integer(state.id),
          text: state.text,
          #links_to: subpages
          )
          Events.page_updated(page)
          Enum.map(
            subpages,
            fn(subpage) ->
              json = %{
                to: WikiPage.node_url(page),
                type: "links_to"} |> Poison.encode!
              HTTPoison.post!(WikiPage.relationships_url(subpage), json)
            end)

        #WikiPage.save(page)
        Events.page_updated(page, state)
    end
  end
end
