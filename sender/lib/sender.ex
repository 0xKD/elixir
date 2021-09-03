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
    # if it doesn't return until then
    # Enum.map instead of Enum.each because we need to use the results
    emails
      |> Enum.map(fn email -> Task.async(fn -> send_email(email) end) end)
      |> Enum.map(&Task.await/1)
  end
end

