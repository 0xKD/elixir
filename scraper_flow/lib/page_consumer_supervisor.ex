defmodule PageConsumerSupervisor do
  use ConsumerSupervisor
  require Logger

  def start_link(_args) do
    ConsumerSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    Logger.info("PageConsumerSupervisor init")

    children = [
      %{
        id: SupervisorConsumer,
        start: {SupervisorConsumer, :start_link, []},
        restart: :transient
      }
    ]

    opts = [
      strategy: :one_for_one,
      # taken care of elsewhere using Flow
      subscribe_to: []
    ]

    ConsumerSupervisor.init(children, opts)
  end
end
