Config = {}

Config.InitialSqlCreation = true               -- Automatically create the sql columns when the script starts (true/false) (It detects if the columns already exists)
Config.AutoSaveJob = true                      -- Whenever /setjob from ESX is called, it will save the job to multijob (true/false)
Config.OpenMenuCommand = { "jobs", "jobmenu" } -- Command to open the job menu (table<string>)

Config.Features = {                            -- If you disable a feature, it will not be registered as a command or be visible in the job menu

  -- Features for the menu
  ListJobs = {                                   -- Opens a job menu
    enabled = true,                              -- Should the feature be enabled or disabled fully (true/false)
    title = "Se gemte jobs",                     -- Title of the option in the menu (string)
    description = "Se alle de jobs du har gemt", -- Description of the option in the menu (string)
    icon = "list",                               -- Icon of the option in the menu (string) https://fontawesome.com/icons?d=gallery&m=free
  },
  SaveJob = {                                    -- This adds your current job to multijob
    enabled = true,                              -- Should the feature be enabled or disabled fully (true/false)
    title = "Gem job",                           -- Title of the option in the menu (string)
    description = "Gem dit nuværende job",       -- Description of the option in the menu (string)
    icon = "save",                               -- Icon of the option in the menu (string) https://fontawesome.com/icons?d=gallery&m=free
  },
  LeaveJob = {                                   -- This does not remove the job from multijob, it just sets the esx player job to "unemployed"
    enabled = true,                              -- Should the feature be enabled or disabled fully (true/false)
    title = "Gå af job",                         -- Title of the option in the menu (string)
    description = "Går af dit nuværende job",    -- Description of the option in the menu (string)
    icon = "door-open",                          -- Icon of the option in the menu (string) https://fontawesome.com/icons?d=gallery&m=free
  },

  -- Features for a selected job
  SelectJob = {                     -- Choose / pick a job already saved in multijob
    enabled = true,                 -- Should the feature be enabled or disabled fully (true/false)
    title = "Gå på job",            -- Title of the option in the menu (string)
    description = "Går på jobbet",  -- Description of the option in the menu (string)
    icon = "user-plus",             -- Icon of the option in the menu (string) https://fontawesome.com/icons?d=gallery&m=free
  },
  RemoveJob = {                     -- Removes the job from multijob and sets the esx player job to "unemployed" if he has the given job
    enabled = true,                 -- Should the feature be enabled or disabled fully (true/false)
    title = "Fjern job",            -- Title of the option in the menu (string)
    description = "Fjerner jobbet", -- Description of the option in the menu (string)
    icon = "trash",                 -- Icon of the option in the menu (string) https://fontawesome.com/icons?d=gallery&m=free
  }

}

Config.AdminCommands = {

  GiveJob = { -- Saves the given job to multijob and gives the esx player the job (string)
    command = "admin:givejob",
    help = "Giv et job til en spiller.",
  },
  RemoveJob = { -- Removes the given job from multijob and sets the esx player job to "unemployed" if he has the given job (string)
    command = "admin:removejob",
    help = "Fjern et job fra en spiller.",
  },

}
