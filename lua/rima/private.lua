-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local rawtostring, type = tostring, type
local getfenv, ipairs = getfenv, ipairs

module(...)
local rima = getfenv(0).rima

-- Private functionality -------------------------------------------------------

rima.number_format = "%.4g"
function rima.tostring(x)
  if type(x) == "number" then
    return rima.number_format:format(x)
  else
    return rawtostring(x)
  end
end


function rima.imap(f, t)
  local r = {}
  for i, v in ipairs(t) do r[i] = f(v) end
  return r
end


-- EOF -------------------------------------------------------------------------
