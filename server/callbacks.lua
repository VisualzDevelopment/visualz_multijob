lib.callback.register("visualz_multijob:getPlayerJobs", function(source)
  return GetPlayerJobs(source)
end)

lib.callback.register("visualz_multijob:saveJob", function(source)
  return SaveJob(source)
end)

lib.callback.register("visualz_multijob:leaveJob", function(source)
  return LeaveJob(source)
end)

lib.callback.register("visualz_multijob:selectJob", function(source, jobName)
  return SelectJob(source, jobName)
end)

lib.callback.register("visualz_multijob:removeJob", function(source, jobName)
  return RemoveJob(source, jobName)
end)
