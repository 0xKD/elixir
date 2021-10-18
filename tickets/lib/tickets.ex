defmodule Tickets do
  def pretend_work(range) do
    Process.sleep(Enum.random(range))
  end

  # def tickets_available?("cinema") do
  #   pretend_work(100..200)
  #   false
  # end

  def tickets_available?(_event) do
    pretend_work(100..200)
    true
  end

  def create_ticket(_user, _event) do
    pretend_work(250..500)
  end

  def create_tickets(messages) do
    count = Enum.count(messages)
    pretend_work((count * 100)..(count * 250))
    messages
  end

  def send_email(_event) do
    pretend_work(100..250)
  end

  @users [
    %{id: "1", email: "foo@bar.baz"},
    %{id: "2", email: "hello@world.com"},
    %{id: "3", email: "john@doe.me"}
  ]

  def users_by_ids(ids) when is_list(ids) do
    Enum.filter(@users, &(&1.id in ids))
  end
end
