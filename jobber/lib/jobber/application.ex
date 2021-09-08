defmodule Jobber.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # todo: figure out max_seconds and max_restarts
    # supervisor will restart if a process keeps failing
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
