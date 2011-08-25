-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local math = require("math")
local error, getmetatable, ipairs, require, type =
      error, getmetatable, ipairs, require, type

local object = require("rima.lib.object")
local proxy = require("rima.lib.proxy")
local lib = require("rima.lib")
local core = require("rima.core")
local add_mul = require("rima.operators.add_mul")
local element = require("rima.sets.element")

module(...)

local expression = require("rima.expression")
local mul = require("rima.operators.mul")

-- Addition --------------------------------------------------------------------

local add = object:new_class(_M, "add")
add.precedence = 5


-- String Representation -------------------------------------------------------

function add:__repr(format)
  local terms = proxy.O(self)
  if format.format == "dump" then
    return "+("..
      lib.concat(terms, ", ",
        function(t) return lib.simple_repr(t[1], format).."*"..lib.repr(t[2], format) end)..
      ")"
  end

  local s = ""
  for i, t in ipairs(terms) do
    local c, e = t[1], t[2]
    
    -- If it's the first argument and it's negative, put a "-" out front
    if i == 1 then
      if c < 0 then
        s = "-"
      end
    else
      s = s..((c < 0 and " - ") or " + ")
    end

    -- If the coefficient's not 1, make a sub-expression with a multiplication
    local ac = math.abs(c)
    e = ac == 1 and e or mul.simplify({{1, ac}, {1, e}})

    -- If the constant's not 1 then we need to parenthise (almost) like a multiplication
    s = s..core.parenthise(e, format, (c == 1 and 5) or 4)
  end
  return s
end


-- Evaluation ------------------------------------------------------------------

function add:__eval(S)
  -- Sum all the arguments, keeping track of the sum of any constants,
  -- and of all remaining unresolved terms.
  -- If any subexpressions are sums, we dive into them, and if any are
  -- products, we try to hoist out the constant and see if what's left is a
  -- sum.
  local terms = add_mul.evaluate_terms(proxy.O(self), S)

  local constant, term_map = 0, {}

  -- Run through all the terms in a sum
  local function sum(term_map, coeff, terms)
    coeff = coeff or 1
    for _, t in ipairs(terms) do

      -- Simplify a single term
      local function simplify(term_map, coeff, e)
        local ti = object.typeinfo(e)
        if core.arithmetic(e) then              -- if the term evaluated to a number, then add it to the constant
          constant = constant + coeff * e
        elseif ti.add then                      -- if the term is another sum, hoist its terms
          sum(term_map, coeff, proxy.O(e))
        elseif ti.mul then                      -- if the term is a multiplication, try to hoist any constant
          local new_c, new_e = extract_constant(e, getmetatable(e))
          if new_c then                         -- if we did hoist a constant, re-simplify the resulting expression
            simplify(term_map, coeff * new_c, new_e)
          else                                  -- otherwise just add it
            add_mul.add_term(term_map, coeff, element.extract(e))
          end
        else                                    -- if there's nothing else to do, add the term
          add_mul.add_term(term_map, coeff, element.extract(e))
        end
      end
      simplify(term_map, coeff * t[1], t[2])

    end
  end
  sum(term_map, 1, terms)

  ordered_terms, term_count = add_mul.sort_terms(term_map)

  if not ordered_terms[1] then                  -- if there's no terms, we're just a constant
    return constant
  elseif constant == 0 and                      -- if there's no constant, and one term without a coefficent,
         term_count == 1 and                    -- we're the identity, so return the term
         ordered_terms[1].coeff == 1 then
    return ordered_terms[1].expression
  else                                          -- return the constant and the terms
    local new_terms = {}
    if constant ~= 0 then new_terms[1] = {1, constant} end
    for i, t in ipairs(ordered_terms) do
      new_terms[#new_terms+1] = { t.coeff, t.expression }
    end
    return expression:new_table(add, new_terms)
  end
end


-- Extract the constant from an add or mul (if there is one)
function extract_constant(e, mt)
  e = proxy.O(e)
  mt = mt or add
  if type(e[1][2]) == "number" then
    local constant = e[1][2]
    local new_terms = {}
    for i = 2, #e do
      new_terms[i-1] = e[i]
    end
    if #new_terms == 1 and new_terms[1][1] == 1 then
      -- there's a constant and only one other argument with a coefficient/exponent of 1 - hoist the other argument
      return constant, new_terms[1][2]
    else
      return constant, expression:new_table(mt, new_terms)
    end
  else                                          -- there's no constant to extract
    return nil
  end
end


-- Automatic differentiation ---------------------------------------------------

function add:__diff(v)
  local diff_terms = {}
  for _, t in ipairs(proxy.O(self)) do
    local c, e = t[1], t[2]
    local dedv = core.diff(e, v)
    if dedv ~= 0 then
      diff_terms[#diff_terms+1] = {c, dedv}
    end
  end
  
  return expression:new_table(add, diff_terms)
end


-- Introspection? --------------------------------------------------------------

function add:__list_variables(S, list)
  for _, t in ipairs(proxy.O(self)) do
    core.list_variables(t[2], S, list)
  end
end


-- EOF -------------------------------------------------------------------------

