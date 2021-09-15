defmodule Scraper do
  @moduledoc """
  Documentation for Scraper.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Scraper.hello()
      :world

  """
  def hello do
    :world
  end

  def work() do
    # 1..5 is a "range"
    #
    # iex()> Enum.to_list(1..5)
    # [1, 2, 3, 4, 5]
    1..5
    |> Enum.random()
    |> :timer.seconds()
    |> Process.sleep()
  end
end
