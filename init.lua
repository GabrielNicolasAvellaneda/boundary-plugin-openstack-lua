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

function KeystoneClient:getToken(callback)
	
	local data = {auth = { tenantName = self.tenantName, passwordCredentials ={username = self.username,  password = self.password}} }
	local path = '/v2.0/tokens'

	local postData = json.stringify(data)

	local headers = {}
	headers['Content-Type'] = 'application/json'
	headers['Content-Length'] = #postData 	
	headers['Accept'] = 'application/json'

	local reqOptions = {
		host = self.host,
		port = self.port,
		path = path,
		method = 'POST',
		headers = headers
	}

	local req = http.request(reqOptions, function (res) 
	
		res:on('data', function (data) 
			local parsed = json.parse(data)	
			if callback then callback(parsed) end	
			end)

		res:on('error', function (err)  p(err.message) end)
	end)

	req:on('error', function (err) self:emit('error', err.message) end)
	req:write(postData)
	req:done()
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

