defmodule Scraper.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # shorthand for {Child, []}
      # used when no options need to be passed
      PageProducer,
      # PageConsumer,
      #
      # adding multiple consumers
      # Supervisor.child_spec(PageConsumer, id: :consumer_one),
      # Supervisor.child_spec(PageConsumer, id: :consumer_two)
      PageConsumerSupervisor
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Scraper.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
