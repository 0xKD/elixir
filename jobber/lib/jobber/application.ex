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
      # this name is used to find the process using Process.whereis/1
      name: Jobber.JobRunner
    ]

    children = [
      # Registry acts as k-v store to maintain process names as strings
      # it is being included here to run as a process under the supervisor
      {Registry, keys: :unique, name: Jobber.JobRegistry},
      {DynamicSupervisor, config}
    ]

    opts = [strategy: :one_for_one, name: Jobber.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
