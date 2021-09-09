defmodule Jobber.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # Supervisor will restart a process that keeps failing.
    # A process under the supervisor can restart upto 'max_restarts'
    # times within 'max_seconds' before it will crash (for good)
    #
    # If the process takes a while to crash, it may keep restarting
    # forever with default values for max_restarts (3) and max_seconds (5)
    config = [
      strategy: :one_for_one,
      max_seconds: 30,
      name: Jober.JobRunner
    ]

    children = [
      # Starts a worker by calling: Jobber.Worker.start_link(arg)
      # {Jobber.Worker, arg}
      {DynamicSupervisor, config}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Jobber.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
