-- Copyright (c) 2009-2011 Incremental IP Limited
-- see LICENSE for license information

local table = require("table")
local getmetatable, ipairs, pairs, require, type =
      getmetatable, ipairs, pairs, require, type

local lib = require("rima.lib")
local core = require("rima.core")
local proxy = require("rima.lib.proxy")

module(...)

local expression = require("rima.expression")


-- Evaluate all terms, and return the same object if nothing changed -----------

function evaluate_terms(terms, S)
  local new_terms
  for i, t in ipairs(terms) do
    local et2 = core.eval(t[2], S)
    if et2 ~= t[2] then
      new_terms = new_terms or {}
      new_terms[i] = { t[1], et2 }
    end
  end
  if new_terms then
    for i, t in ipairs(terms) do
      if not new_terms[i] then
        new_terms[i] = t
      end
    end
  end

  return new_terms or terms, new_terms and true or false
end


-- Add a term to the term_map --------------------------------------------------

local SCOPE_FORMAT = { scopes = true }

function add_term(term_map, coeff, e, id, sort)
  local id = id or lib.repr(e, SCOPE_FORMAT)
  local t = term_map[id]
  if coeff == 0 then
    return true                                 -- Do nothing, but either way we removed a term
  end
  if t then
    t[1] = t[1] + coeff
    return true
  else
    term_map[id] = { coeff, e, id=id, sort=sort or lib.repr(e) }
  end
end


-- Sort terms ------------------------------------------------------------------

function sort_terms(term_map)
  -- sort the new terms alphabetically, so that when we group by a string
  -- representation, like terms look alike
  local terms = {}
  local term_count = 0
  for name, t in pairs(term_map) do
    if t[1] ~= 0 then
      term_count = term_count + 1
      local e = t[2]
      if e == " " then
        terms[term_count] = { 1, t[1], id=" ", sort=" " }
      else
        terms[term_count] = t
      end
    end
  end
  table.sort(terms, function(a, b) return a.sort < b.sort end)
  return terms, term_count
end


-- Extract the constant from an add or mul (if there is one) -------------------

function extract_constant(e)
  local terms = proxy.O(e)
  local constant = terms[1][2]

  if type(constant) == "number" then
    local term_count = #terms

    if term_count == 1 then
      return constant                           -- There was just a constant
    end

    if term_count == 2 and terms[2][1] == 1 then
      -- there's a constant and only one other argument with a
      -- coefficient/exponent of 1 - hoist the other argument
      return constant, terms[2][2]
    end
            
    local new_terms = {}
    for i = 2, term_count do
      new_terms[i-1] = terms[i]
    end
    return constant, expression:new_table(getmetatable(e), new_terms)
  end
end


-- EOF -------------------------------------------------------------------------
