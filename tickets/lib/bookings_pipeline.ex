defmodule BookingsPipeline do
  use Broadway

  @producer BroadwayRabbitMQ.Producer

  # specific to RMQ
  @producer_config [
    queue: "bookings_queue",
    declare: [durable: true],
    on_failure: :reject_and_requeue
  ]

  def start_link(_args) do
    options = [
      # used as prefix when naming processes
      name: BookingsPipeline,
      # contains config about source of events; in this case, RMQ
      # "modue" manages connection to the message broker
      producer: [module: {@producer, @producer_config}],
      # processors receive events and perform work
      processors: [default: []],
      # required for handle_batch/4
      batchers: [cinema: [], musical: [], default: []]
    ]

    Broadway.start_link(__MODULE__, options)
  end

  # Incoming messages sent by broker are processed by this;
  # Code within is executed by a processor (outside current process)
  # unlike the callbacks in GenServer and GenStage
  def handle_message(_processor, message, _context) do
    # message is a Broadway.Message{} struct,
    # and this callback must also return the same type
    %{data: %{event: event}} = message

    if Tickets.tickets_available?(event) do
      # These operations were moved to the batcher later
      #
      # Tickets.create_ticket(user, event)
      # Tickets.send_email(user)
      # IO.inspect(message, label: "Message")
      case event do
        "cinema" -> Broadway.Message.put_batcher(message, :cinema)
        "musical" -> Broadway.Message.put_batcher(message, :musical)
        _ -> message
      end
    else
      # these go to handle_failed/2
      Broadway.Message.failed(message, "bookings-closed")
    end
  end

  # like handle_message/3, code runs in a special batch processor
  # messages returned by handle_message/3 go to a batcher
  def handle_batch(_batcher, messages, batch_info, _context) do
    # messages is a BatchInfo{} struct
    IO.inspect(batch_info, label: "#{inspect(self())} Batch")

    messages
    |> Tickets.create_tickets()
    # Earlier this pipeline handled sending emails as well
    # |> Enum.each(fn %{data: %{user: user}} -> Tickets.send_email(user) end)
    |> Enum.each(fn message ->
      channel = message.metadata.amqp_channel
      payload = "email,#{message.data.user.email}"
      AMQP.Basic.publish(channel, "", "notifications_queue", payload)
    end)

    messages
  end

  def handle_failed(messages, _context) do
    IO.inspect(messages, label: "Failed messages")

    Enum.map(messages, fn
      %{status: {:failed, "bookings-closed"}} = message ->
        Broadway.Message.configure_ack(message, on_failure: :reject)

      message ->
        message
    end)
  end

  # gets messages in bulk, useful for doing batch ops
  # runs before handle_message
  # Any errors here will cause the entire batch to be marked as failed
  def prepare_messages(messages, _context) do
    messages =
      Enum.map(messages, fn message ->
        Broadway.Message.update_data(message, fn data ->
          # message from broker is CSV
          [event, user_id] = String.split(data, ",")
          %{event: event, user_id: user_id}
        end)
      end)

    users = Tickets.users_by_ids(Enum.map(messages, & &1.data.user_id))

    Enum.map(messages, fn message ->
      Broadway.Message.update_data(message, fn data ->
        user = Enum.find(users, &(&1.id == data.user_id))
        Map.put(data, :user, user)
      end)
    end)
  end
end
