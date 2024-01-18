if Config.Features.ListJobs.enabled then
  for _, command in pairs(Config.OpenMenuCommand) do
    RegisterCommand(command, function()
      OpenJobsMenu()
    end)
  end
end

local currentJob = nil

function OpenJobsMenu()
  local config = Config.Features

  local jobOptions = {
    {
      icon = "user-tie",
      title = "Nuværende job:",
      description = ESX.PlayerData.job.label .. " - " .. ESX.PlayerData.job.grade_label,
      readOnly = true,
    },
  }

  if config.ListJobs.enabled then
    table.insert(jobOptions, {
      icon = config.ListJobs.icon,
      title = config.ListJobs.title,
      description = config.ListJobs.description,
      arrow = true,
      onSelect = function()
        ViewSavedJobs()
      end
    })
  end

  if config.SaveJob.enabled then
    table.insert(jobOptions, {
      icon = config.SaveJob.icon,
      title = config.SaveJob.title,
      description = config.SaveJob.description,
      onSelect = function()
        CallbackOperation("visualz_multijob:saveJob", {}, "visualz_multijob:jobMenu", "visualz_multijob:jobMenu")
      end
    })
  end

  if config.LeaveJob.enabled then
    table.insert(jobOptions, {
      icon = config.LeaveJob.icon,
      title = config.LeaveJob.title,
      description = config.LeaveJob.description,
      onSelect = function()
        CallbackOperation("visualz_multijob:leaveJob", {}, OpenJobsMenu, OpenJobsMenu)
      end
    })
  end

  lib.registerContext({
    id = "visualz_multijob:jobMenu",
    title = "Job menu",
    options = jobOptions
  })

  lib.showContext("visualz_multijob:jobMenu")
end

function ViewSavedJobs()
  local playerJobsResponse = lib.callback.await("visualz_multijob:getPlayerJobs")
  if not playerJobsResponse then
    lib.notify({
      type = "error",
      icon = "face-frown-open",
      description = "Der skete en fejl, prøv igen senere."
    })
    return
  end

  local jobOptions = {}

  if #playerJobsResponse > 0 then
    for _, job in ipairs(playerJobsResponse) do
      local hasJob = ESX.PlayerData.job.name == job.name
      table.insert(jobOptions, {
        icon = hasJob and "square-check" or "square",
        title = job.label .. " - " .. job.grade_label,
        description = "Klik for at håndtere jobbet",
        arrow = true,
        onSelect = function()
          currentJob = job
          ViewJob()
        end
      })
    end
  else
    table.insert(jobOptions, {
      title = "Du har ikke nogen jobs gemte",
    })
  end

  lib.registerContext({
    id = "visualz_multijob:jobMenuList",
    title = "Liste over gemte jobs",
    menu = "visualz_multijob:jobMenu",
    options = jobOptions,
  })

  lib.showContext("visualz_multijob:jobMenuList")
end

function ViewJob()
  if not currentJob then
    return
  end

  local job = currentJob

  local config = Config.Features

  local jobOptions = {
    {
      icon = "user-tie",
      title = "Job:",
      description = job.label .. " - " .. job.grade_label,
      readOnly = true,
    },
  }

  if config.SelectJob.enabled and job.name ~= ESX.PlayerData.job.name then
    table.insert(jobOptions, {
      icon = config.SelectJob.icon,
      title = config.SelectJob.title,
      description = config.SelectJob.description,
      onSelect = function()
        CallbackOperation("visualz_multijob:selectJob", { job.name }, OpenJobsMenu, ViewJob)
      end
    })
  end

  if config.RemoveJob.enabled then
    table.insert(jobOptions, {
      icon = config.RemoveJob.icon,
      title = config.RemoveJob.title,
      description = config.RemoveJob.description,
      onSelect = function()
        CallbackOperation("visualz_multijob:removeJob", { job.name }, OpenJobsMenu, ViewJob)
      end
    })
  end

  lib.registerContext({
    id = "visualz_multijob:jobMenuView",
    title = "Job menu",
    menu = "visualz_multijob:jobMenuList",
    options = jobOptions
  })

  lib.showContext("visualz_multijob:jobMenuView")
end
