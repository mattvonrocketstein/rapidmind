defmodule SaxState do
  defstruct title: "", text: "", element_acc: "", id: ""
end

defmodule WikiDumpParser do
  @moduledoc """
  Abstract WikiMedia dump parser.

  Specific parsers must extend this module with "use WikiDumpParser"
  """
  defmacro __using__(_) do
    quote do
      @chunk 10000

      def run(path) do
        result = File.open(path, [:binary])
        case result do
          {:ok, handle} ->
            run_with_file_handle(handle)
          {:error, :eacces} ->
            Common.error_msg("Do you have read-access to #{path}?")
            System.halt(1)
        end
      end
      def run_with_file_handle(handle) do
        position           = 0
        c_state            = {handle, position, @chunk}
        sax_callback_state = nil
        :erlsom.parse_sax(
          "",
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
      def sax_event_handler({:startElement, _, 'title', _, _}, _state) do
        %SaxState{}
      end
      def sax_event_handler({:startElement, _, 'text', _, _}, state) do
        %{state | element_acc: ""}
      end
      def sax_event_handler({:startElement, _, 'id', _, _}, state) do
        %{state | element_acc: ""}
      end
      def sax_event_handler({:endElement, _, 'title', _}, state) do
        %{state | title: state.element_acc}
      end
      def sax_event_handler({:endElement, _, 'id', _}, state) do
        case state.id == "" do
          false ->
            state
          true ->
            %{state | id: state.element_acc}
        end
      end
      def sax_event_handler({:endElement, _, 'text', _}, state) do
        %{state | text: state.element_acc}
      end
      def sax_event_handler({:endElement, x_, 'page', y_}, state) do
        __MODULE__.page_callback(state)
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
  end
end
