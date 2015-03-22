local framework = require('framework/framework.lua')
local Plugin = framework.Plugin
local DataSource = framework.DataSource
local Emitter = require('core').Emitter
local stringutils = framework.string
local math = require('math')
local json = require('json')
local net = require('net') -- TODO: This dependency will be moved to the framework.
local http = require('http')
local table = require('table')
require('fun')(true)

local params = framework.boundary.param
params.name = 'Boundary OpenStack plugin'
params.version = '1.0'

local HttpDataSource = DataSource:extend()
local RandomDataSource = DataSource:extend()

local KeystoneClient = Emitter:extend() 

function KeystoneClient:initialize(host, port, tenantName, username, password)
	self.host = host
	self.port = port
	self.tenantName = tenantName
	self.username = username
	self.password = password
end

local get = framework.table.get
local post = framework.http.post

local Nothing = {
	_create = function () return Nothing end,
	__index = _create, 
	isNothing = true
}
setmetatable(Nothing, Nothing)

function Nothing.isNothing(value) 
	return value and value.isNothing	
end

function Nothing.apply(map)
	if type(map) ~= 'table' then
		return
	end

	local mt = self or Nothing
	setmetatable(map, mt) 

	for _, v in pairs(map) do
		apply(v)
	end
end

function KeystoneClient:buildData(tenantName, username, password)
	local data = json.stringify({auth = { tenantName = tenantName, passwordCredentials ={username = username,  password = password}} })

	return data
end

function KeystoneClient:getToken(callback)
	
	local data = self:buildData(self.tenantName, self.username, self.password)
	local path = '/v2.0/tokens'
	local options = {
		host = self.host,
		port = self.port,
		path = path
	}

	local req = post(options, data, callback, 'json') 
	-- Propagate errors 
	req:on('error', function (err) self:emit(err) end)
end

function getEndpoint(name, endpoints)
	
	return totable(filter(function (e) return e.name == name end, endpoints))[1]
end


function getAdminUrl(endpoint)
	return get('adminURL', nth(1, get('endpoints', endpoint)))
end

function getToken(data)
	return get('id', (get('token',(get('access', data)))))
end


local CeilometerClient = Emitter:extend()

function CeilometerClient:initialize(host, port, tenantName, username, password)
	self.host = host
	self.port = port
	self.tenantName = tenantName
	self.username = username
	self.password = password
end

function CeilometerClient:getMetric(metric, period, groupBy, callback)

	local client = KeystoneClient:new(self.host, self.port, self.tenantName, self.username, self.password)
	client:on('error', function (err) 
		-- Propagate errors
		self:emit('error', err)
	end)

	client:getToken(function (data)
		local hasError = get('error', data)
		if hasError ~= nil then
			-- Propagate errors
			self:emit('error', data)
		else
			local token = getToken(data) 
			local endpoints = get('serviceCatalog', get('access', data))
			local adminUrl = getAdminUrl(getEndpoint('ceilometer', endpoints))

			local headers = {}
			headers['X-Auth-Token'] = token

			if callback then
				callback()
			end
		end
	end)
end

local ceilometer = CeilometerClient:new('localhost', 5000, 'admin', 'admin', '123456') 
ceilometer:getMetric('cpu.util', 300, 'avg', function () print('getMetric callback') end) 

function HttpDataSource:initialize(host, port, path, tenantName, username, password)
	self.host = host
	self.port = port
	self.path = path
	self.tenantName = tenantName
	self.username = username
	self.password = password
end



function HttpDataSource:hasCredentials()
	return stringutil.notEmpty(self.username) and stringutil.notEmpty(self.password)
end

function HttpDataSource:fetch(context, callback)
	local req = http.request(reqOptions, function (res)

		res:on('data', function (chunk)
			if callback then
				callback(data)
			end
		end)

		res:on('error', function (err)
			self:emit('error', err.message)
		end)

	end)

	req:on('error', function (err)
		self:emit('error', err.message)
	end)

	req:done()
end

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

--plugin:poll()

