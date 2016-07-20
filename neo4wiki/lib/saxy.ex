defmodule WikiPage do
  use Neo4j.Sips.Model

  field :title, required: true, unique: true
  field :text, required: true
  field :neo4j_sips, type: :boolean, default: true

  relationship :LINKS_TO, WikiPage
  #relationship :LINKED_FROM, WikiPage
end
defmodule Saxy do
  defmodule SaxState do
    defstruct title: "", text: "", element_acc: ""
  end

  @chunk 10000

  def run(path) do
    {:ok, handle} = File.open(path, [:binary])

    position           = 0
    c_state            = {handle, position, @chunk}
    sax_callback_state = nil

    :erlsom.parse_sax("",
                      sax_callback_state,
                      &sax_event_handler/2,
                      [{:continuation_function,
                       &continue_file/2, c_state}])

    :ok = File.close(handle)
  end

  def continue_file(tail, {handle, offset, chunk}) do
    case :file.pread(handle, offset, chunk) do
      {:ok, data} ->
        {<<tail :: binary, data::binary>>, {handle, offset + chunk, chunk}}
      :oef ->
        {tail, {handle, offset, chunk}}
    end
  end
  def skip?(state) do
    String.starts_with?(state.title, "Talk:") or
    String.starts_with?(state.title, "User") or
    String.starts_with?(state.title, "Wikipedia") or
    String.starts_with?(state.title, "Help")
  end

    def create_node(state) do
      title = state.title
      Common.user_msg("creating #{title}")
      {:ok,page} = WikiParser.create(
        title: title,
        text: state.text)
      IO.puts(page)
      #Neo4j.query(Neo4j.conn, cypher)
    end

    def create_link(state, page) do
      #IO.puts("  creating link: #{page}")
    end

  def sax_event_handler({:startElement, _, 'title', _, _}, _state) do
    %SaxState{}
  end

  def sax_event_handler({:startElement, _, 'text', _, _}, state) do
    %{state | element_acc: ""}
  end

  def sax_event_handler({:endElement, _, 'title', _}, state) do
    %{state | title: state.element_acc}
  end

  def sax_event_handler({:endElement, _, 'text', _}, state) do
    state = %{state | text: state.element_acc}
    cond do
      not skip?(state) ->
        create_node(state)
        Enum.map(
          Regex.scan(
            ~r/\[\[([\w\d\s])+\]\]/,
            state.text),
          fn ([match, _]) ->
            IO.puts("  #{match}")
            create_link(state, match)
          end)
      true ->
        nil
    end
    state
    #IO.puts "Text:  #{state.text}"
  end
  def sax_event_handler(:endDocument, state) do
    state
  end
  def sax_event_handler({:characters, value}, %SaxState{element_acc: element_acc} = state) do
    %{state | element_acc: element_acc <> to_string(value)}
  end

  def sax_event_handler(_, state) do
     state
  end
end
