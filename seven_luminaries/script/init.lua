function init()

    CS.Constants.CONSOLE_ENABLED = true
    CS.Constants.DEBUG_MODE = true
    CS.Aotenjo.Logger.Log("Mod load success")
    local ok = CS.Aotenjo.LuaTermBuilder.Register("seven_luminaries_active", "yellow")
    if not ok then
        CS.Aotenjo.Logger.Error("Failed to register seven_luminaries_active term")
    end
    require("materials").register()
    require("artifacts").register()
end