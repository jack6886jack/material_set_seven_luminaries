local Aotenjo = CS.Aotenjo

-- 结算热路径日志开关:Logger.Log 每次都会同步写文件,开启会明显卡顿;排查问题时改为 true
local DEBUG_LOG = false
local _logger = Aotenjo.Logger
local function log(...) if DEBUG_LOG then _logger.Log(...) end end

local M = {}
local tree_fertilizer_usedtile = {}

local materials = require("materials")

-- 图鉴里没有正在游玩的玩家(player 为 nil)时展示的样例牌
-- 与原版魂符同理:不依赖 player,只用牌码 + loc 取名字
local SAMPLE_CODES = { "1m", "2m", "3m", "4m", "5m", "6m", "7m", "8m", "9m",
                       "1p", "2p", "3p", "4p", "5p", "6p", "7p", "8p", "9p",
                       "1s", "2s", "3s", "4s", "5s", "6s", "7s", "8s", "9s",
                       "1z", "2z", "3z", "4z", "5z", "6z", "7z" }
local sample_cursor = 0
local function sample_tile_name(loc)
    sample_cursor = sample_cursor % #SAMPLE_CODES + 1
    return loc("tile_" .. SAMPLE_CODES[sample_cursor] .. "_name")
end

-- 被封(suppressed)的牌:引擎会删除这张牌的计分效果(effects:Add 出来的),但 OnTileEffect 回调照常触发。
-- 回调里的 SetData 这类持久写入删不掉 => 会白白累积,或读到被跳过的材质钩子留下的过期标志,故显式跳过。
-- 掩码注册名带 "_mask" 后缀:普通牌 "none_mask",被封的牌 "suppressed_mask"
local function tile_suppressed(tile)
    return tile.properties.mask:GetRegName() == "suppressed_mask"
end

function M.is_seven_luminaries(player, tile)
    if (player:DetermineMaterialCompatibility(tile, materials.metal) or player:DetermineMaterialCompatibility(tile, materials.wood) or player:DetermineMaterialCompatibility(tile, materials.water) or player:DetermineMaterialCompatibility(tile, materials.fire) or player:DetermineMaterialCompatibility(tile, materials.earth) or player:DetermineMaterialCompatibility(tile, materials.sun) or player:DetermineMaterialCompatibility(tile, materials.moon)) then
        return true
    else
        return false
    end
end
function M.tai_chi_check(player)
    log("ttest1")
    local aperm = player:GetAccumulatedPermutation()
    log("ttest2")
    local suns = 0
    local moons = 0
    log("ttest3")
    if aperm ~= nil then
        log("ttest4")
        local tiles = aperm:ToTiles()
        for i = 0, tiles.Count - 3 do
            local atile = tiles[i]
            if (player:DetermineMaterialCompatibility(atile, materials.sun)) then
                suns = suns + 1
            elseif (player:DetermineMaterialCompatibility(atile, materials.moon))then 
                moons = moons + 1
            end
        end
    end
    aperm = player:GetSelectedTilesCopy()
    if aperm ~= nil then
        log("ttest5")
        for i = 0, aperm.Count - 1 do
            local atile = aperm[i]
            log("ttestB")
            if (player:DetermineMaterialCompatibility(atile, materials.sun)) then
                suns = suns + 1
            elseif (player:DetermineMaterialCompatibility(atile, materials.moon))then 
                moons = moons + 1
            end
        end
    end
    log("ttest6")
    -- if suns > moons then
    --     log("ttest7")
    --     return moons
    -- else
    --     log("ttest8")
    --     return suns
    -- end
    return math.min(suns, moons)
