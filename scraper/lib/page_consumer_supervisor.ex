defmodule PageConsumerSupervisor do
  # ConsumerSupervisor will help start separate consumer processes
  # to process events from the producer (one at a time)
  # It will wait for child processes to exit successfully
  # before issuing new demand
  use ConsumerSupervisor
  require Logger

  def start_link(_args) do
    ConsumerSupervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    Logger.info("PageConsumerSupervisor init")

    children = [
      %{
        id: SupervisorConsumer,
        start: {SupervisorConsumer, :start_link, []},
        # :temporary is the only other option available here
        restart: :transient
      }
    ]

    opts = [
      strategy: :one_for_one,
      # max_demand here indicates the max number of child
      # (SupervisorConsumer) processes that can run concurrently
      #
      # from before OnlinePageProducerConsumer was introduced
      # subscribe_to: [{PageProducer, max_demand: 2}]
      # when OPPC was a singled un-named process
      # subscribe_to: [{OnlinePageProducerConsumer, max_demand: 2}]
      subscribe_to: [
        {OnlinePageProducerConsumer.via("online_page_producer_consumer_1"), []},
        {OnlinePageProducerConsumer.via("online_page_producer_consumer_2"), []}
      ]
    ]

    ConsumerSupervisor.init(children, opts)
  end
end
