

defmodule PageEvents do
  def created(page, state) do
    Common.user_msg("created: #{page}")
    page
  end
  def linked(page1, page2) do
    Common.user_msg(" linked: #{page1} -> #{page2}")
  end

  def updated(page, state) do
    Common.user_msg("updated: #{page}")
    page
  end
  def retrieved(page) do
    Common.user_msg("retrieved: #{page}")
    page
  end
end
