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
                      [{:continuation_function, &continue_file/2, c_state}])

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
        IO.puts "#{state.title}"
        count = 0
        Enum.map(
          Regex.scan(
            ~r/\[\[([\w\d\s])+\]\]/,
            state.text),
          fn ([match, _]) ->
            IO.puts("  #{match}")
            count = count + 1
          end)
      true ->
        nil
    end
    IO.puts("Total links out: #{count}")
    state
    #IO.puts "Text:  #{state.text}"
  end
  def sax_event_handler({:characters, value}, %SaxState{element_acc: element_acc} = state) do
    %{state | element_acc: element_acc <> to_string(value)}
  end
  def skip?(state) do
    String.starts_with?(state.title, "Talk:") or
    String.starts_with?(state.title, "User") or
    String.starts_with?(state.title, "Wikipedia") or
    String.starts_with?(state.title, "Help")
  end
  def sax_event_handler(:endDocument, state) do
    state
  end
  def sax_event_handler(_, state) do
     state
  end
end
