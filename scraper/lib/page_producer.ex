defmodule PageProducer do
  use GenStage
  require Logger

  def start_link(_args) do
    initial_state = []
    GenStage.start_link(__MODULE__, initial_state, name: __MODULE__)
  end

  def init(initial_state) do
    Logger.info("PageProducer init")
    # Indicates the type of stage process, in this case, a producer
    # other types - :consumer, :producer_consumer
    {:producer, initial_state}
  end

  # called by the consumer
  # required when type is :producer or :producer_consumer
  def handle_demand(demand, state) do
    # demand: number of events requested by consumer
    # state: internal state of the producer
    #
    Logger.info("PageProducer received demand for #{demand} pages")
    events = []
    {:noreply, events, state}
  end

  # public API that can be used to dispatch events to consumers
  def scrape_pages(pages) when is_list(pages) do
    GenStage.cast(__MODULE__, {:pages, pages})
  end

  # handle_demand/2 may not be suitable for all types of work since
  # it is consumer-driven, expecting the producer to have a steady
  # steam of events to return for processing.
  # We can use a GenServer callback to instead dispatch stuff to
  # the consumers
  def handle_cast({:pages, pages}, state) do
    # pages contains the list of events to dispatch
    {:noreply, pages, state}
  end
end
