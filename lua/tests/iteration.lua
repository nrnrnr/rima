-- Copyright (c) 2009 Incremental IP Limited
-- see license.txt for license information

local series = require("test.series")
local object = require("rima.object")
require("rima.iteration")
require("rima.public")
local rima = rima

module(...)

-- Tests -----------------------------------------------------------------------

function test(show_passes)
  local T = series:new(_M, show_passes)
  
  local x, y, Q, R, r = rima.R"x, y, Q, R, r"
  local S = { x = { 10, 20, 30 }, Q = {"a", "b", "c"}, R = rima.range(2, r) }
  
  T:check_equal(rima.sum({Q}, x[Q]), "sum({Q}, x[Q])")
  T:check_equal(rima.E(rima.sum({Q}, x[Q]), S), 60)
  T:check_equal(rima.sum({rima.alias(Q, "y")}, x[y]), "sum({y in Q}, x[y])")
  T:check_equal(rima.sum({rima.alias(Q, "Q")}, x[Q]), "sum({Q}, x[Q])")
  T:check_equal(rima.E(rima.sum({rima.alias(Q, "y")}, x[y]), S), 60)
  T:check_equal(rima.sum({rima.alias(Q, "y")}, y.index), "sum({y in Q}, y.index)")
  T:check_equal(rima.E(rima.sum({rima.alias(Q, "y")}, y.index), S), 6)
  T:check_equal(rima.E(rima.sum({rima.alias(x, "y")}, y.value), S), 60)
  T:check_equal(rima.sum({R}, R.value), "sum({R}, R.value)")
  T:check_equal(rima.E(rima.sum({R}, R.value), S), "sum({R in range(2, r)}, R.value)")
  T:check_equal(rima.E(rima.sum({rima.alias(R, "y")}, y.value), S), "sum({y in range(2, r)}, y.value)")
  S.r = 10
  T:check_equal(rima.E(rima.sum({R}, R.value), S), 54)
  T:check_equal(rima.E(rima.sum({rima.alias(R, "y")}, y.value), S), 54)
  T:check_equal(rima.E(rima.sum({rima.alias(R, "y")}, y.index), S), 45)

  do
    local x, k, v = rima.R"x, k, v"
    local S = rima.scope.create{ x = { 10, 20, 30 }, y = { 10, 20, 30, a = 10 } }
    T:check_equal(rima.sum({rima.pairs(x, k, v)}, k + v), "sum({k, v in pairs(x)}, k + v)")
    T:check_equal(rima.sum({rima.ipairs(x, k, v)}, k + v), "sum({k, v in ipairs(x)}, k + v)")
    T:check_equal(rima.E(rima.sum({rima.pairs(x, k, v)}, k + v), S), 66)
    T:check_equal(rima.E(rima.sum({rima.pairs(y, k, v)}, v), S), 70)
    T:check_equal(rima.E(rima.sum({rima.ipairs(y, k, v)}, v), S), 60)
  end
  
  do
    local t, v = rima.R"t, v"
    local S = rima.scope.create{ t={ {b=5}, {b=6}, {b=7} }}
    T:check_equal(rima.sum({rima.ipairs(t, "_", v)}, v.a * v.b), "sum({_, v in ipairs(t)}, v.a*v.b)")
    T:check_equal(rima.E(rima.sum({rima.ipairs(t, "_", v)}, v.a * v.b), S), "5*t[1].a + 6*t[2].a + 7*t[3].a")
  end

  return T:close()
end

-- EOF -------------------------------------------------------------------------

