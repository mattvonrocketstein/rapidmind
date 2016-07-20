defmodule WikiPage do
  use Neo4j.Sips.Model

  field :title, required: true, unique: true
  field :text, required: true
  field :neo4j_sips, type: :boolean, default: true

  relationship :LINKS_TO, WikiPage
  #relationship :LINKED_FROM, WikiPage

  def skip?(title) do
    String.starts_with?(title, "Talk:") or
    String.starts_with?(title, "User") or
    String.starts_with?(title, "MediaWiki:") or
    String.starts_with?(title, "Category:") or
    String.starts_with?(title, "Wikipedia") or
    String.starts_with?(title, "Help")
  end

  def page_created_event(page) do
    Common.user_msg("✓ #{page.title}")
  end

  def update_page_event(page) do
    Common.user_msg("✖ #{page.title}")
  end

  def create_or_update(state) do
      title = state.title
      case WikiPage.skip?(state.title) do
        true ->
          nil
        false ->
          case WikiPage.create(
            title: state.title,
            text: state.text
            #links_to: [links]
            ) do
            {:ok, page} ->
              page_created_event(page)
            {:nok, nil, page} ->
              update_page_event(page)
          end
      end
      state
  end
end
#link_regex = ~r/\[\[([\w\d\s])+\]\]/
#text_links = Enum.map(
#  Regex.scan(link_regex, state.text),
#  fn ([match, _]) ->
#    match
#    |> String.replace("[[","")
#    |> String.replace("]]","")
#  end)
#  text_links = Enum.filter(
#    text_links,
#    &WikiPage.skip?/1)
#  IO.puts(text_links)
#Enum.map(
#  links,
#  fn ([match, _]) ->
#    IO.puts("  #{match}")
#    create_link(wikipage_node, match)
#  end)
#Neo4j.query(Neo4j.conn, cypher)