end
-- 附赠牌体:返回一个可直接用于 :OnObtain 的回调
-- 获得该遗物时,从牌池随机抽取 count 张牌,给它们贴上 material 牌体
-- material: TileMaterial 实例,或材质注册名字符串(如 "seven_luminaries:fire")
-- count: 附赠的牌数,必须为正整数
function M.material_gift(material, count)
    return function(player, artifact)
        if player == nil or count == nil or count <= 0 then return end
        local mat = material
        if type(mat) == "string" then
            mat = Aotenjo.TileMaterial.GetMaterial(mat)
        end
        if mat == nil then return end
        local tiles = player:DrawPlainTilesFromPool(count)
        if tiles == nil then return end
        for i = 0, tiles.Count - 1 do
            local tile = tiles[i]
            if tile ~= nil then
                -- 每张牌用独立副本,避免多张牌共用同一材质实例导致 active/计数等状态串台
                tile:SetMaterial(mat:Copy(), player)
            end
        end
    end
end
function M.register()
    M.lucky_coin = Aotenjo.LuaArtifactBuilder.Create("seven_luminaries:lucky_coin", Aotenjo.Rarity.COMMON)
        :WithMaterialRequired({ "seven_luminaries:metal" })
        :OnObtain(M.material_gift(materials.metal, 5))
        :OnTileEffect(function(player, perm, tile, effects, artifact)
            if tile_suppressed(tile) then return end
            if player:DetermineMaterialCompatibility(tile, materials.metal) then
                local metalhit = tonumber(tile.properties.material:GetDataOrDefault("metalget", 0))
                if metalhit == 1 then
                    effects:Add(Aotenjo.ScoreEffect.AddFan(3, artifact))
                    effects:Add(Aotenjo.ScoreEffect.AddFu(20, artifact))
                end
            end
        end)
        :BuildAndRegister()
    M.torch = Aotenjo.LuaArtifactBuilder.Create("seven_luminaries:torch", Aotenjo.Rarity.COMMON)
        :WithMaterialRequired({ "seven_luminaries:fire" })
        :OnObtain(M.material_gift(materials.fire, 5))
        :OnTileEffect(function(player, perm, tile, effects, artifact)
            if tile_suppressed(tile) then return end
            if player:DetermineMaterialCompatibility(tile, materials.fire) then
                local actived = tonumber(tile.properties.material:GetDataOrDefault("active", 0))
                if (player:Selecting(tile) and actived == 0) then
                    -- effects:Add(Aotenjo.SimpleEffect("effects_burn", nil, function() end))
                    -- tile.properties.material:SetData("active", tostring(1))
                    
                    effects:Add(Aotenjo.SimpleEffect("effects_torch", artifact, function() end))
                    materials.activetile(tile, player, tile.properties.material, effects)
                end
            end
        end)
        :BuildAndRegister()
    
    -- M.sapling = Aotenjo.LuaArtifactBuilder.Create("seven_luminaries:sapling", Aotenjo.Rarity.COMMON)
    --     :WithMaterialRequired({ "seven_luminaries:wood" })
    --     :PreGameInitialized(function(player, artifact)
    --         local card = player:GenerateRandomInt(34) + 1
    --         artifact:SetData("card", tostring(card))
    --     end)
    --     :WithDescription(function(player, loc, artifact)
    --         local ranges = { "一万", "二万", "三万", "四万", "五万", "六万", "七万", "八万", "九万", 
    --                          "一饼", "二饼", "三饼", "四饼", "五饼", "六饼", "七饼", "八饼", "九饼", 
    --                          "一索", "二索", "三索", "四索", "五索", "六索", "七索", "八索", "九索", 
    --                          "东风", "南风", "西风", "北风", "红中", "发财", "白板"}
    --         local card = tonumber(artifact:GetDataOrDefault("card", 0))
    --         if card ~= 0 then
    --             return string.format(loc("artifact_seven_luminaries:sapling_description"), ranges[card])
    --         end
    --         card = player:GenerateRandomInt(34) + 1
    --         return string.format(loc("artifact_seven_luminaries:sapling_description"), ranges[card])
    --     end)
    --     :OnTileEffect(function(player, perm, tile, effects, artifact)
    --         local card = tonumber(artifact:GetDataOrDefault("card", 0))
    --         local ranges = { "1m", "2m", "3m", "4m", "5m", "6m", "7m", "8m", "9m", 
    --                          "1p", "2p", "3p", "4p", "5p", "6p", "7p", "8p", "9p", 
    --                          "1s", "2s", "3s", "4s", "5s", "6s", "7s", "8s", "9s", 
    --                          "1z", "2z", "3z", "4z", "5z", "6z", "7z"}
    --         if card == 0 then
    --             card = player:GenerateRandomInt(34) + 1
    --             artifact:SetData("card", tostring(card))
    --         end
    --         if (tile:CompatWith(tostring(ranges[card])) and player:DetermineMaterialCompatibility(tile,Aotenjo.TileMaterial.PLAIN)) then
    --             tile:SetMaterial(materials.wood, player)
    --         end
    --     end)
    --     :BuildAndRegister()
    
    M.sapling = Aotenjo.LuaArtifactBuilder.Create("seven_luminaries:sapling", Aotenjo.Rarity.COMMON)
        :WithMaterialRequired({ "seven_luminaries:wood" })
        :PreGameInitialized(function(player, artifact)
            local ranges = player:GetUniqueFullDeck()
            local goaltile = tonumber(player:GenerateRandomInt(ranges.Count))
            artifact:SetData("goal", tostring(goaltile))
        end)
        :WithDescription(function(player, loc, artifact)
            local goaltile = tonumber(artifact:GetDataOrDefault("goal", -1))
            if player == nil or goaltile < 0 then
                return string.format(loc("artifact_seven_luminaries:sapling_description"), sample_tile_name(loc))
            end
            local ranges = player:GetUniqueFullDeck()
            local goal = ranges[goaltile]
            if goal == nil then
                return string.format(loc("artifact_seven_luminaries:sapling_description"), sample_tile_name(loc))
            end
            return string.format(loc("artifact_seven_luminaries:sapling_description"), goal:GetLocalizedName(loc))
        end)
        -- :OnTileEffect(function(player, perm, tile, effects, artifact)
        --     local goaltile = tonumber(artifact:GetDataOrDefault("goal", -1))
        --     local ranges = player:GetUniqueFullDeck()
        --     if goaltile == -1 then
        --         log("error")
        --         goaltile = player:GenerateRandomInt(ranges.Count)
        --         artifact:SetData("goal", tostring(goaltile))
        --     end
        --     local goal = ranges[goaltile]
        --     if (tile:CompatWith(goal) and player:DetermineMaterialCompatibility(tile,Aotenjo.TileMaterial.PLAIN)) then
        --         log("t3")
        --         tile:SetMaterial(materials.wood, player)
        --         effects:Add(Aotenjo.SimpleEffect("effects_sapling", artifact, function() end))
        --     end
        -- end)
        :OnRoundEndEffect(function(player, perm, effects, artifact)
            local goaltile = tonumber(artifact:GetDataOrDefault("goal", -1))
            local ranges = player:GetUniqueFullDeck()
            local deck = player:GetAllTiles()
            if goaltile == -1 then
                log("error")
                goaltile = player:GenerateRandomInt(ranges.Count)
                artifact:SetData("goal", tostring(goaltile))
            end
            local goal = ranges[goaltile]
            effects:Add(Aotenjo.SimpleEffect("effects_sapling", artifact, function() end))
            for i = 0, deck.Count - 1 do
                local atile = deck[i]
                if (atile:CompatWith(goal) and player:DetermineMaterialCompatibility(atile,Aotenjo.TileMaterial.PLAIN)) then
                    atile:SetMaterial(materials.wood, player)
                end
            end
        end)
        :OnRemoved(function(player, artifact)
            -- effects:Add(Aotenjo.EarnMoneyEffect(2, null))
            log("error1")
            local ranges = player:GetUniqueFullDeck()
            log("error2")
            local goaltile = player:GenerateRandomInt(ranges.Count)
            log("error3")
            artifact:SetData("goal", tostring(goaltile))
        end)
        :BuildAndRegister()
    M.water_bottle = Aotenjo.LuaArtifactBuilder.Create("seven_luminaries:water_bottle", Aotenjo.Rarity.COMMON)
        :WithMaterialRequired({ "seven_luminaries:water" })
        :OnObtain(M.material_gift(materials.water, 5))
        -- :PreGameInitialized(function(player, artifact)
        --     artifact:SetData("ingame", "1")
        -- end)
        :WithDescription(function(player, loc, artifact)
            if player == nil then
                return string.format(loc("artifact_seven_luminaries:water_bottle_description"), 0)
            end
            -- local ingame = tonumber(artifact:GetDataOrDefault("ingame", 0))
            -- if ingame == 1 then 
                local paishan = player:GetTilePool()
                local cnt = math.floor(paishan.Count/2)
                return string.format(loc("artifact_seven_luminaries:water_bottle_description"), cnt)
            -- end
            -- return string.format(loc("artifact_seven_luminaries:water_bottle_description"), 0)
        end)
        :OnTileEffect(function(player, perm, tile, effects, artifact)
            if player:DetermineMaterialCompatibility(tile, materials.water) then
                local paishan = player:GetTilePool()
                local cnt = math.floor(paishan.Count/2)
                effects:Add(Aotenjo.ScoreEffect.AddFu(cnt, artifact))
            end
        end)
        :OnSelfEffect(function(player, perm, effects, artifact)
            local paishan = player:GetTilePool()
            local cnt = math.floor(paishan.Count/2)
            effects:Add(Aotenjo.ScoreEffect.AddFu(cnt, artifact))
        end)
        :BuildAndRegister()
    M.alchemy_furnace = Aotenjo.LuaArtifactBuilder.Create("seven_luminaries:alchemy_furnace", Aotenjo.Rarity.COMMON)
        :WithSetIn({ "seven_luminaries:seven_luminaries" })
        :OnTileEffect(function(player, perm, tile, effects, artifact)
            if M.is_seven_luminaries(player, tile) then
                local actived = tonumber(tile.properties.material:GetDataOrDefault("active", 0))
                if (player:Selecting(tile) and actived == 1) then
                    effects:Add(Aotenjo.EarnMoneyEffect(1, artifact))
                end
            end
        end)
        :BuildAndRegister()
    M.black_lotus = Aotenjo.LuaArtifactBuilder.Create("seven_luminaries:black_lotus", Aotenjo.Rarity.RARE)
        :WithDeckIn({ "rainbow_deck" })
        :WithSetIn({ "seven_luminaries:seven_luminaries" })
        :OnSelfEffect(function(player, perm, effects, artifact)
            local cnt = player.PlayedFlowerTiles.Count
            local handtile = player:GetUnusedTilesInHand()
            local handseven = 0
            for i = 0, handtile.Count - 1 do
                local atile = handtile[i]
                -- log("test4")
                if (materials.sevenluminariescheck(atile, player) and tonumber(atile.properties.material:GetDataOrDefault("active", 0)) == 0) then
                    handseven = handseven + 1
                end
                -- log("test5")
            end
            -- log("check" .. cnt)
            -- local use = 0
            -- if handseven < cnt then
            --     use = handseven
            -- else
            --     use = cnt
            -- end
            local use = math.min(handseven, cnt)
            if use ~= 0 then
                for j = 0, handtile.Count - 1 do
                    local atile = handtile[j]
                    -- log("test8")
                    if (materials.sevenluminariescheck(atile, player) and tonumber(atile.properties.material:GetDataOrDefault("active", 0)) == 0) then
                        materials.activetile(atile, player, atile.properties.material, effects)
                        effects:Add(Aotenjo.SimpleEffect("effects_black_lotus", artifact, function() end))
                        use = use - 1
                        if use == 0 then
                            break
                        end
                    end
                    -- log("testD")
                end
            -- log("testF")
            end
        end)
        :BuildAndRegister()
    M.colorful_earth = Aotenjo.LuaArtifactBuilder.Create("seven_luminaries:colorful_earth", Aotenjo.Rarity.RARE)
        :WithMaterialRequired({ "seven_luminaries:earth" })
        :OnObtain(M.material_gift(materials.earth, 5))
        -- :OnTileEffect(function(player, perm, tile, effects, artifact)
        --     local have_earth = M.earthcheck(player, tile, effects)
        --     if have_earth == 1 then
        --         if (M.is_seven_luminaries(player, tile) and ~(player:DetermineMaterialCompatibility(tile, materials.earth))) then
        --             local actived = tonumber(tile.properties.material:GetDataOrDefault("active", 0))
        --             if actived == 0 then
        --                 effects:Add(Aotenjo.SimpleEffect("effects_active", artifact, function() end))
        --                 materials.activetile(tile, player, tile.properties.material, effects)
        --             end
        --         end
        --     end
        -- end)
        :BuildAndRegister()
    M.tree_fertilizer = Aotenjo.LuaArtifactBuilder.Create("seven_luminaries:tree_fertilizer", Aotenjo.Rarity.RARE)
        :WithMaterialRequired({ "seven_luminaries:wood" })
        :OnObtain(M.material_gift(materials.wood, 5))
        -- :OnObtain(function(player, artifact)
        --     log("ttest1")
        --     artifact:SetData("used", "1")
        -- end)
        :OnTilePostEffect(function(player, perm, tile, effects, artifact)
            -- 每张木牌每次结算只额外计分一次。
            -- 用牌本身作键(tile:GetHashCode),而不是材质:SetMaterial 存的是材质引用,
            -- 幼苗等会给多张牌挂同一个材质实例,用材质哈希会互相顶掉。
            local id = tile:GetHashCode()
            if (player:DetermineMaterialCompatibility(tile, materials.wood) and (tree_fertilizer_usedtile[id] ~= 1)) then
                tree_fertilizer_usedtile[id] = 1
                effects:Add(Aotenjo.SimpleEffect("effects_tree_fertilizer", artifact, function() end))
                effects:Add(Aotenjo.TileScoringEffectAppendEffect(player, tile, perm, player.playHandEffectStack))
            end
        end)
        -- 结算结束后清空标记,下一小局该牌可再次额外计分
        :OnRoundEndEffect(function(player, perm, effects, artifact)
            tree_fertilizer_usedtile = {}
        end)
        :BuildAndRegister()
    M.bottled_flame = Aotenjo.LuaArtifactBuilder.Create("seven_luminaries:bottled_flame", Aotenjo.Rarity.RARE)
        :WithMaterialRequired({ "seven_luminaries:fire" })
        :WithDescription(function(player, loc, artifact)
            if player == nil then
                return string.format(loc("artifact_seven_luminaries:bottled_flame_description"), 3)
            end
            local artifacts = player:GetArtifacts()
            for i = 0, artifacts.Count - 1 do
                local aartifact = artifacts[i]
                if aartifact:GetRegName() == "seven_luminaries:bottled_flame" then
                    local flameaddfan = tonumber(artifact:GetDataOrDefault("flameaddfan", 3))
                    return string.format(loc("artifact_seven_luminaries:bottled_flame_description"), flameaddfan)
                end
            end
            return string.format(loc("artifact_seven_luminaries:bottled_flame_description"), 3)
        end)
        :OnObtain(function(player, artifact)
            artifact:SetData("flameaddfan", "3")
            M.material_gift(materials.fire, 5)(player, artifact)
        end)
        :OnTileEffect(function(player, perm, tile, effects, artifact)
            if tile_suppressed(tile) then return end
            if player:DetermineMaterialCompatibility(tile, materials.fire) then
                local flameaddfan = tonumber(artifact:GetDataOrDefault("flameaddfan", 3))
                if (player:Selecting(tile)) then
                    local actived = tonumber(tile.properties.material:GetDataOrDefault("active", 0))
                    if actived == 0 then
                        flameaddfan = flameaddfan + 2
                    else
                        flameaddfan = flameaddfan + 3
                    end
                    artifact:SetData("flameaddfan", tostring(flameaddfan))
                end
                effects:Add(Aotenjo.SimpleEffect("effects_bottled_flame", artifact, function() end))
            end
        end)
        :OnSelfEffect(function(player, perm, effects, artifact)
            local flameaddfan = tonumber(artifact:GetDataOrDefault("flameaddfan", 3)) 
            effects:Add(Aotenjo.ScoreEffect.AddFan(flameaddfan, artifact))
        end)
        :OnRemoved(function(player, artifact)
            artifact:SetData("flameaddfan", "3")
        end)
        :BuildAndRegister()
    M.ceremony_platform = Aotenjo.LuaArtifactBuilder.Create("seven_luminaries:ceremony_platform", Aotenjo.Rarity.RARE)
        :WithSetIn({ "seven_luminaries:seven_luminaries" })
        :OnTileEffect(function(player, perm, tile, effects, artifact)
            local haveseven = tonumber(artifact:GetDataOrDefault("haveseven", 0))
            if (player:Selecting(tile) and haveseven == 0 and M.is_seven_luminaries(player, tile)) then
                artifact:SetData("haveseven", "1")
            end
        end)
        :OnSelfEffect(function(player, perm, effects, artifact)
            local haveseven = tonumber(artifact:GetDataOrDefault("haveseven", 0))
            if haveseven == 0 then
                local unplayed = player:GetUnusedTilesInHand()
                local cnt = 0
                for i = 0, unplayed.Count - 1 do
                    local atile = unplayed[i]
                    if (player:DetermineMaterialCompatibility(atile,Aotenjo.TileMaterial.PLAIN)) then
                        cnt = cnt + 1
                    end
                end
                if cnt ~= 0 then
                    local place = player:GenerateRandomInt(cnt) + 1
                    for i = 0, unplayed.Count - 1 do
                        local atile = unplayed[i]
                        if (player:DetermineMaterialCompatibility(atile,Aotenjo.TileMaterial.PLAIN)) then
                            place = place - 1
                            if place == 0 then
                                effects:Add(Aotenjo.SimpleEffect("effects_ceremony_platform", artifact, function() end))
                                materials.earthtrans(atile, player, atile.properties.material)
                                break
                            end
                        end
                    end
                end
            end
            artifact:SetData("haveseven", "0")
        end)
        :BuildAndRegister()
    M.tai_chi = Aotenjo.LuaArtifactBuilder.Create("seven_luminaries:tai_chi", Aotenjo.Rarity.EPIC)
        :WithSetIn({ "seven_luminaries:seven_luminaries" })
        :WithDescription(function(player, loc, artifact)
            if player == nil then
                return string.format(loc("artifact_seven_luminaries:tai_chi_description"), 2)
            end
            local artifacts = player:GetArtifacts()
            for i = 0, artifacts.Count - 1 do
                local aartifact = artifacts[i]
                if aartifact:GetRegName() == "seven_luminaries:tai_chi" then
                    local pairss = tonumber(artifact:GetDataOrDefault("pairs", 0))
                    local cnt = pairss * 0.5 + 2
                    return string.format(loc("artifact_seven_luminaries:tai_chi_description"), cnt)
                end
            end
            return string.format(loc("artifact_seven_luminaries:tai_chi_description"), 2)
        end)
        :OnObtain(function(player, artifact)
            artifact:SetData("pairs", "0")
            -- 附赠4:日牌、月牌各2张
            M.material_gift(materials.sun, 2)(player, artifact)
            M.material_gift(materials.moon, 2)(player, artifact)
        end)
        :OnSelfEffect(function(player, perm, effects, artifact)
            local pairss = M.tai_chi_check(player)
            local cnt = pairss * 0.5 + 2
            artifact:SetData("pairs", tostring(pairss))
            log("ttest?")
            effects:Add(Aotenjo.ScoreEffect.MulFan(cnt, artifact))
        end)
        :OnRoundEndEffect(function(player, perm, effects, artifact)
            artifact:SetData("pairs", "0")
        end)
        :OnRemoved(function(player, artifact)
            artifact:SetData("pairs", "0")
        end)
        :BuildAndRegister()
    -- M.grimoire = Aotenjo.LuaArtifactBuilder.Create("seven_luminaries:grimoire", Aotenjo.Rarity.EPIC)
    --     :WithSetIn({ "seven_luminaries:seven_luminaries" })
    --     :WithDescription(function(player, loc, artifact)
    --         local artifacts = player:GetArtifacts()
    --         for i = 0, artifacts.Count - 1 do
    --             local aartifact = artifacts[i]
    --             if aartifact:GetRegName() == "seven_luminaries:grimoire" then
    --                 local gmulfan = tonumber(artifact:GetDataOrDefault("gmulfan", 1.0)) * 1.0
    --                 return string.format(loc("artifact_seven_luminaries:grimoire_description"), gmulfan)
    --             end
    --         end
    --         return string.format(loc("artifact_seven_luminaries:grimoire_description"), 1.0)
    --     end)
    --     :OnObtain(function(player, artifact)
    --         artifact:SetData("gmulfan", "1.0")
    --     end)
    --     :OnTileEffect(function(player, perm, tile, effects, artifact)
    --         local gmulfan = tonumber(artifact:GetDataOrDefault("gmulfan", 1.0)) * 1.0
    --         if M.is_seven_luminaries(player, tile) then
    --             local actived = tonumber(tile.properties.material:GetDataOrDefault("active", 0))
    --             if (player:Selecting(tile) and actived == 1) then
    --                 effects:Add(Aotenjo.SimpleEffect("effects_grimoire", artifact, function() end))
    --                 tile.properties.material:SetData("active", tostring(0))
    --                 if (player:DetermineMaterialCompatibility(tile, materials.sun) or player:DetermineMaterialCompatibility(tile, materials.moon)) then
    --                     gmulfan = gmulfan + 0.2
    --                 else
    --                     gmulfan = gmulfan + 0.1
    --                 end
    --                 artifact:SetData("gmulfan", tostring(gmulfan))
    --             end
    --         end
    --     end)
    --     :OnSelfEffect(function(player, perm, effects, artifact)
    --         local gmulfan = tonumber(artifact:GetDataOrDefault("gmulfan", 1.0)) * 1.0
    --         log("ttest?")
    --         effects:Add(Aotenjo.ScoreEffect.MulFan(gmulfan, artifact))
    --     end)
    --     :OnRemoved(function(player, artifact)
    --         artifact:SetData("gmulfan", "1.0")
    --     end)
    --     :BuildAndRegister()
    M.grimoire = Aotenjo.LuaArtifactBuilder.Create("seven_luminaries:grimoire", Aotenjo.Rarity.EPIC)
        :WithSetIn({ "seven_luminaries:seven_luminaries" })
        :WithDescription(function(player, loc, artifact)
            if player == nil then
                return string.format(loc("artifact_seven_luminaries:grimoire_description"), 1.0)
            end
            local artifacts = player:GetArtifacts()
            for i = 0, artifacts.Count - 1 do
                local aartifact = artifacts[i]
                if aartifact:GetRegName() == "seven_luminaries:grimoire" then
                    local gmulfan = tonumber(artifact:GetDataOrDefault("gmulfan", 1.0)) * 1.0
                    return string.format(loc("artifact_seven_luminaries:grimoire_description"), gmulfan)
                end
            end
            return string.format(loc("artifact_seven_luminaries:grimoire_description"), 1.0)
        end)
        :OnObtain(function(player, artifact)
            artifact:SetData("gmulfan", "1.0")
            -- 附赠7:七种七曜牌各1张
            M.material_gift(materials.metal, 1)(player, artifact)
            M.material_gift(materials.wood, 1)(player, artifact)
            M.material_gift(materials.water, 1)(player, artifact)
            M.material_gift(materials.fire, 1)(player, artifact)
            M.material_gift(materials.earth, 1)(player, artifact)
            M.material_gift(materials.sun, 1)(player, artifact)
            M.material_gift(materials.moon, 1)(player, artifact)
        end)
        :OnRoundEndEffect(function(player, perm, effects, artifact)
            if perm == nil then
                return
            end
            local played = perm:ToTiles()
            local gmulfan = tonumber(artifact:GetDataOrDefault("gmulfan", 1.0)) * 1.0
            local check = 0
            for i = 0, played.Count - 1 do
                local atile = played[i]
                if (M.is_seven_luminaries(player, atile) and tonumber(atile.properties.material:GetDataOrDefault("active", 0)) == 1) then
                    -- effects:Add(Aotenjo.SimpleEffect("effects_grimoire", atile, function() end))
                    check = 1
                    gmulfan = gmulfan + 0.05
                end
            end
            if check == 1 then
                effects:Add(Aotenjo.SimpleEffect("effects_grimoire", artifact, function() end))
            end
            artifact:SetData("gmulfan", tostring(gmulfan))
        end)
        :OnSelfEffect(function(player, perm, effects, artifact)
            local gmulfan = tonumber(artifact:GetDataOrDefault("gmulfan", 1.0)) * 1.0
            log("ttest?")
            effects:Add(Aotenjo.ScoreEffect.MulFan(gmulfan, artifact))
        end)
        :OnRemoved(function(player, artifact)
            artifact:SetData("gmulfan", "1.0")
        end)
        :BuildAndRegister()
    M.golden_dan = Aotenjo.LuaArtifactBuilder.Create("seven_luminaries:golden_dan", Aotenjo.Rarity.EPIC)
        :WithMaterialRequired({ "seven_luminaries:metal" })
        :WithDescription(function(player, loc, artifact)
            if player == nil then
                return string.format(loc("artifact_seven_luminaries:golden_dan_description"), 1.0)
            end
            local artifacts = player:GetArtifacts()
            for i = 0, artifacts.Count - 1 do
                local aartifact = artifacts[i]
                if aartifact:GetRegName() == "seven_luminaries:golden_dan" then
                    local gomulfan = tonumber(artifact:GetDataOrDefault("gomulfan", 1.00)) * 1.00
                    return string.format(loc("artifact_seven_luminaries:golden_dan_description"), gomulfan)
                end
            end
            return string.format(loc("artifact_seven_luminaries:golden_dan_description"), 1.0)
        end)
        :OnObtain(function(player, artifact)
            artifact:SetData("gomulfan", "1.00")
            M.material_gift(materials.metal, 5)(player, artifact)
        end)
        :OnTileEffect(function(player, perm, tile, effects, artifact)
            if tile_suppressed(tile) then return end
            local gomulfan = tonumber(artifact:GetDataOrDefault("gomulfan", 1.00)) * 1.00
            if player:DetermineMaterialCompatibility(tile, materials.metal) then
                local metalhit = tonumber(tile.properties.material:GetDataOrDefault("metalget", 0))
                if metalhit == 1 then
                    local actived = tonumber(tile.properties.material:GetDataOrDefault("active", 0))
                    if actived == 0 then
                        gomulfan = gomulfan + 0.04
                    else
                        gomulfan = gomulfan + 0.06
                    end
                end
            end
            log("gomulfan " .. tostring(gomulfan))
            artifact:SetData("gomulfan", tostring(gomulfan))
        end)
        :OnSelfEffect(function(player, perm, effects, artifact)
            local gomulfan = tonumber(artifact:GetDataOrDefault("gomulfan", 1.00)) * 1.00
            log("gomulfan " .. tostring(gomulfan))
            effects:Add(Aotenjo.ScoreEffect.MulFan(gomulfan, artifact))
        end)
        :OnRemoved(function(player, artifact)
            artifact:SetData("gomulfan", "1.00")
        end)
        :BuildAndRegister()
end
return M

-- setHand 111111111111m111g
-- setMat 0-11 seven_luminaries:fire
-- give seven_luminaries:black_lotus
-- effects.Add(new TileScoringEffectAppendEffect(player, tile, permutation, player.playHandEffectStack));