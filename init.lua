local framework = require('framework')
local Plugin = framework.Plugin
local DataSource = framework.DataSource
local Emitter = require('core').Emitter
local stringutils = framework.string
local math = require('math')
local json = require('json')
local http = require('http')
local table = require('table')
local url = require('url')
local os = require('os')
require('fun')(true)

local params = framework.boundary.param
params.name = 'Boundary OpenStack plugin'
params.version = '1.0'

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
local request = framework.http.get

local Nothing = {
	_create = function () return Nothing end,
	__index = _create, 
	isNothing = true
}
setmetatable(Nothing, Nothing)

function Nothing.isNothing(value) 
	return value and value.isNothing	
end

function Nothing:apply(map)
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
	req:propagate('error', self)
end

function getEndpoint(name, endpoints)
	
	return nth(1, totable(filter(function (e) return e.name == name end, endpoints)))
end


function getAdminUrl(endpoint)
	return get('adminURL', nth(1, get('endpoints', endpoint)))
end

function getToken(data)
	return get('id', (get('token',(get('access', data)))))
end


local CeilometerClient = Emitter:extend()

function CeilometerClient:initialize(host, port, tenant, username, password)
	self.host = host
	self.port = port
	self.tenant = tenant
	self.username = username
	self.password = password
end


function CeilometerClient:getMetric(metric, period, callback)

	local client = KeystoneClient:new(self.host, self.port, self.tenant, self.username, self.password)
	client:propagate('error', self)

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
			local datetime = os.date("!%Y-%m-%dT%H:%M:%S", os.time()-3600) 
			local path = '/v2/meters/' .. metric .. '/statistics?q.field=timestamp&q.op=gt&q.type=&q.value=' .. datetime .. '&period=' .. period	
			local urlParts = url.parse(adminUrl)
			
			local options = {
				host = urlParts.hostname,
				port = urlParts.port,
				path = path,
				headers = headers
			}
			
			local req = request(options, nil, function (res) 
				if callback then
					callback(res)
				end
			end, 'json', false)
			req:propagate('error', self) -- Propagate errors
		end
	end)
end

local mapping = {}

mapping['cpu_util'] = {avg = 'OS_CPUUTIL_AVG', sum = 'OS_CPUUTIL_SUM', min = 'OS_CPUUTIL_MIN', max = 'OS_CPUUTIL_MAX'}
mapping['cpu'] = {avg = 'OS_CPU_AVG', sum = 'OS_CPU_SUM'}
mapping['instance'] = {sum = 'OS_INSTANCE_SUM', max = 'OS_INSTANCE_MAX'}
mapping['memory'] = {sum = 'OS_MEMORY_SUM', avg = 'OS_MEMORY_AVG'}
mapping['memory.usage'] = {sum = 'OS_MEMORY_USAGE_SUM', avg = 'OS_MEMORY_USAGE_AVG'}
mapping['volume'] = {sum = 'OS_VOLUME_SUM', avg = 'OS_VOLUME_AVG'}
mapping['image'] = {sum = 'OS_IMAGE_SUM', avg = 'OS_IMAGE_AVG'}
mapping['image.size'] = {avg = 'OS_IMAGE_SIZE_AVG', sum = 'OS_IMAGE_SIZE_SUM'}
mapping['disk.read.requests.rate'] = {sum = 'OS_DISK_READ_RATE_SUM', avg = 'OS_DISK_READ_RATE_AVG'}
mapping['disk.write.requests.rate'] = {sum = 'OS_DISK_WRITE_RATE_SUM', avg = 'OS_DISK_WRITE_RATE_AVG'}
mapping['network.incoming.bytes'] = {sum = 'OS_NETWORK_IN_BYTES_SUM', avg = 'OS_NETWORK_IN_BYTES_AVG'}
mapping['network.outgoing.bytes'] = {sum = 'OS_NETWORK_OUT_BYTES_SUM', avg = 'OS_NETWORK_OUT_BYTES_AVG'}

local OpenStackDataSource = DataSource:extend()

function OpenStackDataSource:initialize(host, port, tenant, username, password)

	self.host = host
	self.port = port
	self.tenant = tenant
	self.username = username
	self.password = password
end

function OpenStackDataSource:fetch(context, callback)

	local ceilometer = CeilometerClient:new(self.host, self.port, self.tenant, self.username, self.password) 
	ceilometer:propagate('error', context)

	for metric,v in pairs(mapping) do

		ceilometer:getMetric(metric, 300,
			function (result)
				if callback then
					callback(metric, result)
				end
			end
		)
	end
end

local dataSource = OpenStackDataSource:new(params.service_host, params.service_port, params.service_tenant, params.service_username, params.service_password)
local plugin = Plugin:new(params, dataSource)
function plugin:onParseValues(metric, data)
	local result = {}
	
	if data == nil then
		return {}
	end
	
	local m = mapping[metric]
	--local data = nth(1, data)
	local data = data[#data]
	for col, boundaryName in pairs(m) do
		result[boundaryName] = tonumber(get(col, data))
	end

	return result 
end

plugin:poll()

