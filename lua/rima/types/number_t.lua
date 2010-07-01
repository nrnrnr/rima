-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local math = require("math")
local error = error

local args = require("rima.lib.args")
local lib = require("rima.lib")
local undefined_t = require("rima.types.undefined_t")
local rima = rima

module(...)

-- Number type -----------------------------------------------------------------

local number_t = undefined_t:new(_M, "number_t")

function number_t:new(lower, upper, integer)
  local fname, usage =
    "rima.types.number_t:new",
    "new([lower_bound [, upper_bound, [, is_integral]]])"

  lower, upper = lower or -math.huge, upper or math.huge
  integer = (integer and true) or false

  args.check_type(lower, "lower_bound", "number", usage, fname)
  args.check_type(upper, "upper_bound", "number", usage, fname)

--  lower, upper = rima.eval(lower), rima.eval(upper)

--  assert((type(lower) == "number" or variable.isa(lower) or expression.isa(lower)) and
--         (type(upper) == "number" or variable.isa(upper) or expression.isa(upper)),
--         "Upper and lower bounds must be numbers, variables or expressions")

  if type(lower) == "number" and type(upper) == "number" and lower > upper then
    error(("%s: lower bound must be <= upper bound, got %s and %s.\n  Usage: %s"):format(
          fname, lib.repr(lower), lib.repr(upper), usage))
  end
  if type(lower) == "number" and integer and math.floor(lower) ~= lower then
    error(("%s: lower bound is not integer, got %s.\n  Usage: %s"):format(
          fname, lib.repr(lower), usage))
  end
  if type(upper) == "number" and integer and math.floor(upper) ~= upper then
    error(("%s: upper bound is not integer, got %s.\n  Usage: %s"):format(
          fname, lib.repr(upper), usage))
  end

  return undefined_t.new(self, { lower=lower, upper=upper, integer=integer })
end


-- String representation -------------------------------------------------------

function number_t:__repr(format)
  if self.integer and self.lower == 0 and self.upper == 1 then return "binary" end
--  return ("%s <= V <= %s, V %s"):format(
--    lib.repr(self.lower), lib.repr(self.upper), self.integer and "integer" or "real")
  return ("%s <= * <= %s, * %s"):format(
    lib.repr(self.lower, format), lib.repr(self.upper, format), self.integer and "integer" or "real")
end
number_t.__tostring = lib.__tostring


function number_t:describe(vars)
--  local lower, upper = rima.eval(self.lower, env), rima.eval(self.upper, env)
  if self.integer and self.lower == 0 and self.upper == 1 then return vars.." binary" end
  return ("%s <= %s <= %s, %s %s"):format(
    lib.repr(self.lower), vars, lib.repr(self.upper), vars, self.integer and "integer" or "real")
end

--[[
function number_t:describe(vars, env)
  local lower, upper = rima.eval(self.lower, env), rima.eval(self.upper, env)
  if self.integer and self.lower == 0 and self.upper == 1 then return vars.." binary" end
  return ("%s <= %s <= %s, %s %s"):format(
    lib.repr(lower), vars, lib.repr(upper), vars, self.integer and "integer" or "real")
end
--]]
-- Checks ----------------------------------------------------------------------

function number_t:includes(x)
  local fname, usage =
    "rima.types.number_t:includes",
    "includes(x<number or type>)"

  if type(x) == "number" then
    if x < self.lower then return false end
    if x > self.upper then return false end
    if self.integer and x ~= math.floor(x) then return false end
    return true
  elseif undefined_t:isa(x) then
    if number_t:isa(x) then
      if x.lower < self.lower then return false end
      if x.upper > self.upper then return false end
      if self.integer and not x.integer then return false end
      return true
    else
      return false
    end
  else
    return false
  end
end

--[[

function number_t:defined(env)
  local lower, upper = rima.eval(self.lower, env), rima.eval(self.upper, env)
  return type(lower) == "number" and type(upper) == "number"
end

function number_t:evaluate(env)
  local lower, upper = rima.eval(self.lower, env), rima.eval(self.upper, env)
  return lower, upper, self.integer
end

function number_t:check(v, env)
  v = rima.eval(v, env)
  local lower, upper = rima.eval(self.lower, env), rima.eval(self.upper, env)
  if type(v) == "number" then
    if type(lower) == "number" then
      assert(v >= lower, "The value is less than the lower bound")
    end
    if type(upper) == "number" then
      assert(v <= upper, "The value is greater than the upper bound")
    end
    assert(not self.integer or math.floor(v) == v, "The value in not an integer")
  end
end

--]]
-- Standard number types and shortcuts -----------------------------------------

local _free
local _positive
local _negative
local _integer
local _binary

function rima.free(lower, upper)
  _free = _free or number_t:new()

--  lower, upper = rima.eval(lower), rima.eval(upper)
  if not lower and not upper then
    return _free
  else
    return number_t:new(lower, upper)
  end
end

function rima.positive(lower, upper)
  local fname, usage =
    "rima.positive",
    "positive([lower_bound [, upper_bound]])"
  _positive = _positive or number_t:new(0)

--  lower, upper = rima.eval(lower), rima.eval(upper)
  if not lower and not upper then
    return _positive
  else
    local n = number_t:new(lower, upper)
    if not _positive:includes(n) then
      error(("%s: bounds for positive variables must be positive"):format(fname, usage))
    end
    return n
  end
end

function rima.negative(lower, upper)
  local fname, usage =
    "rima.negative",
    "negative([lower_bound [, upper_bound]])"

  _negative = _negative or number_t:new(nil, 0)
--  lower, upper = rima.eval(lower), rima.eval(upper)
  if not lower and not upper then
    return _negative
  else
    local n = number_t:new(lower, upper)
    if not _negative:includes(n) then
      error(("%s: bounds for negative variables must be negative"):format(fname, usage))
    end
    return n
  end
end

function rima.integer(lower, upper)
  _integer = _integer or number_t:new(0, math.huge, true)

--  lower, upper = rima.eval(lower), rima.eval(upper)
  if not lower and not upper then
    return _integer
  else
    return number_t:new(lower, upper, true)
  end
end

function rima.binary()
  _binary = _binary or number_t:new(0, 1, true)
  return _binary
end


-- EOF -------------------------------------------------------------------------

