defmodule Jobber.Job do
  # only restart process if it is not exiting normally
  use GenServer, restart: :transient
  require Logger

  # define a struct, this takes the name of the module
  # behaves like a map for the most part
  defstruct [:work, :id, :max_retries, retries: 0, status: "new"]

  def init(args) do
    # fetch! will throw an error if :work is not provided in args
    work = Keyword.fetch!(args, :work)

    # this is from when start_link only had GenServer.start_link call
    # (no name: arg)
    # id = Keyword.get(args, :id, random_job_id())
    id = Keyword.get(args, :id)
    max_retries = Keyword.get(args, :max_retries, 3)

    state = %Jobber.Job{id: id, work: work, max_retries: max_retries}
    {:ok, state, {:continue, :run}}
  end

  # requried by DynamicSupervisor
  def start_link(args) do
    args =
      if Keyword.has_key?(args, :id) do
        args
      else
        # todo: would %{args | id: random_job_id()} work?
        Keyword.put(args, :id, random_job_id())
      end

    id = Keyword.get(args, :id)
    type = Keyword.get(args, :type)

    GenServer.start_link(__MODULE__, args, name: via(id, type))
  end

  # to handle :continue, :run that is returned at the end of init
  def handle_continue(:run, state) do
    # work attribute is an anonymous function (notice .() instead of () syntax)
    new_state = state.work.() |> handle_job_result(state)

    if new_state.status == "errored" do
      Process.send_after(self(), :retry, 5000)
      {:noreply, new_state}
    else
      Logger.info("Job exiting #{state.id}")
      {:stop, :normal, new_state}
    end
  end

  def handle_info(:retry, state) do
    # delegating to handle_continue on :retry
    {:noreply, state, {:continue, :run}}
  end

  def handle_job_result({:ok, _data}, state) do
    Logger.info("Job completed #{state.id}")
    %Jobber.Job{state | status: "done"}
  end

  def handle_job_result(:error, %{status: "new"} = state) do
    Logger.warn("Job errored #{state.id}")
    %Jobber.Job{state | status: "errored"}
  end

  def handle_job_result(:error, %{status: "errored"} = state) do
    Logger.warn("Job retry failed #{state.id}")
    new_state = %Jobber.Job{state | retries: state.retries + 1}

    if new_state.retries == state.max_retries do
      %Jobber.Job{new_state | status: "failed"}
    else
      new_state
    end
  end

  def random_job_id() do
    :crypto.strong_rand_bytes(5) |> Base.url_encode64(padding: false)
  end

  defp via(key, value) do
    # one of the formats used to name a process,
    # which is what this function returns
    # {:via, module, config} -> module takes care of registering value "config"
    # config is a tuple of {registry_process, key} or {registry_process, key, value}
    # where "value" can be used to store metadata against the process
    {:via, Registry, {Jobber.JobRegistry, {key, value}}}
  end
end
