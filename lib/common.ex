defmodule Common do
  def user_msg(msg) do
    msg = IO.ANSI.blue() <> msg <> IO.ANSI.reset()
    IO.puts(msg)
  end
  def error_msg(msg) do
    msg = IO.ANSI.red() <> msg <> IO.ANSI.reset()
    IO.puts(msg)
  end
end
