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
  local status = indexAttribute()
  Helix.Core.Server.SetClientMsg(status)
  return true
end

function indexAttribute()
  -- print("Going to call index asset...")

  local xAuthToken = config["auth_token"]
  print("xAuthToken: " .. xAuthToken)
  local p4searchUrl = config["p4search_url"]
  local url = p4searchUrl
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
  print("Going to call p4search: " .. url)

  local c = curl.easy{
    url        = url,
    customrequest = "PATCH",
    httpheader = headers,
    postfields = encoded_payload,
  }
  local ok, err = c:perform()
  c:close()

  if not ok then
    return "Error occurred indexing attributes..."
  else return ""
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
