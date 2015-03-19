local framework = require('framework/framework.lua')
local Plugin = framework.Plugin
local DataSource = framework.DataSource
local Emitter = require('core').Emitter
local stringutils = framework.string
local math = require('math')
local json = require('json')
local net = require('net') -- TODO: This dependency will be moved to the framework.
local http = require('http')
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

function post(options, data, callback, dataType)
	local headers = {} 
	if type(options.headers) == 'table' then
		headers = options.headers
	end

	if dataType == 'json' then
		headers['Content-Type'] = 'application/json'
		headers['Content-Length'] = #data 
		headers['Accept'] = 'application/json'
	end

	local reqOptions = {
		host = options.host,
		port = options.port,
		path = options.path,
		method = 'POST',
		headers = headers
	}

	local req = http.request(reqOptions, function (res) 
	
		res:on('data', function (data) 
			if dataType == 'json' then
				data = json.parse(data)	
			end

			if callback then callback(data) end	
		end)

		res:on('error', function (err)  req:emit('error', err.message) end)
	end)

	req:write(data)
	req:done()

	return req
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

local client = KeystoneClient:new('localhost', 5000, 'admin', 'admin', '123456')
client:on('error', p)
client:getToken(function (data)
	local hasError = get('error', data)

	if hasError ~= nil then
		p(get('error', data))
	else
		p(get('id', (get('token',(get('access', data))))))
	end
end)

local CeilometerClient = Emitter:extend()

function CeilometerClient:initialize(host, port, tenantName, username, password)
	self.host = host
	self.port = port
	self.tenantName = tenantName
	self.username = username
	self.password = password
end

function CeilometerClient:getMetric(metric, groupBy)
	print('unimplemented!')
	return nil
end

function HttpDataSource:initialize(host, port, path, username, password)
	self.host = host
	self.port = port
	self.path = path
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

