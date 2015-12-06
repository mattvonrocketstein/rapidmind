require IEx
require Charm
require Logger

defmodule Cell do
  @moduledoc """
  	Things and stuff.....
  """
  use ExActor.GenServer
  @colors [
  	&Colors.green/1, 
  	&Colors.red/1, 
  	&Colors.white/1,
  	&Colors.cyan/1, 
  	&Colors.grey/1,
  	&Colors.magenta/1,
  	&Colors.black/1, 
  	&Colors.yellow/1, 
  	&Colors.blue/1,]
  
  @num_colors Enum.count(@colors)

  defstart start_link({x, y, val}, {rows, cols}) do
  	#IO.puts("creating #{inspect {x,y}}")
  	initial_state({{x, y, val}, {rows, cols}})
  end
  
  defcast iterate(grid), state: state do
  	{{x, y, val}, boring} = state
  	#val=val+1
  	val = Enum.sum(
  		Enum.map(
  			Automata.neighbors(state),
  			fn [nx, ny] -> 
	  			cell = HashDict.get(grid, {nx, ny})
				state = Cell.get(cell)
  				{{_,_,v}, _} = state
  				v
  			end)
  		)
  	newish = {x, y, val}
  	#IO.puts("iterating #{inspect newish}")
  	new_state({newish, boring})
  end
  
  defcall paint(), state: state do 	
  	#reply(do_paint(state))
	#state = Cell.get(cell)
	{{x, y, val}, _} = state
  	Charm.position(x, y)
  	val = String.slice(inspect(val), -1, 1)
  	val = String.to_integer(val)
  	tmp = rem(val, 4)#@num_colors)
  	f = Enum.at(@colors, tmp)
  	Charm.write f.(inspect(val))
  	reply(state)
  end  
  
  defcall get(), state: state, do: reply(state)
  
  defcast stop(), do: stop_server(:normal)
end

	

defmodule Automata do
  @moduledoc """
  	Things and stuff.....
  """
  use Application
  def start(_type, _args) do Automata.Supervisor.start_link end
  def main(args) do args |> parse_args |> process end
  #def main() do process end
  @spec parse_args(Enum) :: Map
  defp parse_args(args) do
    switches = [
      help:   :boolean,
      debug:  :boolean,
      reddit: :string,
      rules:  :string ]
    {options, _, _} = OptionParser.parse(args, switches: switches)
    options
  end

  def neighbors(state) do
  	{{x, y, _}, {rows, cols}} = state
  	Enum.filter(
  		[
  			[x-1, y],
  			#[x+1,y],
  			[x, y+1],
  			[x, y-1]
  			],
  		fn [nx, ny] ->
  			nx>0 and ny>0 and nx<=rows and ny<=cols
  		end)
  end
  defp process([]) do 
  	IO.puts "Incorrect usage (use --help for help)" 
  	{rows, cols} = {55, 30}
  	Charm.reset
  	#Charm.insert
  	cells = make_cells(rows, cols)
  	|> List.flatten
  	#:timer.sleep(100)
  	grid = Enum.into(
  		Enum.map(cells, 
  		fn c ->
  			{{x,y,v}, _} = Cell.get(c)
  			{{x,y}, c}
  		end),
  		HashDict.new)
  	#Apex.ap grid #{2,1})
	#raise grid
  	for n<-1..1000 do 
    		Enum.map(cells,
  		fn cell ->#for i <- 1..Enum.count(cells) do
  		:timer.sleep(1)
  		Cell.paint(cell)
  		Charm.position(0,70)
  		Cell.iterate(cell, grid)
  		#IO.puts("#{inspect Cell.get(cell)}, #{inspect Cell.neighbors(cell)}")
  		end)
  		#Charm.reset
  	end
  end
  
  def make_cells(rows, cols) do
  	out = Enum.map(
  		0..rows,
  		fn x ->
  			Enum.map(
  				0..cols, 
  				fn y ->
  					:random.seed(:erlang.now())
  					rando = :random.uniform(9)
  					v = rando#Random.random(5)
  					{:ok, cell} = Cell.start_link({x, y, v}, {rows, cols})
  					cell
  				end)
  		end
  		)
  	#raise Enum.count(Enum.first(out))
  end
  
  @spec process(any) :: any
  defp process(:help) do
    IO.puts """
      Usage:
        automata --cells [num_cells]

      Options:
        --cells  specify rules to use (a file containing JSON)
        --help   Show this help message
    """
  end
  defp process(options) do
    #{:ok, record} = State.start_link(options)
    cond do
      options[:help]  -> process(:help)
      #options[:cells] -> process(:cells) 
      true            -> 
      	process([])
  	end
  end
end
