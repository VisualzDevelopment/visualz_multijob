JobsCache = {
  ["unemployed"] = { label = "Unemployed", grades = { ["0"] = { grade = 0, label = "Unemployed" } } }
}

MySQL.ready(function()
  RefreshJobs()

  local doesUsersExist = MySQL.query.await("SHOW TABLES LIKE 'users';")
  if not doesUsersExist then
    print("[visualz_multijob] Could not check if table 'users' exists in database")
    return
  end

  local doesJobsExist = MySQL.query.await("SHOW COLUMNS FROM `users` LIKE 'jobs';")
  if #doesJobsExist > 0 then
    return
  end

  local createTableResponse = MySQL.rawExecute.await("ALTER TABLE `users` ADD COLUMN `jobs` JSON NOT NULL DEFAULT '[]' AFTER `job_grade`;")
  if not createTableResponse then
    print("[visualz_multijob] Could not create column 'jobs' in table 'users'")
    return
  end

  print("[visualz_multijob] Created column 'jobs' in table 'users' successfully")
end)

if Config.AutoSaveJob then
  AddEventHandler("esx:setJob", function(source, job)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or job.name == "unemployed" then return end

    local playerJobsResponse = GetPlayerJobsUtil(xPlayer)
    if not playerJobsResponse.success then
      return
    end

    local foundJob, index = false, nil
    for _, job in ipairs(playerJobsResponse.data) do
      if job.name == xPlayer.job.name then
        if job.grade == xPlayer.job.grade then
          return
        end

        foundJob, index = true, index
        job.grade = xPlayer.job.grade
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
      return
    end
  end)
end

lib.addCommand(Config.AdminCommands.GiveJob.command, {
  help = Config.AdminCommands.GiveJob.help,
  params = {
    { name = "id",   help = "Spiller ID", type = "playerId" },
    { name = "job",  help = "Job",        type = "string" },
    { name = "grad", help = "Job grad",   type = "number" },
  }
}, function(source, args)
  local xPlayer = ESX.GetPlayerFromId(source)
  if not xPlayer or not xPlayer.getGroup() == "admin" then
    return TriggerClientEvent("ox_lib:notify", source, { type = "error", description = "Du har ikke adgang til denne kommando." })
  end

  local target = ESX.GetPlayerFromId(args.id)
  if not target then return end

  local jobName, jobGrade = args.job, args.grad

  if not JobsCache[jobName] or not JobsCache[jobName].grades[tostring(jobGrade)] then
    return TriggerClientEvent("ox_lib:notify", source, { type = "error", description = "Jobbet eller job graden findes ikke." })
  end

  if Config.AutoSaveJob then
    target.setJob(jobName, jobGrade)
    return TriggerClientEvent("ox_lib:notify", source, { type = "success", description = "Du har givet spilleren jobbet." })
  end

  local playerJobsResponse = GetPlayerJobs(target)
  if not playerJobsResponse.success then
    return TriggerClientEvent("ox_lib:notify", source, { type = "error", description = playerJobsResponse.error })
  end

  local foundJob, index = false, nil
  for _, job in ipairs(playerJobsResponse.data) do
    if job.name == jobName then
      foundJob = true
      index = index

      if job.grade == jobGrade then
        return TriggerClientEvent("ox_lib:notify", source, {
          type = "error",
          description = "Spilleren har allerede dette job."
        })
      end

      job.grade = jobGrade
      break
    end
  end

  if not foundJob then
    playerJobsResponse.data[#playerJobsResponse.data + 1] = { name = jobName, grade = jobGrade }
  else
    table.remove(playerJobsResponse.data, index)
    playerJobsResponse.data[#playerJobsResponse.data + 1] = { name = jobName, grade = jobGrade }
  end

  local saveJobDB = MySQL.insert.await("UPDATE `users` SET `jobs` = ? WHERE `identifier` = ?", {
    json.encode(playerJobsResponse.data), target.identifier
  })

  if not saveJobDB then
    return TriggerClientEvent("ox_lib:notify", source, { type = "error", description = "Der skete en fejl, prøv igen senere." })
  end

  target.setJob(jobName, jobGrade)

  TriggerClientEvent("ox_lib:notify", source, { type = "success", description = "Du har givet spilleren jobbet." })
end)

lib.addCommand(Config.AdminCommands.RemoveJob.command, {
  help = Config.AdminCommands.RemoveJob.help,
  params = {
    { name = "id",  help = "Spiller ID", type = "playerId" },
    { name = "job", help = "Job",        type = "string" },
  }
}, function(source, args)
  local xPlayer = ESX.GetPlayerFromId(source)
  if not xPlayer or not xPlayer.getGroup() == "admin" then
    return TriggerClientEvent("ox_lib:notify", source, { type = "error", description = "Du har ikke adgang til denne kommando." })
  end

  local target = ESX.GetPlayerFromId(args.id)
  if not target then return end

  local jobName = args.job

  if not JobsCache[jobName] then
    return TriggerClientEvent("ox_lib:notify", source, { type = "error", description = "Job findes ikke." })
  end

  local playerJobsResponse = GetPlayerJobs(target)
  if not playerJobsResponse.success then
    return TriggerClientEvent("ox_lib:notify", source, { type = "error", description = playerJobsResponse.error })
  end

  local foundJob, index = false, nil
  for _, job in ipairs(playerJobsResponse.data) do
    if job.name == jobName then
      foundJob, index = true, index
      break
    end
  end

  if not foundJob or not index then
    return TriggerClientEvent("ox_lib:notify", source, { type = "error", description = "Spilleren har ikke dette job." })
  end

  table.remove(playerJobsResponse.data, index)

  local saveJobDB = MySQL.insert.await("UPDATE `users` SET `jobs` = ? WHERE `identifier` = ?", {
    json.encode(playerJobsResponse.data), target.identifier
  })

  if not saveJobDB then
    return TriggerClientEvent("ox_lib:notify", source, { type = "error", description = "Der skete en fejl, prøv igen senere." })
  end

  target.setJob("unemployed", 0)

  TriggerClientEvent("ox_lib:notify", source, { type = "success", description = "Du har fjernet spillerens job." })
end)
