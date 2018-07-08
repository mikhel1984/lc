--[[      liblc/polynom.lua 

--- Manipulations with polynomials.
--  @author <a href="mailto:sonatalc@yandex.ru">Stanislav Mikhel</a>
--  @release This file is a part of <a href="https://github.com/mikhel1984/lc">liblc</a> collection, 2017-2018.

            module 'polynom'
--]]

-------------------- Tests -------------------
--[[!!
Poly = require 'liblc.polynom'

-- coefficients in ascendant order
a = Poly {1,2,4,3}           
b = Poly {1,1}   
-- polynomial value for x=0             
ans = a:val(0)                --> 3

-- simplified call
ans = a(0)                    --> 3

-- arithmetic
ans = a + b                   --> Poly {1,2,5,4}

ans = a - b                   --> Poly {1,2,3,2}

ans = b * b                   --> Poly {1,2,1}

ans = a / b                   --> Poly {1,1,3}

ans = a % b                   --> Poly {0}

ans = b ^ 3                   --> Poly {1,3,3,1}

-- integration
-- free coefficient is 0
ans = b:int()                 --> Poly {0.5,1,0}

-- derivative
-- and its value for x=1
_,ans = a:der(1)              --> 11

-- build polynomial using roots
ans = Poly.coef(1,-1)         --> Poly {1,0,-1}

-- make copy and compare
c = a:copy()
ans = (a == c)                --> true

ans = (b == c)                --> false

-- find real roots
e = a:real()
ans = e[1]                    --~ -1.00

-- fit curve with polynomial
-- of 2 order
A={0,1,2,3}
B={-3,2,11,24}
p = Poly.fit(A,B,2)
ans = p(10)                   --~ 227.0

-- simple print
print(a)

-- human-friendly print
-- with varialbe 's'
d = Poly {2,-2,1}
ans = d:str('s')              --> '2*s^2-2*s+1'
]]

--	LOCAL

local Ver = require "liblc.versions"

-- Check object type.
local function ispolynom(x) return type(x) == 'table' and x.ispolynom end

-- Simplify polynomial, remove zeros from the begin.
--    @param p Table of coefficients.
--    @return Simplified polynomial.
local function reduce (p)
   while #p > 1 and  p[1] == 0 do table.remove(p, 1) end
   return p
end

-- Get sum of the table elements.
--    Use product if need.
--    @param X First table.
--    @param Y Second table (optional).
--    @return Sum of elements.
local function getSum(X,Y)
   local res = 0
   if Y then
      for i = 1, #X do res = res + X[i]*Y[i] end
   else 
      for i = 1, #X do res = res + X[i] end
   end
   return res
end

--	INFO

local help = lc_version and (require "liblc.help") or {new=function () return {} end}

--	MODULE

local polynom = {
-- marker
type = 'polynomial', ispolynom = true,
-- description
about = help:new("Operations with polynomials"),
}
polynom.__index = polynom

-- dependencies
local done, M = pcall(require,'liblc.matrix')
if done then
   polynom.lc_matrix = M 
else
   print('WARNING >> Not available: fit()')
end

--- Correct arguments if need.
--    <i>Private function.</i>
--    @param a First object
--    @param b Second object.
--    @return Two polynomial objects.
polynom._args = function (a,b)
   a = ispolynom(a) and a or polynom.new {a}
   b = ispolynom(b) and b or polynom.new {b}
   return a, b
end

-- Initialize polynomial from table.
--    @param t Table of coefficients.
--    @return Polynomial object.
polynom.init = function (self, t)
   if #t == 0 then t[1] = 0 end
   return setmetatable(t, self)
end

-- Create polynomial from table of coefficients.
--    Arguments are a list of coefficients.
--    @return Polynomial object.
polynom.new = function (p)
   p = p or {}
   local o = {}
   for i = 1,#p do o[i] = p[i] end
   return polynom:init(o)
end

