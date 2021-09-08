defmodule Sender do
  @moduledoc """
  Documentation for Sender.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Sender.hello()
      :world

  """
  def hello do
    :world
  end

  def send_email("hello@world.com" = _email) do
    # raise "#{email} is meant to fail!"
    :error
  end

  def send_email(email) do
    Process.sleep(2000)
    IO.puts("Email to #{email} sent")
    {:ok, "email_sent"}
  end

  def notify_all(emails) do
    # Enum.each executes synchronously
    Enum.each(emails, &send_email/1)
  end

  def notify_async(emails) do
    # The queueing of tasks is still sync, but they execute asynchronously with Task.start
    Enum.each(emails, fn email -> Task.start(fn -> send_email(email) end) end)
  end

  def notify_async_await(emails) do
    # await is blocking, has default 5s timeout and will kill the task
    # if it doesn't return until end of the timeout
    # Enum.map instead of Enum.each because it returns the result
    emails
    |> Enum.map(fn email -> Task.async(fn -> send_email(email) end) end)
    |> Enum.map(&Task.await/1)
  end

  def notify_stream(emails) do
    emails
    |> Task.async_stream(&send_email/1)
    # optional arguments, ordering=true by default, and there's a default timeout of 5s
    # if a task reaches the timeout, the stream crahes (!)
    #
    # |> Task.async_stream(&send_email/1, max_concurrency: 2, ordered: false, on_timeout: :kill_task)
    |> Enum.to_list()
  end

  def notify_safe_stream(emails) do
    Sender.EmailTaskSupervisor
    |> Task.Supervisor.async_stream_nolink(emails, &send_email/1)
    |> Enum.to_list()
  end
end
