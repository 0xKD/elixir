defmodule Jobber do
  # so we can refer to Jobber.JobRunner and Jobber.Job without the namespace
  # looks like shell glob syntax
  alias Jobber.{JobRunner, Job}

  def start_job(args) do
    DynamicSupervisor.start_child(JobRunner, {Job, args})
  end
end
