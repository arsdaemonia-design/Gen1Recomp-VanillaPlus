package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")
local Data = require("src.core.Data")
Data:load()

local Font = require("src.render.Font")
Font.load(Data)
require("data.scripts.init")

local run = T.sdk.loadMod("mods/vanilla-plus", { data = Data })
T.eq(#run.errors, 0, "vanilla-plus loads clean")
T.check(Data.items.RUNNING_SHOES ~= nil, "running shoes item registered")
T.check(Data.items.RUNNING_SHOES_STOLEN ~= nil, "stolen shoes item registered")
T.check(Data.trainers.RUNNING_SHOES_THIEF ~= nil, "thief trainer registered")
T.check(Data.maps.VIRIDIAN_MART ~= nil, "Viridian Mart map exists")
T.check(Data.maps.ROUTE_2 ~= nil, "Route 2 map exists")

local MapScripts = require("src.script.MapScripts")
T.check(MapScripts.talkScript("VIRIDIAN_MART", "TEXT_VIRIDIANMART_CLERK") ~= nil,
  "merchant script registered")
T.check(MapScripts.talkScript("VIRIDIAN_MART", "TEXT_RUNNING_SHOES_VICTIM") ~= nil,
  "victim script registered")
T.check(MapScripts.talkScript("ROUTE_2", "TEXT_RUNNING_SHOES_THIEF") ~= nil,
  "thief script registered")

run.release()
T.finish("vanilla-plus")
