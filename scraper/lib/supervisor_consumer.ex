defmodule SupervisorConsumer do
  require Logger

  def start_link(event) do
    Logger.info("SupervisorConsumer received #{event}")

    Task.start_link(fn -> Scraper.work() end)
  end
end
