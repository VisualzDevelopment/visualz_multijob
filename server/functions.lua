function RefreshJobs()
  local Jobs = {}
  local jobs = MySQL.query.await("SELECT * FROM jobs")

  for _, v in ipairs(jobs) do
    Jobs[v.name] = v
    Jobs[v.name].grades = {}
  end

  local jobGrades = MySQL.query.await("SELECT * FROM job_grades")

  for _, v in ipairs(jobGrades) do
    if Jobs[v.job_name] then
      Jobs[v.job_name].grades[tostring(v.grade)] = v
    end
  end

  for _, v in pairs(Jobs) do
    if ESX.Table.SizeOf(v.grades) == 0 then
      Jobs[v.name] = nil
    end
  end

  if not Jobs then
    return
  end

  JobsCache = Jobs
end

function GetPlayerJobsUtil(xPlayer)
  local playerDB = MySQL.single.await("SELECT `jobs` FROM `users` WHERE `identifier` = ? LIMIT 1", {
    xPlayer.identifier
  })

  local playerJobs = json.decode(playerDB.jobs)
  if not playerJobs then
    return { data = {}, success = false, error = "Der skete en fejl, prøv igen senere." }
  end

  return { data = playerJobs, success = true, error = nil }
end

function GetPlayerJobs(source)
  if not Config.Features.ListJobs.enabled then
    return {}
  end

  local xPlayer = ESX.GetPlayerFromId(source)
  if not xPlayer then return {} end

  local playerJobResponse = GetPlayerJobsUtil(xPlayer)
  if not playerJobResponse.success then
    return {}
  end

  table.insert(playerJobResponse.data, 1, { name = "unemployed", grade = 0 })

  for _, job in ipairs(playerJobResponse.data) do
    local jobData = JobsCache[job.name]
    if jobData then
      job.label = jobData.label
      job.grade_label = jobData.grades[tostring(job.grade)].label
    end
  end

  table.sort(playerJobResponse.data, function(a, b)
    if a.name == "unemployed" then
      return true
    elseif b.name == "unemployed" then
      return false
    else
      return a.name < b.name
    end
  end)

  return playerJobResponse.data
end

function SaveJob(source)
  if not Config.Features.SaveJob.enabled then
    return { type = "error", message = "Denne funktion er ikke aktiveret." }
  end

  local xPlayer = ESX.GetPlayerFromId(source)
  if not xPlayer then return { type = "error", message = "Der skete en fejl, prøv igen senere." } end

  if xPlayer.job.name == "unemployed" then
    return { type = "error", message = "Du har ikke noget job." }
  end

  local playerJobsResponse = GetPlayerJobsUtil(xPlayer)
  if not playerJobsResponse.success then
    return { type = "error", message = playerJobsResponse.error }
  end

  local foundJob, index = false, nil
  for index, job in ipairs(playerJobsResponse.data) do
    if job.name == xPlayer.job.name then
      if job.grade == xPlayer.job.grade then
        return { type = "error", message = "Du har allerede dette job gemt." }
      end

      job.grade = xPlayer.job.grade
      foundJob, index = true, index
      break
    end
  end

  if not foundJob then
    playerJobsResponse.data[#playerJobsResponse.data + 1] = { name = xPlayer.job.name, grade = xPlayer.job.grade }
  else
    table.remove(playerJobsResponse.data, index)
    playerJobsResponse.data[#playerJobsResponse.data + 1] = { name = xPlayer.job.name, grade = xPlayer.job.grade }
  end

  local saveJobDB = MySQL.insert.await("UPDATE `users` SET `jobs` = ? WHERE `identifier` = ?", {
    json.encode(playerJobsResponse.data), xPlayer.identifier
  })

  if not saveJobDB then
    return { type = "error", message = "Der skete en fejl, prøv igen senere." }
  end

  return { type = "success", message = "Dit job er nu gemt." }
end

function LeaveJob(source)
  if not Config.Features.LeaveJob.enabled then
    return { type = "error", message = "Denne funktion er ikke aktiveret." }
  end

  local xPlayer = ESX.GetPlayerFromId(source)
  if not xPlayer then return { type = "error", message = "Der skete en fejl, prøv igen senere." } end

  if xPlayer.job.name == "unemployed" then
    return { type = "error", message = "Du har ikke noget job." }
  end

  local playerJobsResponse = GetPlayerJobsUtil(xPlayer)
  if not playerJobsResponse.success then
    return { type = "error", message = playerJobsResponse.error }
  end

  xPlayer.setJob("unemployed", 0)

  return { type = "success", message = "Du er gået af job." }
end

function SelectJob(source, jobName)
  if not Config.Features.SelectJob.enabled then
    return { type = "error", message = "Denne funktion er ikke aktiveret." }
  end

  local xPlayer = ESX.GetPlayerFromId(source)
  if not xPlayer then return { type = "error", message = "Der skete en fejl, prøv igen senere." } end

  local playerJobsResponse = GetPlayerJobsUtil(xPlayer)
  if not playerJobsResponse.success then
    return { type = "error", message = playerJobsResponse.error }
  end

  local foundJob, grade = false, 0
  for _, job in ipairs(playerJobsResponse.data) do
    if job.name == jobName then
      foundJob, grade = true, job.grade
      break
    end
  end

  if not foundJob and jobName ~= "unemployed" then
    return { type = "error", message = "Du har ikke dette job gemt." }
  end

  local jobData = JobsCache[jobName]
  if not jobData then
    return { type = "error", message = "Der skete en fejl, prøv igen senere." }
  end

  xPlayer.setJob(jobName, grade)

  return { type = "success", message = "Du er nu gået på job." }
end

function RemoveJob(source, jobName)
  if not Config.Features.RemoveJob.enabled then
    return { type = "error", message = "Denne funktion er ikke aktiveret." }
  end

  local xPlayer = ESX.GetPlayerFromId(source)
  if not xPlayer then return { type = "error", message = "Der skete en fejl, prøv igen senere." } end

  if jobName == "unemployed" then
    return { type = "error", message = "Du kan ikke fjerne dette job." }
  end

  local playerJobsResponse = GetPlayerJobsUtil(xPlayer)
  if not playerJobsResponse.success then
    return { type = "error", message = playerJobsResponse.error }
  end

  local foundJob = false
  for i, job in ipairs(playerJobsResponse.data) do
    if job.name == jobName then
      table.remove(playerJobsResponse.data, i)
      foundJob = true
      break
    end
  end

  if not foundJob then
    return { type = "error", message = "Du har ikke dette job gemt." }
  end

  local saveJobDB = MySQL.insert.await("UPDATE `users` SET `jobs` = ? WHERE `identifier` = ?", {
    json.encode(playerJobsResponse.data), xPlayer.identifier
  })

  if not saveJobDB then
    return { type = "error", message = "Der skete en fejl, prøv igen senere." }
  end

  if xPlayer.job.name == jobName then
    xPlayer.setJob("unemployed", 0)
  end

  return { type = "success", message = "Du har fjernet dette job." }
end

exports("GetPlayerJobs", GetPlayerJobs)
exports("SaveJob", SaveJob)
exports("LeaveJob", LeaveJob)
exports("SelectJob", SelectJob)
exports("RemoveJob", RemoveJob)
