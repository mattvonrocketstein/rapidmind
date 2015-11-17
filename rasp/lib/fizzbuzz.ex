defmodule FizzBuzz do
	
  use GenServer
	require Logger
	
  def start_link do GenServer.start_link(__MODULE__, :ok, name: __MODULE__) end
	def get(n) do GenServer.call(__MODULE__, {:print, n}) end
	def print(n) do GenServer.cast(__MODULE__, {:print, n}) end

	def init(:ok) do
  		Logger.debug "FizzBuzz server started"
  		{:ok, %{}}
	end

	def handle_call({:print, n}, _from, state) do
  		{:ok, fb, state} = fetch_or_calculate(n, state)
  		{:reply, fb, state}
	end

	def handle_cast({:print, n}, state) do
  		{:ok, fb, state} = fetch_or_calculate(n, state)
  		IO.puts "casted #{fb}"
  		{:noreply, state}
	end

  defp fetch_or_calculate(n, state) do
    if Dict.has_key?(state, n) do
      Logger.debug "Fetching #{n}"
      {:ok, fb} = Dict.fetch(state, n)
    else
      Logger.debug "Calculating #{n}"
      fb = fizzbuzz(n)
      state = Dict.put(state, n, fb)
    end
    {:ok, fb , state}
  end

  defp fizzbuzz(n) do
    case {rem(n, 3), rem(n, 5)} do
      {0, 0} -> :FizzBuzz
      {0, _} -> :Fizz
      {_, 0} -> :Buzz
      _      -> n
    end
  end
end