-- Calculate ratio and rest of 2 polynomials.
--    @param a First polynomial.
--    @param b Second polynomial.
--    @return Ratio and the rest.
polynom._div = function (a,b)
   local rest, res = polynom.copy(a), polynom.new() 
   -- update coefficients
   for k = 1,(#a-#b+1) do
      local tmp = rest[1]/b[1]
      res[k] = tmp
      for j = 1,#b do rest[j] = rest[j] - tmp*b[j] end
      -- remove zero element
      table.remove(rest,1)
   end
   return res, rest
end

--- Polynomial value.
--    Can be called with ().
--    @param p Polynomial.
--    @param x Variable.
--    @return Value in the given point.
polynom.val = function (p,x)
   local res = 0
   for i = 1, #p do
      res = res * (i > 1 and x or 1)
      res = res + p[i]
   end
   return res
end
polynom.about[polynom.val] = {"val(p,x)", "Get value of polynomial p in point x."}

-- simplify call
polynom.__call = function (p,x) return polynom.val(p,x) end

--- Create copy of object.
--    @param p Initial polynomial.
--    @return Deep copy.
polynom.copy = function (p)
   return polynom:init(Ver.move(p,1,#p,1,{}))
end
polynom.about[polynom.copy] = {"copy(p)", "Get copy of the polynomial.", help.OTHER}

-- a + b
polynom.__add = function (a,b)
   a, b = polynom._args(a,b)
   local t = {}
   -- get sum of equal powers
   local i,j = #a, #b
   for k = math.max(i,j),1,-1 do
      t[k] = (a[i] or 0) + (b[j] or 0)
      i, j = i-1, j-1
   end
   return polynom:init(t)
end

-- -a
polynom.__unm = function (p)
   local res = {}
   for i = 1, #p do res[i] = -p[i] end
   return polynom:init(res)
end

-- a - b
polynom.__sub = function (a,b)
   return reduce(a + (-b))
end

-- a * b
polynom.__mul = function (a,b)
   a,b = polynom._args(a,b)
   local res = polynom.new()
   -- get sum of coefficients
   for i = 1, #a do
      for j = 1, #b do
         local k = i+j-1
         res[k] = (res[k] or 0) + a[i]*b[j]
      end
   end
   return res
end

-- a / b
polynom.__div = function (a,b)
   local res, _ = polynom._div(polynom._args(a,b))
   return res
end

-- a % b
polynom.__mod = function (a,b)
   local _, res = polynom._div(polynom._args(a,b))
   return res
end

-- a ^ n
polynom.__pow = function (p,n)
   n = assert(Ver.toInteger(n), "Integer power is expected!")
   if n <= 0 then error("Positive power is expected!") end
   local res, acc = polynom:init({1}), polynom.copy(p)
   while n > 0 do
      if n%2 == 1 then res = res*acc end
      if n ~= 1 then acc = acc * acc end
      n = math.modf(n/2)
   end
   return res
end

-- a == b
polynom.__eq = function (a,b)
   if type(a) ~= type(b) or a.type ~= b.type then return false end
   if #a ~= #b then return false end
   for i = 1, #a do
      if a[i] ~= b[i] then return false end
   end
   return true
end

-- a < b
polynom.__lt = function (a,b)
   a,b = polynom._args(a,b)
   return #a < #b or (#a == #b and a[1] < b[1])
end

-- a <= b
polynom.__le = function (a,b)
   return a == b or a < b
end

polynom.arithmetic = 'arithmetic'
polynom.about[polynom.arithmetic] = {polynom.arithmetic, "a+b, a-b, a*b, a/b, a^n, -a", help.META}

polynom.comparison = 'comparison'
polynom.about[polynom.comparison] = {polynom.comparison, "a<b, a<=b, a>b, a>=b, a==b, a~=b", help.META}

--- Get derivative.
--    @param p Initial polynomial.
--    @param x Variable (can be omitted).
--    @return Derivative or its value.
polynom.der = function (p,x)
   if not ispolynom(p) then error("Polynomial is expected!") end
   local der, pow = {}, #p
   for i = 1, #p-1 do
      table.insert(der, p[i]*(pow-i))
   end
   der = polynom:init(der)
   if x then x = polynom.val(der,x) end
   return der, x
end
polynom.about[polynom.der] = {"der(p[,x])", "Calculate derivative of polynomial, and its value, if need.", }

--- Get integral.
--    @param p Initial polynomial.
--    @param x Free coefficient.
--    @return Integral.
polynom.int = function (p,x)
   if not ispolynom(p) then error("Polynomial is expected!") end
   x = x or 0
   local int, pow = {}, #p+1
   for i = 1, #p do
      table.insert(int, p[i]/(pow-i))
   end
   table.insert(int, x)
   return polynom:init(int)
end
polynom.about[polynom.int] = {"int(p[,x0])", "Calculate integral, x0 - free coefficient.", }

--- Get polynomial from roots.
--    Arguments are a sequence of roots.
--    @return Polynomial object.
polynom.coef = function (...)
   local args = {...}
   local res = polynom:init({1})
   for i = 1, #args do
      res = polynom.__mul(res, polynom:init({1,-args[i]}))
   end
   return res
end
polynom.about[polynom.coef] = {"coef(...)", "Return polynomial with given roots.", help.OTHER}

-- String representation.
polynom.__tostring = function (p)
   return table.concat(p,' ')
end

--- Represent polynomial in natural form.
--    @param p Source polynomial.
--    @param l String variable (default is <code>x</code>).
--    @return String with traditional form of equation.
polynom.str = function (p,l)
   l = l or 'x'
   local res,pow,mult = {}, #p-1
   res[1] = string.format('%s%s%s', tostring(p[1]), (pow > 0 and '*'..l or ''), (pow > 1 and '^'..pow or ''))
   for i = 2,#p do
      pow = #p-i
      res[i] = string.format('%s%s%s', (p[i] > 0 and '+'..p[i] or tostring(p[i])), (pow > 0 and '*'..l or ''), (pow > 1 and '^'..pow or ''))
   end
   return table.concat(res)
end

-- Find closest root using Newton-Rapson technique
--    @param p Source polynomial.
--    @param x Initial value of the root (optional).
--    @param epx Tolerance
--    @return Found value and flag about its correctness.
polynom.NewtonRapson = function (p,x,eps)
   eps = eps or 1e-6
   x = x or math.random()
   -- prepare variables
   local dp,n,max = p:der(), 0, 30
   while true do
      -- polynomial value
      local dx = p(x) / dp(x) 
      if math.abs(dx) <= eps or n > max then break
      else
         -- update root value and number of iterations
         x = x - dx
	 n = n+1
      end
   end
   return x, (n < max)
end

--- Find real roots of the polynomial.
--    @param p Source polynomial.
--    @return Table with real roots.
polynom.real = function (p)
   local pp, res = p:copy(), {}
   -- zeros
   while pp[#pp] == 0 do
      pp[#pp] = nil
      res[#res+1] = 0
   end
   -- if could have roots
   while #pp > 1 do
      local x, root = polynom.NewtonRapson(pp)
      if root then 
         -- save and remove the root
         res[#res+1] = x
	 -- divide by (1-x)
	 for i = 2,#pp-1 do pp[i] = pp[i] + x*pp[i-1] end
	 pp[#pp] = nil
      else break
      end
   end
   return res
end
polynom.about[polynom.real] = {"real(p)", "Find real roots of the polynomial.", help.OTHER}


--- Find the best polynomial approximation for the line.
--    @param X Set of independent variables.
--    @param Y Set of dependent variables.
--    @param ord Polynomial order.
--    @return Polynomial object.
polynom.fit = function (X,Y,ord)
   if not (ord > 0 and Ver.mathType(ord) == 'integer') then error('Wrong order!') end
   if #X ~= #Y then error('Wrong data size!') end
   if #X <= ord then error('Too few data points!') end
   -- find sums
   local acc = Ver.move(X,1,#X,1,{})       -- accumulate powers
   local sX, sY = {}, {}                     -- accumulate sums
   local nY = ord
   sY[nY+1] = getSum(Y) 
   for nX = 2*ord,1,-1 do
      sX[nX] = getSum(acc)
      if nY > 0 then sY[nY] = getSum(acc, Y); nY = nY-1 end
      if nX > 1 then
         for i = 1,#acc do acc[i] = acc[i]*X[i] end
      end -- if
   end -- for
   sX[#sX+1] = #X
   -- prepare matrix
   local m = {}
   for k = 1,ord+1 do
      m[k] = {}
      for j = 1, ord+1 do m[k][j] = sX[k+j-1] end
   end
   -- solve
   local mat = polynom.lc_matrix
   local gaus = mat.rref(mat(m),mat.V(sY))
   local res = {}
   for i = 1,ord+1 do res[i] = gaus:get(i,-1) end
   return polynom:init(res)
end
polynom.about[polynom.fit] = {"fit(X,Y,ord)", "Find polynomial approximation for the line.", help.OTHER}

setmetatable(polynom, {__call = function (self, ...) return polynom.new(...) end})
polynom.Poly = 'Poly'
polynom.about[polynom.Poly] = {"Poly(...)", "Create a polynomial.", help.NEW}

--- Polynomial serialization.
--    @param obj Polynomial object.
--    @return String, suitable for exchange.
polynom.serialize = function (obj)
   local s = {}
   for i = 1, #obj do s[#s+1] = string.format("%a", obj[i]) end
   s[#s+1] = "metatablename='Poly'"
   s[#s+1] = "modulename='polynom'"
   return string.format("{%s}", table.concat(s, ','))
end
polynom.about[polynom.serialize] = {"serialize(obj)", "Save polynomial internal representation.", help.OTHER}

-- free memory if need
if not lc_version then polynom.about = nil end

return polynom

--===========================
--TODO: polyroot

