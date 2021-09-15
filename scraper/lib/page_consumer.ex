defmodule PageConsumer do
  use GenStage
  require Logger

  def start_link(_args) do
    initial_state = []
    GenStage.start_link(__MODULE__, initial_state)
  end

  def init(initial_state) do
    Logger.info("PageConsumer init")
    # subscribing to PageProducer, thereby linking producer & consumer
    # can also be done during runtime using sync/async_subscribe

    # min_demand: indicate the minimum amount of tasks for the consumer
    # to start processing. max_demand is max consumer can ask for at one
    # time. max_demand - min_demand is the the effective batch size i.e
    # it will process those many events at a time.
    # min_demand=0 means consumer will take at least one event when it is available
    #
    # max_demand>1 for when a single consumer can process multiple
    # events or max_demand=1 when there are multiple consumers,
    # each handling one event at a time
    options = {PageProducer, min_demand: 0, max_demand: 1}
    {:consumer, initial_state, subscribe_to: [options]}
  end

  def handle_events(events, _from, state) do
    Logger.info("PageConsumer received #{inspect(events)}")
    Enum.each(events, fn _page -> Scraper.work() end)
    {:noreply, [], state}
  end
end
