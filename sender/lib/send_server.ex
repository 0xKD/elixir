defmodule SendServer do
  # this is a "behaviour"; OO equivalent is subclassing
  use GenServer

  # iex()> {:ok, pid} = GenServer.start(SendServer, [max_retries: 3])
  def init(args) do
    # this callback runs as soon as process starts, initializing state
    IO.puts("Received arguments: #{inspect(args)}")
    max_retries = Keyword.get(args, :max_retries, 5)
    # emails is to keep track of emails sent
    state = %{emails: [], max_retries: max_retries}

    # send a :retry message to self after 5s delay
    Process.send_after(self(), :retry, 5000)

    # :ok indicates successful initialization
    # other possible return values are :stop, :ignore for failed init
    # where supervisor will restart a :stop, but not an :ignore
    {:ok, state}
  end

  # iex()> GenServer.call(pid, :get_state)
  def handle_call(:get_state, _from, state) do
    # a way to communicate with the genserver that returns something
    {:reply, state, state}
  end

  def handle_cast({:send, email}, state) do
    # acks immediately, doing actual work in the background,
    # in contrast to call/3 which returns value to caller
    #
    # even if this is done in the background, there is only a single
    # process handling these and calling GenServer.call while process
    # is busy will result in timeout

    status =
      case Sender.send_email(email) do
        {:ok, "email_sent"} -> "sent"
        :error -> "failed"
      end

    # prepend to list, similar to python's [1] + [2] == [1, 2]
    emails = [%{email: email, status: status, retries: 0}] ++ state.emails
    # return map with updated value for key "emails"
    {:noreply, %{state | emails: emails}}
  end

  # handle_info is the internal equivalent of handle_cast,
  # meant for system/internal use
  def handle_info(:retry, state) do
    # this is like python's filter but returns two items
    # first that matched the conditional, and the rest that didn't
    {failed, done} =
      Enum.split_with(state.emails, fn item ->
        item.status == "failed" && item.retries < state.max_retries
      end)

    # updated values for "retried" after attempting to send email again
    retried =
      Enum.map(failed, fn item ->
        IO.puts("Retrying email #{item.email}...")

        new_status =
          case Sender.send_email(item.email) do
            {:ok, "email_sent"} -> "sent"
            :error -> "failed"
          end

        %{email: item.email, status: new_status, retries: item.retries + 1}
      end)

    Process.send_after(self(), :retry, 5000)
    {:noreply, %{state | emails: done ++ retried}}
  end

  def terminate(reason, _state) do
    # called when process is responsible for stopping
    # .e.g a :stop response from a callback or an unhandled exception
    IO.puts("Terminating: #{reason}")
  end
end
