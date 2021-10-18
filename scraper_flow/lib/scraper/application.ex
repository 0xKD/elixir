defmodule Scraper.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      PageProducer,
      # since Process.whereis/1 is used (in OnlinePageConsumerProducer)
      # to get PID of PageConsumerSupervisor, it must be started first
      PageConsumerSupervisor,
      OnlinePageProducerConsumer
    ]

    opts = [strategy: :one_for_one, name: Scraper.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
