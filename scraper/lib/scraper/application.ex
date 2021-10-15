defmodule Scraper.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: ProducerConsumerRegistry},
      # shorthand for {Child, []}
      # used when no options need to be passed
      PageProducer,
      # introduced later; ordering matters, this must exist
      # before because producers must be started before consumers
      # OnlinePageProducerConsumer,
      # adding multiple OPPC
      producer_consumer_spec(id: 1),
      producer_consumer_spec(id: 2),
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

  def producer_consumer_spec(id: id) do
    id = "online_page_producer_consumer_#{id}"
    Supervisor.child_spec({OnlinePageProducerConsumer, id}, id: id)
  end
end
