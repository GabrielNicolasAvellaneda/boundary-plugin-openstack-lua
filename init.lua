local framework = require('framework/framework.lua')
local Plugin = framework.Plugin
local DataSource = framework.DataSource
local math = require('math')

local params = framework.boundary.param
params.name = 'LUA demo plugin'
params.version = '1.0'

local RandomDataSource = DataSource:extend()

function RandomDataSource:initialize(minValue, maxValue)
	self.minValue = minValue
	self.maxValue = maxValue
end

function RandomDataSource:fetch(context, callback)
	
	local value = math.random(self.minValue, self.maxValue)
	if not callback then error('fetch: you must set a callback when calling fetch') end

	callback(value)
end

local dataSource = RandomDataSource:new(params.minValue, params.maxValue)
local plugin = Plugin:new(params, dataSource)
-- Must override to map datasource data to metrics.
function plugin:onParseValues(data)
	local result = {}
	result['BOUNDARY_LUA_SAMPLE'] = tonumber(data)

	return result 
end

plugin:poll()
