local Aotenjo = CS.Aotenjo

-- 结算热路径日志开关:Logger.Log 每次都会同步写文件,开启会明显卡顿;排查问题时改为 true
local DEBUG_LOG = false
local _logger = Aotenjo.Logger
local function log(...) if DEBUG_LOG then _logger.Log(...) end end

local M = {}
local handlers = {}

-- function M.whethercoseven(player, atile)
--     log("cotest")
--     if(player:DetermineMaterialCompatibility(atile, M.metal) or player:DetermineMaterialCompatibility(atile, M.wood) or player:DetermineMaterialCompatibility(atile, M.water) or player:DetermineMaterialCompatibility(atile, M.fire) or player:DetermineMaterialCompatibility(atile, M.earth)) then
--         return true
--     else
--         return false
--     end
-- end
-- function M.whetherepseven(player, atile)
--     log("eptest")
--     if(player:DetermineMaterialCompatibility(atile, M.moon) or player:DetermineMaterialCompatibility(atile, M.sun)) then
--         return true
--     else
--         return false
--     end
-- end
-- setMat 7-13 seven_luminaries:moon
-- function M.mooncheck(tile, player, material, sorm)
--     local cnt = 0
--     local perm = player:GetAccumulatedPermutation()
--     local tiles = perm:ToTiles()
--     for i = 0, tiles.Count - 1 do
--         local atile = tiles[i]
--         if (M.whethercoseven(tile)) then
--             cnt = cnt + 1
--         elseif (M.whetherepseven(tile) and sorm)then 
--             cnt = cnt + 1
--         end
--     end
--     return cnt
-- end
function M.activetile(tile, player, material, effects)
    log("active")
    material:SetData("active", tostring(1))
end
function M.earthtrans(tile, player, material)
    log("ccheck")
    local rnd = player:GenerateRandomInt(100)
    local result = nil
    if rnd < 19 then
        result = M.metal
    elseif rnd < 38 then
        result = M.wood
    elseif rnd < 59 then
        result = M.water
    elseif rnd < 80 then
        result = M.fire
    elseif rnd < 92 then
        result = M.earth
    elseif rnd < 96 then
        result = M.sun
    else
        result = M.moon
    end
    if result ~= nil then
        tile:SetMaterial(result:Copy(), player)
    end
end
function M.sevenluminariescheck(atile, player)
    -- log("test1")
    if (player:DetermineMaterialCompatibility(atile, M.metal) or player:DetermineMaterialCompatibility(atile, M.wood) or player:DetermineMaterialCompatibility(atile, M.water) or player:DetermineMaterialCompatibility(atile, M.fire) or player:DetermineMaterialCompatibility(atile, M.earth) or player:DetermineMaterialCompatibility(atile, M.sun) or player:DetermineMaterialCompatibility(atile, M.moon)) then
        -- log("test2")
        return true
    else
        -- log("test3")
        return false
    end
end
function M.colorful_earthcheck(player)
    -- log("colorful earth start")
    local artifacts = player:GetArtifacts()
    for i = 0, artifacts.Count - 1 do
        local aartifact = artifacts[i]
        -- log(aartifact:GetRegName())
        if aartifact:GetRegName() == "seven_luminaries:colorful_earth" then
            local played = player:GetSelectedTilesCopy()
            for i = 0, played.Count - 1 do
                local atile = played[i]
                if player:DetermineMaterialCompatibility(atile, M.earth) then
                    -- log("colorful earth over")
                    return true
                end
            end
            -- log("colorful earth over")
            return false
        end
    end
    log("colorful earth over")
    return false
end
function M.GetChanceMultiplier(player)
    local artifacts = player:GetArtifacts()
    -- for i = 0, artifacts.Count - 1 do
    --     local aartifact = artifacts[i]
    --     log(aartifact:GetRegName())
    --     if aartifact:GetRegName() == "scarlet_core" then
    --         if aartifact:GetChanceMultiplier(player) == "1" then
    --             log("*1")
    --             return false
    --         else
    --             log("*2")
    --             return true
    --         end
    --     end
    -- end
    if artifacts.Count ~= 0 then
        local aartifact = artifacts[0]
        if aartifact:GetChanceMultiplier(player) == "1" then
            log("*1")
            return false
        else
            log("*2")
            return true
        end
    else
        return false
    end
