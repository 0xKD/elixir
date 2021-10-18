defmodule Scraper do
  def hello do
    :world
  end

  def online?(_url) do
    work()
    Enum.random([true, false, true])
  end

  def work() do
    1..5
    |> Enum.random()
    |> :timer.seconds()
    |> Process.sleep()
  end
end
