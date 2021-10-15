defmodule Airports do
  alias NimbleCSV.RFC4180, as: CSV

  @moduledoc """
  Documentation for Airports.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Airports.hello()
      :world

  """
  def hello do
    :world
  end

  def airports_csv() do
    # join path of airports app and /priv/airports.csv
    Application.app_dir(:airports, "/priv/airports.csv")
  end

  def open_airports_slow() do
    airports_csv()
    # reads entire file in memory
    |> File.read!()
    |> CSV.parse_string()
    |> Enum.map(fn row ->
      %{
        id: Enum.at(row, 0),
        type: Enum.at(row, 2),
        name: Enum.at(row, 3),
        country: Enum.at(row, 8)
      }
    end)
    |> Enum.reject(&(&1.type == "closed"))
  end

  # This is much faster (5x v/s. _slow) but hard to understand why;
  # 9MB (airports.csv) isn't a lot to hold in memory and process at once
  def open_airports_fast() do
    airports_csv()
    |> File.stream!()
    |> CSV.parse_stream()
    |> Stream.map(fn row ->
      %{
        id: :binary.copy(Enum.at(row, 0)),
        type: :binary.copy(Enum.at(row, 2)),
        name: :binary.copy(Enum.at(row, 3)),
        country: :binary.copy(Enum.at(row, 8))
      }
    end)
    |> Stream.reject(&(&1.type == "closed"))
    |> Enum.to_list()
  end

  # using a lib called Flow for parallel processing
  # it uses GenStage underneath
  def open_airports() do
    airports_csv()
    |> File.stream!()
    # this version where CSV is parsed up front is slower (2x)
    # |> CSV.parse_stream()
    |> Flow.from_enumerable()
    |> Flow.map(fn row ->
      [row] = CSV.parse_string(row, skip_headers: false)

      # without inline CSV.parse_string, this would require binary.copy
      %{
        id: Enum.at(row, 0),
        type: Enum.at(row, 2),
        name: Enum.at(row, 3),
        country: Enum.at(row, 8)
      }
    end)
    |> Flow.reject(&(&1.type == "closed"))
    |> Enum.to_list()
  end
end
