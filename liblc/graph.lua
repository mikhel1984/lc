--[[       liblc/graph.lua

--- Operations with graphs.
--  @author My Name

           module 'graph'
--]]

--------------- Tests ------------
-- Define here your tests, save results to 'ans', use --> for equality and --~ for estimation.
--[[!!
Graph = require 'liblc.graph'

-- example
a = Graph()
ans = a.type                   --> 'graph'
]]

---------------------------------
-- @class table
-- @name graph
-- @field about Description of functions.
local graph = {type='graph', isgraph=true}
graph.__index = graph

-- marker
local function isgraph(t) return type(t)=='table' and t.isgraph end

-- description
local help = lc_version and (require "liblc.help") or {new=function () return {} end}
graph.about = help:new("Operations with graphs.")

local function isedge(m) return type(m) == 'table' end

--- Constructor example
--    @param t Some value.
--    @return New object of graph.
function graph:new(t)
   local o = {}
   -- add nodes
   for _,elt in ipairs(t) do graph.add(o,elt) end
   setmetatable(o,self)
   return o
end

graph.add = function (g, t)
   if isedge(t) then
      local t1,t2,w12,w21 = t[1],t[2],t[3] or t.w12,t[4] or t.w21
      g[t1] = g[t1] or {}
      g[t2] = g[t2] or {}
      if not (t3 or t4) then
         local w = t.w or 1
	 g[t1][t2] = w; g[t2][t1] = w
      else
         g[t1][t2] = w12; g[t2][t1] = w21
      end
   else
      g[t] = g[t] or {}
   end
end

graph.remove = function (g, t)
   if isedge(t) then
      local t1,t2 = t[1],t[2]
      g[t1][t2] = nil
      if not t.single then        -- change keyword ???
         g[t2][t1] = nil
      end
   else
      for _,v in pairs(g) do v[t] = nil end
      g[t] = nil
   end
end

-- simplify constructor call
setmetatable(graph, {__call = function (self,v) return graph:new(v) end})
graph.Graph = 'Graph'
graph.about[graph.Graph] = {"Graph(t)", "Create new graph.", help.NEW}

graph.nodes = function (g)
   local res = {}
   for k in pairs(g) do res[#res+1] = k end
   return res
end

graph.edges = function (g)
   local nodes = graph.nodes(g)
   local res = {}
   for i = 1,#nodes do
      local ni = nodes[i]
      for j = i,#nodes do
         local nj = nodes[j]
         local w = g[ni][nj]
	 if w then 
	    res[#res+1] = {ni,nj} 
	    if g[nj][ni] ~= w then res[#res+1] = {nj,ni} end
	 end
      end
   end
   return res
end

graph.copy = function (g)
   local res = graph:new({})
   for k,v in pairs(g) do
      res[k] = {}
      for n,w in pairs(v) do res[k][n] = w end
   end
   return res
end

graph.__len = function (g)
   local n = 0
   for i in pairs(g) do n = n+1 end
   return n
end

graph.__tostring = function (g)
   local nd = graph.nodes(g)
   local res
   if #nd <= 5 then 
      res = string.format('Graph {%s}', table.concat(nd,','))
   else
      res = string.format('Graph {%s -%d- %s}', 
                          tostring(nd[1]), #nd-2, tostring(nd[#nd]))
   end
   return res
end

-- free memory in case of standalone usage
if not lc_version then graph.about = nil end

return graph

-- TODO: multible edges for the same verteces

--[[
a = graph {{'a','b'},{'a','c',w=2},{'c','b',3,4}}
print(a)
b = a:copy()
print(b)
a:add('pp')
a:add({'t','u'})

a:remove({'t','u'})
a:remove('a')

n = a:edges()
for _,v in ipairs(n) do print(v[1],v[2]) end

print(a)
]]
