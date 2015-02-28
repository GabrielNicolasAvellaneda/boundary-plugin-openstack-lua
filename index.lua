local framework = require('framework/framework.lua')
local Plugin = framework.Plugin


local params = boundary.params
params.name = 'LUA demo plugin'
params.version = '1.0'

local plugin = Plugin:new(params)
plugin:poll()
