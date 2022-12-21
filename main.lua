local cjson = require "cjson"
local curl = require "cURL.safe"

local initDone = false
local config = {}

-- Remove leading and trailing whitespace from a string.
function trim( s )
	return ( s:gsub( "^%s*(.-)%s*$", "%1" ) )
end

-- Read the configuration settings the first time.
-- Read the global config first, then the instance config. The latter could
-- override the former if there are duplicate variable names. This is assumed
-- to be a desirable feature.
function init()
	-- Uncomment for debugging
	-- print("Initializing...")
	if initDone == false then
		for k, v in pairs(Helix.Core.Server.GetGlobalConfigData()) do
			if string.len(trim(v)) > 0 then
				config[k] = trim(v)
			end
		end

		for k, v in pairs(Helix.Core.Server.GetInstanceConfigData()) do
			if string.len(trim(v)) > 0 then
				config[k] = trim(v)
			end
		end
		initDone = true
	end
end

-- Write a log message to the extension log, along with some user data.
function log(msg)
	local host = Helix.Core.Server.GetVar("clientip")
	local user = Helix.Core.Server.GetVar("user")
	Helix.Core.Server.log({ ["user"] = user, ["host"] = host, ["msg"] = msg })
end

function GlobalConfigFields()
	return {}
end

function InstanceConfigFields()
	return {}
end

function InstanceConfigEvents()
	return { command = "post-user-attribute" }
end

function Command()
	init()

	-- Read properties from P4
	local p4 = P4.P4:new()
	p4:autoconnect()
	if not p4:connect() then
		Helix.Core.Server.ReportError( Helix.Core.P4API.Severity.E_FAILED, "Error connecting to server\n" )
		return false
	end
	local props = p4:run("property", "-l", "-nP4.P4Search.URL")
	local p4searchUrl = props[1]["value"]
	props = p4:run("property", "-l", "-nP4.P4Search.AUTH_TOKEN")
	local xAuthToken = props[1]["value"]
	p4:disconnect()

	local status = indexAttribute(p4searchUrl, xAuthToken)
	Helix.Core.Server.SetClientMsg(status)
	return true
end

function indexAttribute(p4searchUrl, xAuthToken)
	-- print("Going to call index asset...")
	headers = {
		"Accept: application/json",
		"X-Auth-Token: " .. xAuthToken
	}

	local argsQuoted = Helix.Core.Server.GetVar("argsQuoted")
	print("argsQuoted: " .. argsQuoted)

	-- Separate files from argsQuoted
	local files = getFileArgs(argsQuoted)

	local client = Helix.Core.Server.GetVar("client")
	local clientcwd = Helix.Core.Server.GetVar("clientcwd")
	local t = {
		["argsQuoted"] = files,
		["client"] = client,
		["clientcwd"] = clientcwd
	}

	local encoded_payload = cjson.encode(t)
	print("encoded_payload: " .. encoded_payload)
	p4searchUrl = p4searchUrl .. "/api/v1/index/asset"
	print("Going to call p4search: " .. p4searchUrl)

	local c = curl.easy{
		url				= p4searchUrl,
		customrequest	= "PATCH",
		httpheader		= headers,
		postfields		= encoded_payload,
	}
	local response = c:perform()
	local code = c:getinfo(curl.INFO_RESPONSE_CODE)
	c:close()

	-- Unreachable server
	if not response
	then
		log("Server unreachable. Asset url: " .. p4searchUrl)
		return ""
	end

	if code == 200 then
		-- Return nothing as returning a string breaks p4java.
		log("Asset request sent. Asset url: " .. p4searchUrl)
		return ""
	else
		log("Asset request failed. Status: " .. tostring(code) .. " Asset url: " .. p4searchUrl) 
		return ""
	end
end

function getFileArgs(args)
	local filesStr = ''
	local skipNext = false
	for w in string.gmatch(args, "[^,]*,?") do
		if not skipNext then
			local file, skip = getFileArg(w)
			if file and file ~= '' then
				filesStr = filesStr .. file .. ","
			end
			skipNext = skip
		else
			skipNext = false
		end
	end
	-- Remove the last comma
	filesStr = string.gsub(filesStr, ",$", "")
	print("filesStr: " .. filesStr)
	return filesStr
end

function getFileArg(w)
	w = trim(w)
	local word = string.gsub(w, ",$", "")

	if word == "-n" or word == "-v" then
		-- Ignore option and the following parameter
		return nil, true
	elseif not (string.find(word, "-") == 1) then
		-- This must be one of the actual path we want.
		return word, false
	end
	-- Just a flag, ignore
	return nil, false
end
