
-- Manipulation with sets
-- based on implementation of Roberto Ierusalimschy 
local set = {}
set.__index = set

set.type = 'set'
set.NOT_A_SET = "Set is expected!"

-- description
local help = require "help"
set.about = help:new("Manipulation with sets")

-- check type
local function isset(s) return type(s) == 'table' and s.type == set.type end

-- constructor
function set:new(l)
   local o = {}
   for i = 1, #l do o[l[i]] = true end
   setmetatable(o, self)
   return o
end

-- check if value is in set
set.check = function (s, v)
   assert(isset(s), set.NOT_A_SET)
   return s[v] == true
end
set.about[set.check] = {"check(set,val)", "Check if value is in set", help.OTHER}

-- add new element
set.insert = function (s, v)
   assert(isset(s), set.NOT_A_SET)
   s[v] = true
end
set.about[set.insert] = {"insert(set,val)", "Insert element into set", help.OTHER}

-- delete element
set.remove = function (s,v)
   assert(isset(s), set.NOT_A_SET)
   s[v] = nil
end
set.about[set.remove] = {"remove(set,val)", "Remove element from set", help.OTHER}

-- convert into lua table
set.table = function (s)
   local res = {}
   for k in pairs(v) do table.insert(res, k) end
   return res
end
set.about[set.table] = {"table(set)", "Represent set as a table", help.OTHER}

-- union (a+b)
set.__add = function (a,b)
   assert(isset(a) and isset(b), set.NOT_A_SET)
   local res = set:new({})
   for k in pairs(a) do res[k] = true end
   for k in pairs(b) do res[k] = true end
   return res
end

-- intersection (a*b)
set.__mul = function (a,b)
   assert(isset(a) and isset(b), set.NOT_A_SET)
   local res = set:new({})
   for k in pairs(a) do res[k] = b[k] end
   return res
end

-- difference (a/b)
set.__div = function (a,b)
   assert(isset(a) and isset(b), set.NOT_A_SET)
   local res = set:new({})
   for k in pairs(a) do
      if not b[k] then res[k] = true end
   end
   return res
end

set.about["arithmetic"] = {"union, intersection, defference", "a+b, a*b, a/b", help.BASE}

-- is subset or the same (a<=b)
set.__le = function (a,b)
   assert(isset(a) and isset(b), set.NOT_A_SET)
   for k in pairs(a) do
      if not b[k] then return false end
   end
   return true
end

-- is subset (a<b)
set.__lt = function (a,b)
   return a <= b and not (b <= a)
end

-- are the sets equial
set.__eq = function (a,b)
   return a <= b and b <= a
end

set.about["compare"] = {"comparation", "a==b, a~=b, a<b, a<=b, a>b, a>=b", help.BASE}

-- #a - number of elements
set.__len = function (s)
   local n = 0
   for k in pairs(s) do n = n+1 end
   return n
end

-- representation
set.__tostring = function (s)
   local lst = {}
   for e in pairs(s) do table.insert(lst, e) end
   return string.format('{%s}', table.concat(lst,','))
end

-- redefine constructor
setmetatable(set, {__call = function (self, v) return set:new(v) end})
set.about[help.NEW] = {"Set(t)", "Create new set from table of elements", help.NEW}

return set
