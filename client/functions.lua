-- Simple function that callbacks the server and show a notification and menu based on the response.
function CallbackOperation(callback, args, successMenu, errorMenu)
  local response = lib.callback.await(callback, false, table.unpack(args))
  if not response then
    lib.notify({
      type = "error",
      description = "Der skete en fejl, prøv igen senere."
    })
    return
  end

  if response.type == "error" then
    lib.notify({
      type = "error",
      description = response.message
    })

    if type(errorMenu) == "function" then
      errorMenu()
      return
    end

    return lib.showContext(errorMenu)
  end

  lib.notify({
    type = "success",
    description = response.message
  })

  if type(successMenu) == "function" then
    successMenu()
    return
  end

  lib.showContext(successMenu)
end
