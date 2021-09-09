defmodule Jobber do
  # so we can refer to Jobber.JobRunner and Jobber.Job without the namespace
  # looks like shell glob syntax
  alias Jobber.{JobRunner, Job, JobSupervisor}

  def start_job(args) do
    # old version, before JobSupervisor was introduced
    # DynamicSupervisor.start_child(JobRunner, {Job, args})

    # this allows us to limit jobs based on the type metadata
    if Enum.count(running_imports()) >= 5 do
      {:error, :import_quota_reached}
    else
      DynamicSupervisor.start_child(JobRunner, {JobSupervisor, args})
    end
  end

  def running_imports() do
    # yooo; wtf?
    match_all = {:"$1", :"$2", :"$3"}
    guards = [{:==, :"$3", "import"}]
    map_result = [%{id: :"$1", pid: :"$2", type: :"$3"}]

    # this is querying JobRegistry for processes of value "import"
    # where each process in the registry is tuple of form {name, pid, value}
    #
    # iex()> Jobber.start_job(work: good_job, type: "import")
    Registry.select(Jobber.JobRegistry, [{match_all, guards, map_result}])
  end
end
