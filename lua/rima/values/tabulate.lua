-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local debug = require("debug")
local error, xpcall = error, xpcall
local ipairs, require = ipairs, require
local next = next

local object = require("rima.object")
local scope = require("rima.scope")
local rima = rima

module(...)

local ref = require("rima.ref")
local expression = require("rima.expression")

-- Tabulation ------------------------------------------------------------------

local tabulate_type = object:new(_M, "tabulate")


function tabulate_type:new(indexes, e)
  local new_indexes = {}
  for i, s in ipairs(indexes) do
    local v, set = next(s)
    if type(v) == "string" then
      new_indexes[i] = { ref = v, set = set }
    else
      error(("bad index #%d to tabulate: expected string, got '%s' (%s)"):
        format(i, rima.repr(v), type(v)), 0)
    end
  end

  return object.new(self, { expression=e, indexes=new_indexes})
end


function tabulate_type:__repr(format)
  return ("tabulate({%s}, %s)"):format(
    rima.concat(self.indexes, ", ", function(i) return i.ref end),
    rima.repr(self.expression, format))
end
__tostring = __repr


function tabulate_type:__address(S, a, i, eval)
  if #a - i + 1 < #self.indexes then
    error(("tabulate: error evaluating '%s' as '%s': the tabulation needs %d indexes, got %d"):
      format(__repr(self), rima.repr(self.expression), #self.indexes, #a - i + 1), 0)
  end
  S2 = scope.spawn(S, nil, {overwrite=true})

  for _, j in ipairs(self.indexes) do
    S2[j.ref] = eval(a:value(i), S)
    i = i + 1
  end

  status, r = xpcall(function() return eval(self.expression, S2) end, debug.traceback)
  if not status then
    local i = 0
    local args = rima.concat(self.indexes, ", ",
      function(si) i = i + 1; return ("%s=%s"):format(si.ref, rima.repr(a:value(i))) end)
    error(("tabulate: error evaluating '%s' as '%s' where %s:\n  %s"):
      format(__repr(self), rima.repr(self.expression), args, r:gsub("\n", "\n  ")), 0)
  end
  return r, i <= #a and i or nil
end


-- EOF -------------------------------------------------------------------------