end
function M.register()
    log("Creating Custom Material Set")
    M.metal = Aotenjo.LuaTileMaterialBuilder.Create("seven_luminaries:metal")
        :WithRarity(Aotenjo.Rarity.COMMON)
        :OnSubscribe(function(player, material)
            log("metal init")
            local actived = tonumber(material:GetDataOrDefault("active", 2))
            if actived == 2 then
                material:SetData("active", tostring(0))
            end
            log("metal init over")
        end)
        :WithDescription(function(loc, player, material)
            local actived = tonumber(material:GetDataOrDefault("active", 2))
            local ifdouble = M.GetChanceMultiplier(player)
            if ifdouble == true then
                if actived == 0 then
                    return string.format(loc("tile_seven_luminaries:metalinactive_material_description"),"<style=\"green\">2</style>")
                elseif actived == 1 then
                    return string.format(loc("tile_seven_luminaries:metalactived_material_description"),"<style=\"green\">3</style>")
                else
                    return string.format(loc("tile_seven_luminaries:metalshow_material_description"),"<style=\"green\">2</style>","<style=\"green\">3</style>")
                end
            else
                if actived == 0 then
                    return string.format(loc("tile_seven_luminaries:metalinactive_material_description"),"1")
                elseif actived == 1 then
                    return string.format(loc("tile_seven_luminaries:metalactived_material_description"),"2")
                else
                    return string.format(loc("tile_seven_luminaries:metalshow_material_description"),"1","2")
                end
            end
        end)
        :WithSpriteNamespaceID(function(player, self)
            local actived = tonumber(self:GetDataOrDefault("active", 2))
            if actived == 0 then
                return "tile_material:seven_luminaries:metal"
            elseif actived == 1 then
                return "tile_material:seven_luminaries:metalactived"
            else
                return "tile_material:seven_luminaries:metalshow"
            end
        end)
        :OnScoringEffect(function(player, perm, tile, effects, material)
            local actived = tonumber(material:GetDataOrDefault("active", 0))
            if (player:Selecting(tile) and actived == 0) then
                log("metal check")
                local played = player:GetSelectedTilesCopy()
                for i = 0, played.Count - 1 do
                    local atile = played[i]
                    if (player:DetermineMaterialCompatibility(atile, M.fire) or M.colorful_earthcheck(player)) then
                        effects:Add(Aotenjo.SimpleEffect("effects_active", nil, function() end))
                        M.activetile(tile, player, material, effects)
                        actived = 1
                        break
                    end
                end
            end
            local rndrange = 0
            if actived == 1 then
                rndrange = 3
            else
                rndrange = 2
            end
            if M.GetChanceMultiplier(player) then
                log("metal get")
                material:SetData("metalget", tostring(1))
                effects:Add(Aotenjo.EarnMoneyEffect(rndrange, nil))
            else
                local rnd = player:GenerateRandomInt(rndrange)
                if rnd < rndrange - 1 then
                    log("metal get")
                    material:SetData("metalget", tostring(1))
                    effects:Add(Aotenjo.EarnMoneyEffect(rndrange, nil))
                else
                    log("metal miss")
                    material:SetData("metalget", tostring(0))
                    effects:Add(Aotenjo.SimpleEffect("effects_metalmiss", nil, function() end))
                end
            end
        end)
        -- :OnUnsubscribe(function(player, material)
        --     material:SetData("active", tostring(0))
        -- end)
    :BuildAndRegister()

    M.wood = Aotenjo.LuaTileMaterialBuilder.Create("seven_luminaries:wood")
        :WithRarity(Aotenjo.Rarity.COMMON)
        :OnSubscribe(function(player, material)
            log("wood init")
            local actived = tonumber(material:GetDataOrDefault("active", 2))
            if actived == 2 then
                material:SetData("active", tostring(0))
            end
            -- material:SetData("woodcnt", tostring(0))
            local wcnt = tonumber(material:GetDataOrDefault("woodcnt", -1))
            if actived == -1 then
                material:SetData("woodcnt", tostring(0))
            end
            log("wood init over")
        end)
        :WithDescription(function(loc, player, material)
            local actived = tonumber(material:GetDataOrDefault("active", 2))
            local wcnt = tonumber(material:GetDataOrDefault("woodcnt",0))
            if actived == 0 then
                return string.format(loc("tile_seven_luminaries:woodinactive_material_description"), wcnt, wcnt * 5)
            elseif actived == 1 then
                return string.format(loc("tile_seven_luminaries:woodactived_material_description"), wcnt, wcnt * 5)
            else
                return string.format(loc("tile_seven_luminaries:woodshow_material_description"), wcnt, wcnt * 5, wcnt, wcnt * 5)
            end
        end)
        :WithSpriteNamespaceID(function(player, self)
            local actived = tonumber(self:GetDataOrDefault("active", 2))
            if actived == 0 then
                return "tile_material:seven_luminaries:wood"
            elseif actived == 1 then
                return "tile_material:seven_luminaries:woodactived"
            else
                return "tile_material:seven_luminaries:woodshow"
            end
        end)
        :OnScoringEffect(function(player, perm, tile, effects, material)
            local actived = tonumber(material:GetDataOrDefault("active", 0))
            local wcnt = tonumber(material:GetDataOrDefault("woodcnt",0))
            if (player:Selecting(tile) and actived == 0) then
                log("wood check")
                local played = player:GetSelectedTilesCopy()
                for i = 0, played.Count - 1 do
                    local atile = played[i]
                    if player:DetermineMaterialCompatibility(atile, M.earth) then
                        effects:Add(Aotenjo.SimpleEffect("effects_active", nil, function() end))
                        M.activetile(tile, player, material, effects)
                        actived = 1
                        break
                    end
                end
            end
            if (player:Selecting(tile) and actived == 0) then
                effects:Add(Aotenjo.SimpleEffect("effects_woodgrow", nil, function() end))
                wcnt = wcnt + 2
            end
            if actived == 1 then
                effects:Add(Aotenjo.SimpleEffect("effects_woodgrow", nil, function() end))
                wcnt = wcnt + 1
            end
            material:SetData("woodcnt",tostring(wcnt))
            effects:Add(Aotenjo.ScoreEffect.AddFan(wcnt, nil))
            effects:Add(Aotenjo.ScoreEffect.AddFu(wcnt * 5, nil))
        end)
        -- :OnUnsubscribe(function(player, material)
        --     material:SetData("active", tostring(0))
        --     material:SetData("woodcnt", tostring(0))
        -- end)
    :BuildAndRegister()

    M.water = Aotenjo.LuaTileMaterialBuilder.Create("seven_luminaries:water")
        :WithRarity(Aotenjo.Rarity.COMMON)
        :OnSubscribe(function(player, material)
            log("water init")
            local actived = tonumber(material:GetDataOrDefault("active", 2))
            if actived == 2 then
                material:SetData("active", tostring(0))
            end
            log("water init over")
        end)
        :WithDescription(function(loc, player, material)
            local actived = tonumber(material:GetDataOrDefault("active", 2))
            if actived == 0 then
                return string.format(loc("tile_seven_luminaries:waterinactive_material_description"))
            elseif actived == 1 then
                return string.format(loc("tile_seven_luminaries:wateractived_material_description"))
            else
                return string.format(loc("tile_seven_luminaries:watershow_material_description"))
            end
        end)
        :WithSpriteNamespaceID(function(player, self)
            local actived = tonumber(self:GetDataOrDefault("active", 2))
            if actived == 0 then
                return "tile_material:seven_luminaries:water"
            elseif actived == 1 then
                return "tile_material:seven_luminaries:wateractived"
            else
                return "tile_material:seven_luminaries:watershow"
            end
        end)
        :OnScoringEffect(function(player, perm, tile, effects, material)
            local actived = tonumber(material:GetDataOrDefault("active", 0))
            if (player:Selecting(tile) and actived == 0) then
                log("water check")
                local played = player:GetSelectedTilesCopy()
                for i = 0, played.Count - 1 do
                    local atile = played[i]
                    if (player:DetermineMaterialCompatibility(atile, M.metal) or M.colorful_earthcheck(player)) then
                        effects:Add(Aotenjo.SimpleEffect("effects_active", nil, function() end))
                        M.activetile(tile, player, material, effects)
                        actived = 1
                        break
                    end
                end
            end
            local fireaddfu = 0
            if actived == 1 then
                fireaddfu = 60
            else
                fireaddfu = 20
            end
            effects:Add(Aotenjo.ScoreEffect.AddFu(fireaddfu, nil))
        end)
        -- :OnUnsubscribe(function(player, material)
        --     material:SetData("active", tostring(0))
        -- end)
    :BuildAndRegister()

    M.fire = Aotenjo.LuaTileMaterialBuilder.Create("seven_luminaries:fire")
        :WithRarity(Aotenjo.Rarity.COMMON)
        :OnSubscribe(function(player, material)
            log("fire init")
            local actived = tonumber(material:GetDataOrDefault("active", 2))
            if actived == 2 then
                material:SetData("active", tostring(0))
            end
            log("fire init over")
        end)
        :WithDescription(function(loc, player, material)
            local actived = tonumber(material:GetDataOrDefault("active", 2))
            if actived == 0 then
                return string.format(loc("tile_seven_luminaries:fireinactive_material_description"))
            elseif actived == 1 then
                return string.format(loc("tile_seven_luminaries:fireactived_material_description"))
            else
                return string.format(loc("tile_seven_luminaries:fireshow_material_description"))
            end
        end)
        :WithSpriteNamespaceID(function(player, self)
            local actived = tonumber(self:GetDataOrDefault("active", 2))
            if actived == 0 then
                return "tile_material:seven_luminaries:fire"
            elseif actived == 1 then
                return "tile_material:seven_luminaries:fireactived"
            else
                return "tile_material:seven_luminaries:fireshow"
            end
        end)
        :OnScoringEffect(function(player, perm, tile, effects, material)
            local actived = tonumber(material:GetDataOrDefault("active", 0))
            if (player:Selecting(tile) and actived == 0) then
                log("fire check")
                local played = player:GetSelectedTilesCopy()
                for i = 0, played.Count - 1 do
                    local atile = played[i]
                    if (player:DetermineMaterialCompatibility(atile, M.wood) or M.colorful_earthcheck(player)) then
                        effects:Add(Aotenjo.SimpleEffect("effects_active", nil, function() end))
                        M.activetile(tile, player, material, effects)
                        actived = 1
                        break
                    end
                end
            end
            local fireaddfan = 0
            if actived == 1 then
                fireaddfan = 10
            else
                fireaddfan = 4
            end
            effects:Add(Aotenjo.ScoreEffect.AddFan(fireaddfan, nil))
        end)
        -- :OnUnsubscribe(function(player, material)
        --     material:SetData("active", tostring(0))
        -- end)
    :BuildAndRegister()

    M.earth = Aotenjo.LuaTileMaterialBuilder.Create("seven_luminaries:earth")
        :WithRarity(Aotenjo.Rarity.COMMON)
        :OnSubscribe(function(player, material)
            log("earth init")
            local actived = tonumber(material:GetDataOrDefault("active", 2))
            if actived == 2 then
                material:SetData("active", tostring(0))
            end
            log("earth init over")
        end)
        :WithDescription(function(loc, player, material)
            local actived = tonumber(material:GetDataOrDefault("active", 2))
            if actived == 0 then
                return string.format(loc("tile_seven_luminaries:earthinactive_material_description"))
            elseif actived == 1 then
                return string.format(loc("tile_seven_luminaries:earthactived_material_description"))
            else
                return string.format(loc("tile_seven_luminaries:earthshow_material_description"))
            end
        end)
        :WithSpriteNamespaceID(function(player, self)
            local actived = tonumber(self:GetDataOrDefault("active", 2))
            if actived == 0 then
                return "tile_material:seven_luminaries:earth"
            elseif actived == 1 then
                return "tile_material:seven_luminaries:earthactived"
            else
                return "tile_material:seven_luminaries:earthshow"
            end
        end)
        :OnScoringEffect(function(player, perm, tile, effects, material)
            local actived = tonumber(material:GetDataOrDefault("active", 0))
            if (player:Selecting(tile) and actived == 0) then
                log("earth check")
                local played = player:GetSelectedTilesCopy()
                for i = 0, played.Count - 1 do
                    local atile = played[i]
                    if player:DetermineMaterialCompatibility(atile, M.water) then
                        effects:Add(Aotenjo.SimpleEffect("effects_active", nil, function() end))
                        M.activetile(tile, player, material, effects)
                        actived = 1
                        break
                    end
                end
            end
            if actived == 1 then
                if player:Selecting(tile) then
                    local played = player:GetSelectedTilesCopy()
                    local cnt = 0
                    for i = 0, played.Count - 1 do
                        local atile = played[i]
                        log("test1")
                        if (player:DetermineMaterialCompatibility(atile,Aotenjo.TileMaterial.PLAIN)) then
                            cnt = cnt + 1
                        end
                    end
                    -- log("test1")
                    if cnt ~= 0 then
                        local place = player:GenerateRandomInt(cnt) + 1
                        for i = 0, played.Count - 1 do
                            local atile = played[i]
                            if (player:DetermineMaterialCompatibility(atile,Aotenjo.TileMaterial.PLAIN)) then
                                place = place - 1
                                if place == 0 then
                                    M.earthtrans(atile, player, material)
                                    break
                                end
                            end
                        end
                    end
                end
                effects:Add(Aotenjo.ScoreEffect.MulFan(1.5,nil))
            end
        end)
        -- :OnUnsubscribe(function(player, material)
        --     material:SetData("active", tostring(0))
        -- end)
    :BuildAndRegister()

    M.sun = Aotenjo.LuaTileMaterialBuilder.Create("seven_luminaries:sun")
        :WithRarity(Aotenjo.Rarity.EPIC)
        :OnSubscribe(function(player, material)
            log("sun init")
            local actived = tonumber(material:GetDataOrDefault("active", 2))
            if actived == 2 then
                material:SetData("active", tostring(0))
            end
            log("sun init over")
        end)
        :WithDescription(function(loc, player, material)
            local actived = tonumber(material:GetDataOrDefault("active", 2))
            if actived == 0 then
                return string.format(loc("tile_seven_luminaries:suninactive_material_description"))
            elseif actived == 1 then
                return string.format(loc("tile_seven_luminaries:sunactived_material_description"))
            else
                return string.format(loc("tile_seven_luminaries:sunshow_material_description"))
            end
        end)
        :WithSpriteNamespaceID(function(player, self)
            local actived = tonumber(self:GetDataOrDefault("active", 2))
            if actived == 0 then
                return "tile_material:seven_luminaries:sun"
            elseif actived == 1 then
                return "tile_material:seven_luminaries:sunactived"
            else
                return "tile_material:seven_luminaries:sunshow"
            end
        end)
        :OnScoringEffect(function(player, perm, tile, effects, material)
            local actived = tonumber(material:GetDataOrDefault("active", 0))
            if (player:Selecting(tile) and actived == 0) then
                log("sun check")
                local played = player:GetSelectedTilesCopy()
                for i = 0, played.Count - 1 do
                    local atile = played[i]
                    if (player:DetermineMaterialCompatibility(atile, M.moon) or M.colorful_earthcheck(player)) then
                        effects:Add(Aotenjo.SimpleEffect("effects_active", nil, function() end))
                        M.activetile(tile, player, material, effects)
                        actived = 1
                        break
                    end
                end
            end
            local sunmulfan = 1
            if actived == 1 then
                sunmulfan = 4
            else
                sunmulfan = 2
            end
            effects:Add(Aotenjo.ScoreEffect.MulFan(sunmulfan, nil))
        end)
        -- :OnUnsubscribe(function(player, material)
        --     material:SetData("active", tostring(0))
        -- end)
    :BuildAndRegister()

    M.moon = Aotenjo.LuaTileMaterialBuilder.Create("seven_luminaries:moon")
        :WithRarity(Aotenjo.Rarity.EPIC)
        :OnSubscribe(function(player, material)
            log("moon init")
            local actived = tonumber(material:GetDataOrDefault("active", 2))
            if actived == 2 then
                material:SetData("active", tostring(0))
            end
            log("moon init over")
        end)
        :WithDescription(function(loc, player, material)
            local actived = tonumber(material:GetDataOrDefault("active", 2))
            if actived == 0 then
                return string.format(loc("tile_seven_luminaries:mooninactive_material_description"))
            elseif actived == 1 then
                return string.format(loc("tile_seven_luminaries:moonactived_material_description"))
            else
                return string.format(loc("tile_seven_luminaries:moonshow_material_description"))
            end
        end)
        :WithSpriteNamespaceID(function(player, self)
            local actived = tonumber(self:GetDataOrDefault("active", 2))
            if actived == 0 then
                return "tile_material:seven_luminaries:moon"
            elseif actived == 1 then
                return "tile_material:seven_luminaries:moonactived"
            else
                return "tile_material:seven_luminaries:moonshow"
            end
        end)
        :OnScoringEffect(function(player, perm, tile, effects, material)
            local actived = tonumber(material:GetDataOrDefault("active", 0))
            if (player:Selecting(tile) and actived == 0) then
                log("moon check")
                local played = player:GetSelectedTilesCopy()
                for i = 0, played.Count - 1 do
                    local atile = played[i]
                    if (player:DetermineMaterialCompatibility(atile, M.sun) or M.colorful_earthcheck(player)) then
                        effects:Add(Aotenjo.SimpleEffect("effects_active", nil, function() end))
                        M.activetile(tile, player, material, effects)
                        actived = 1
                        break
                    end
                end
            end
            local moonmulfan = 1.0
            local cnt = 0
            local aperm = player:GetAccumulatedPermutation()
            if (aperm ~= nil) then
                local tiles = aperm:ToTiles()
                for i = 0, tiles.Count - 1 do
                    local atile = tiles[i]
                    if (player:DetermineMaterialCompatibility(atile, M.metal) or player:DetermineMaterialCompatibility(atile, M.wood) or player:DetermineMaterialCompatibility(atile, M.water) or player:DetermineMaterialCompatibility(atile, M.fire) or player:DetermineMaterialCompatibility(atile, M.earth)) then
                        cnt = cnt + 1
                    elseif (actived == 1 and (player:DetermineMaterialCompatibility(atile, M.moon) or player:DetermineMaterialCompatibility(atile, M.sun)))then 
                        cnt = cnt + 1
                    end
                end
            end
            local played = player:GetSelectedTilesCopy()
            for i = 0, played.Count - 1 do
                local atile = played[i]
                if (player:DetermineMaterialCompatibility(atile, M.metal) or player:DetermineMaterialCompatibility(atile, M.wood) or player:DetermineMaterialCompatibility(atile, M.water) or player:DetermineMaterialCompatibility(atile, M.fire) or player:DetermineMaterialCompatibility(atile, M.earth)) then
                    cnt = cnt + 1
                elseif (actived == 1 and (player:DetermineMaterialCompatibility(atile, M.moon) or player:DetermineMaterialCompatibility(atile, M.sun)))then 
                    cnt = cnt + 1
                end
            end
            if actived == 0 then
                moonmulfan = 1.5 + cnt * 0.1
            else
                moonmulfan = 2.0 + cnt * 0.15
            end
            effects:Add(Aotenjo.ScoreEffect.MulFan(moonmulfan, nil))
        end)
        -- :OnUnsubscribe(function(player, material)
        --     material:SetData("active", tostring(0))
        -- end)
    :BuildAndRegister()

    Aotenjo.LuaMaterialSetBuilder.Create("seven_luminaries:seven_luminaries")
        :AddMaterial("seven_luminaries:metal")
        :AddMaterial("seven_luminaries:wood")
        :AddMaterial("seven_luminaries:water")
        :AddMaterial("seven_luminaries:fire")
        :AddMaterial("seven_luminaries:earth")
        :AddMaterial("seven_luminaries:sun")
        :AddMaterial("seven_luminaries:moon")
    :BuildAndRegister()
end
return M

-- player.stats.GetCustomStats
-- local id = material:GetRegName() .. "-" .. material:GetHashCode()
-- tile:SetMaterial(TileMaterial.GOLDEN, player)
-- tile:SetMaterial(result, player)
-- local tiles = perm:ToTiles()
-- setHand 111111m
-- setMat 0-5 seven_luminaries:metal
-- setMat 3 seven_luminaries:fire