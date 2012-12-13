-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

local opmath = require("rima.operators.math")

local lib = require("rima.lib")
local core = require("rima.core")
local index = require("rima.index")


------------------------------------------------------------------------------

return function(T)
  local R = index.R
  local E = core.eval
  local D = lib.dump

  local a, b  = R"a, b"

  T:check_equal(opmath.exp(1), math.exp(1))

  T:check_equal(D(opmath.exp(a)), 'exp(index(address{"a"}))')
  local S = {}
  T:check_equal(E(opmath.exp(a), S), "exp(a)")
  S.a = 4
  T:check_equal(E(opmath.sqrt(a), S), 2)
end


------------------------------------------------------------------------------

