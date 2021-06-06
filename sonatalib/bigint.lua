--[[		sonatalib/bigint.lua 

--- Operations with arbitrary long integer numbers.
--
--  Object structure: </br> 
--  <code> {sign=S,_base_=B, v1, ... vn} </code></br>
--  where <code>S</code> is +1/-1, B is 10 by default, v1 - vn are digits of the number in reverse order. For example, number <code>123</code> is represented as <code>{sign=1, _base_=10, 3, 2, 1}</code>.
--  
--  @author <a href="mailto:sonatalc@yandex.ru">Stanislav Mikhel</a>
--  @release This file is a part of <a href="https://github.com/mikhel1984/sonata">sonatalib</a> collection, 2021.

	module 'bigint'
--]]

---------------- Tests -----------------
--[[TEST
-- use 'bigint'
Int = require 'sonatalib.bigint'

-- from integer
a = Int(123)
ans = a:val()                 --> 123

-- from string
b = Int('456')
ans = b:val()                 --> 456

-- from table 
-- 'sign' and 'base' can be skipped
g = Int {1,2,3,sign=-1,base=10}
ans = g:val()                 --> -123

-- check equality
ans = (a == -g)               --> true

-- arithmetical operations
ans = Int.val(a+b)            --> 579

ans = Int.val(a-b)            --> -333

ans = Int.val(a*Int(2))       --> 246

ans = Int.val(b/2)            --> 228

ans = Int.val(b%a)            --> 87

ans = Int.val(a^3)            --> 1860867

-- absolute value
ans = Int.abs('-25'):val()    --> 25

-- factorial
c = Int(10):fact()
ans = Int.val(c)              --> 3628800

-- make copy, comparison
d = a:copy()
ans = (a == d)                --> true

ans = (a > b)                 --> false

ans = (a == b)                --> false

-- compare with number
ans = a:eq(123)               --> true

-- number of digits
ans = #a                      --> 3

-- 2nd digit (from the lowest)
ans = a[2]                    --> 2

-- get numeric base 
ans = g:base()                --> 10

-- change numeric base
v = g:rebase(60)
ans = tostring(v)             --> '-2|3'

-- still the same value
ans = (v == g)                --> true

-- operations with different bases
-- transform to the biggest common base
w = v + b
ans = tostring(w)             --> '5|33'

-- simple print
print(a)

--]]

--	LOCAL

local Ver = require "sonatalib.versions"

local ZERO = string.byte('0')

--- Check object type.
--  @param v Object.
--  @return True if the object is a big integer.
local function isbigint(v) return type(v) == 'table' and v.isbigint end

--	INFO 

local help = LC_DIALOG and (require "sonatalib.help") or {new=function () return {} end}

--	MODULE

local bigint = {
-- mark
type='bigint', isbigint=true,
-- description
about = help:new("Operations with arbitrary long integers."),
}

bigint.__index = bigint

--- Create new object, set metatable.
--  @param num Integer, string or table.
--  @return Bigint object.
bigint.new = function (self, num)
  local acc = {_base_=10, sign=1}
  -- prepare
  if type(num) == 'table' then
    acc._base_ = num.base or 10
    acc.sign   = num.sign or 1
    for i = #num,1,-1 do
      acc[#acc+1] = num[i] -- reverse
    end
  elseif type(num) == 'string' then
    local sign, s = string.match(num, '^([+-]?)(%d+)$')
    if sign == '-' then acc.sign = -1 end
    s = string.reverse(s)
    for i = 1,#s do
      acc[i] = string.byte(s,i)-ZERO
    end
  elseif type(num) == 'number' and Ver.isInteger(num) then
    if num < 0 then
      acc.sign = -1
      num = -num
    end
    repeat
      local n,_ = math.modf(num / 10)
      acc[#acc+1] = num - 10*n
      num = n
    until num == 0  
  end
  -- check result
  if #acc == 0 then
    error('Wrong number '..tostring(num))
  end
  return setmetatable(acc, self)
end

--- Correct function arguments if need.
--  @param num1 First number representation.
--  @param num2 Second number representation (optional).
--  @return Bigint objects with the same numeric bases.
bigint._args_ = function (num1, num2)
  num1 = isbigint(num1) and num1 or bigint:new(num1)
  num2 = isbigint(num2) and num2 or bigint:new(num2)
  if num1._base_ > num2._base_ then
    num2 = num2:rebase(num1._base_)
  elseif num1._base_ < num2._base_ then
    num1 = num1:rebase(num2._base_)
  end
  return num1, num2
end

--- Main algorithm for division.
--  @param num1 First number representation.
--  @param num2 Second number representation.
--  @return The quotient and remainder.
bigint._div_ = function (B1,B2)
  if #B2 == 1 and B2[1] == 0 then error("Divide by 0!") end
  local d = B1._base_
  local res = bigint:new({0,base=d})
  if #B1 < #B2 then  -- too short
    return res, B1:copy()
  end
  local rem = bigint:new({0,base=d}); rem[1] = nil
  local k = #B1-#B2+1
  Ver.move(B1,k+1,#B1,1,rem)  -- copy last elements
  local v2, den, acc = B2:val(), B2:abs(), {}
  for i = k,1,-1 do
    table.insert(rem,1,B1[i])
    if rem >= den then
      local n = math.modf(rem:val() / v2)  -- estimate
      local tmp = rem - den*bigint:new({n,base=d})
      if tmp.sign < 0 then
        n = n - 1
        tmp = tmp + den
      elseif tmp > den then
        n = n + 1
        tmp = tmp - den
      end
      rem = tmp
      acc[#acc+1] = n
    elseif #acc > 0 then
      acc[#acc+1] = 0
    end
  end
  for i,v in ipairs(acc) do res[#acc-i+1] = v end
  res.sign = B1.sign*B2.sign
  return res, rem
end

--- Get sum of the two positive big numbers.
--  @param B1 First bigint object.
--  @param B2 Second bigint object.
--  @return Sum of the values.
bigint._sum_ = function (B1,B2)
  local n, add = B1._base_, 0
  local res = bigint:new({0,base=n})
  for i = 1, math.max(#B1,#B2) do
    local v = (B1[i] or 0) + (B2[i] or 0) + add
    if v >= n then
      res[i] = v - n
      add = 1
    else
      res[i] = v
      add = 0
    end
  end
  if add == 1 then res[#res+1] = 1 end
  return res
end

--- Get subtraction for two positive bigint numbers.
--  @param B1 First bigint object.
--  @param B2 Second bigint object.
--  @return Difference of the values.
bigint._sub_ = function (B1,B2)
  local r, n, sub = 1, B1._base_, 0
  local res = bigint:new({0,base=n})
  -- find the bigger number
  if #B1 < #B2 then
    r = -1
  elseif #B1 == #B2 then
    local i = #B1
    -- find first difference
    while i > 0 and B1[i] == B2[i] do i = i - 1 end
    if i == 0 then return res end
    if i > 0 and B1[i] < B2[i] then r = -1 end
  end
  if r == -1 then
    B1, B2 = B2, B1
  end
  -- subtraction
  for i = 1, math.max(#B1,#B2) do
    local v = B1[i] - (B2[i] or 0) - sub
    if v < 0 then
      res[i] = v + n
      sub = 1
    elseif v > 0 or (v == 0 and B1[i+1]) then
      res[i] = v
      sub = 0
    end
  end
  res.sign = r
  return res
end

--- Absolute value of number.
--  @param v Bigint or integer number.
--  @return Absolute value.
bigint.abs = function (val)
  local a = isbigint(val) and bigint.copy(val) or bigint:new(val)
  a.sign = 1 
  return a
end
bigint.about[bigint.abs] = {"abs(v)", "Return module of arbitrary long number."}

--- Copy of the object.
--  @param v Original bigint object.
--  @return Deep copy.
bigint.copy = function (B)
  local c = bigint:new({B[1], sign=B.sign, base=B._base_})
  for i = 2,#B do c[i] = B[i] end
  return c
end
bigint.about[bigint.copy] = {"copy(v)", "Return copy of given number.", help.OTHER}

--- B1 + B2
--  @param B1 First bigint or integer.
--  @param B2 Second bigint or integer.
--  @return Sum object.
bigint.__add = function (B1,B2)
  B1,B2 = bigint._args_(B1,B2) 
  if B1.sign > 0 then
    return (B2.sign > 0) and bigint._sum_(B1,B2) or bigint._sub_(B1,B2)
  else 
    return (B2.sign > 0) and bigint._sub_(B2,B1) or -bigint._sum_(B1,B2)
  end
end

--- - B
--  @param B Bigint object.
--  @return Opposite value.
bigint.__unm = function (B)
  local res = B:copy()
  res.sign = -res.sign
  return res
end

--- B1 - B2
--  @param B1 First bigint or integer.
--  @param B2 Second bigint or integer.
--  @return Difference object.
bigint.__sub = function (B1, B2)
  B1,B2 = bigint._args_(B1,B2)
  if B1.sign > 0 then
    return (B2.sign > 0) and bigint._sub_(B1,B2) or bigint._sum_(B1,B2)
  else
    return (B2.sign > 0) and -bigint._sum_(B1,B2) or bigint._sub_(B2,B1)
  end
end

--- Straightforward product algorithm.
--  @param B1 First bigint multiplier.
--  @param B2 Second bigint multiplier.
--  @return Product without sign. 
bigint._mul_ = function (B1,B2)
  local sum = bigint:new({0, base=B1._base_})
  -- get products
  for i = 0,#B1-1 do
    local v = B1[i+1]
    for j = 1,#B2 do
      local pos = i+j
      sum[pos] = (sum[pos] or 0) + v * B2[j]
    end
  end
  -- rearrange
  local rest, d = 0, B1._base_
  for i = 1,#sum do
    sum[i] = sum[i] + rest
    rest = math.modf(sum[i] / d)
    sum[i] = sum[i] - rest * d
  end
  if rest > 0 then sum[#sum+1] = rest end
  return sum
end

--- B1 * B2
--  @param B1 First bigint or integer.
--  @param B2 Second bigint or integer.
--  @return Product object.
bigint.__mul = function (B1, B2)
  B1,B2 = bigint._args_(B1,B2)
  local res = bigint._mul_(B1,B2)
  res.sign = B1.sign * B2.sign
  return res
end

--- B1 / B1
--  @param B1 First bigint or integer.
--  @param B2 Second bigint or integer.
--  @return Ratio object.
bigint.__div = function (B1, B2)
  B1, B2 = bigint._args_(B1,B2)
  local res,_ = bigint._div_(B1,B2)
  return res
end

--- B1 % B2
--  @param B1 First bigint or integer.
--  @param B2 Second bigint or integer.
--  @return Remainder object.
bigint.__mod = function (B1, B2)
  B1, B2 = bigint._args_(B1,B2)
  local _,res = bigint._div_(B1,B2)
  return res
end

--- a == b.
--  In Lua v == 0 is always <code>false</code> because in the case of number
--  the program tries to convert everything into number.
--  For two bigint objects using of <code>==</code> is also possible.
--  @param B1 First bigint object or integer.
--  @param B2 Second bigint object or integer.
--  @return <code>true</code> if numbers have the same values and signs.
bigint.eq = function (B1,B2)
  B1,B2 = bigint._args_(B1,B2)
  if #B1 == #B2 and B1.sign == B2.sign then
    for i = 1,#B1 do
      if B1[i] ~= B2[i] then return false end
    end
    return true
  end
  return false
end
bigint.about[bigint.eq] = {"eq(a,b)", "Check equality of two values.", help.OTHER}
-- redefine equality
bigint.__eq = bigint.eq

--- B1 < B2
--  @param B1 First bigint or integer.
--  @param B2 Second bigint or integer.
--  @return True if the first value is less then the second one.
bigint.__lt = function (B1,B2)
  B1,B2 = bigint._args_(B1,B2)
  if B1.sign < B2.sign then return true end
  if #B1 == #B2 then   -- equal length
    for i = #B1,1,-1 do
      if B1[i] ~= B2[i] then
        return (B1.sign > 0 and B1[i] < B2[i]) or (B1.sign < 0 and B1[i] > B2[i])
      end
    end
    return false
  else                 -- different length
    return (B1.sign > 0 and #B1 < #B2) or (B1.sign < 0 and #B1 > #B2)
  end
end

--- Check if the first number is greater then the second
--  @param B1 First number.
--  @param B2 Second number.
--  @return True if B1 > B2.
bigint._gt_ = function (B1,B2)
  if B1.sign > B2.sign then return true end
  if #B1 == #B2 then
    for i = #B1,1,-1 do
      if B1[i] ~= B2[i] then
        return (B1.sign > 0 and B1[i] > B2[i]) or (B1.sign < 0 and B1[i] < B2[i])
      end
    end
    return false
  else
    return (B1.sign > 0 and #B1 > #B2) or (B1.sign < 0 and #B1 < #B2)
  end
end

--- a <= b
--  @param B1 First bigint or integer.
--  @param B2 Second bigint or integer.
--  @return True if the first value is less or equal to the second.
bigint.__le = function (B1,B2)
  B1,B2 = bigint._args_(B1,B2)
  return not bigint._gt_(B1,B2)
end

--- B1 ^ B2
--  @param B1 First bigint or integer.
--  @param B2 Second bigint or integer.
--  @return Power of the number.
bigint.__pow = function (B1,B2)
  B1,B2 = bigint._args_(B1,B2)
  if B2.sign < 0 then error('Negative power!') end
  local y, x = bigint:new({1,base=B1._base_}), B1
  if #B2 == 1 and B2[1] == 0 then
    assert(#B1 > 1 or B1[1] ~= 0, "Error: 0^0!")
    return res
  end
  local dig, mul, rest = {}, bigint._mul_
  for i = 1,#B2 do dig[i] = B2[i] end
  while #dig > 1 or #dig == 1 and dig[1] > 1 do
    dig, rest = bigint._divBase_(dig, B1._base_, 2)
    if rest == 1 then
      y = mul(y, x)
    end
    x = mul(x, x)
  end
  return mul(x, y)
end

bigint.arithmetic = 'arithmetic'
bigint.about[bigint.arithmetic] = {bigint.arithmetic, "a+b, a-b, a*b, a/b, a%b, a^b, -a, #a", help.META}
bigint.comparison = 'comparison'
bigint.about[bigint.comparison] = {bigint.comparison, "a<b, a<=b, a>b, a>=b, a==b, a~=b", help.META}

--- String representation.
--  @param B Bigint object.
--  @return String object.
bigint.__tostring = function (B)
  local s
  if B._base_ > 10 then
    s = {}
    local n = #B+1
    for i = 1,#B do s[i] = B[n-i] end
    s = table.concat(s, '|')
  else
    s = string.reverse(table.concat(B, (B._base_ == 10) and '' or '|'))
  end
  return B.sign < 0 and ('-' .. s) or s
end

--- Float number representation.
--  @param v Bigint object.
--  @return Integer if possible, otherwise float point number.
bigint.val = function (B)
  local d, v, sum = B._base_, 1, 0
  for i = 1,#B do
    sum = sum + B[i]*v
    v = v * d
  end
  return B.sign >= 0 and sum or (-sum)
end
bigint.about[bigint.val] = {"val(N)", "Represent current big integer as number if it possible.", help.OTHER}

--- B!
--  @param B Bigint object or integer.
--  @return Factorial of the number as bigint object.
bigint.fact = function (B)
  local n = isbigint(B) and B:copy() or bigint:new(B)
  assert(n.sign > 0, "Non-negative value is expected!")
  local res, one = bigint:new({1,base=B._base_}), bigint:new({1,base=B._base_})
  if #n == 1 and n[1] == 0 then return res end  -- 0! == 1
  local mul, sub = bigint._mul_, bigint._sub_
  repeat 
    res = mul(res, n)
    n = sub(n, one)
  until #n == 1 and n[1] == 0
  return res
end
bigint.about[bigint.fact] = {"fact(B)", "Return factorial of non-negative integer n."}

--- Divide elements in the list ot given number, find reminder
--  @param t List of numbers.
--  @param bOld Initial bases.
--  @param bNew New bases.
--  @return Quotient and reminder.
bigint._divBase_ = function (t, bOld, bNew)
  local rest, set = 0, false
  for i = #t,1,-1 do
    rest = rest * bOld + t[i]
    local n,_ = math.modf(rest / bNew)
    if set or n > 0 then
      t[i] = n
      set = true
    else 
      t[i] = nil
    end
    rest = rest - bNew * n
  end
  return t, rest
end

--- Change current numeric base.
--  @param B Bigint object.
--  @param base New base. 
--  @return Copy with new base.
bigint.rebase = function (B,base)
  if base <= 0 then error("Wrong base "..tostring(base)) end
  if B._base_ == base then return B:copy() end
  local res = bigint:new({0,sign=B.sign, base=base})
  res[1] = nil    -- remove zero
  -- reverse order
  local dig, n = {}, #B+1
  for i,v in ipairs(B) do dig[i] = v end
  repeat 
    dig, n = bigint._divBase_(dig, B._base_, base)
    res[#res+1] = n
  until #dig == 0
  return res
end
bigint.about[bigint.rebase] = {"rebase(B,base)","Convert number to the new numeric base."}

--- Get numeric base.
--  @param B Bigint object.
--  @return Base value.
bigint.base = function (B) return B._base_ end
bigint.about[bigint.base] = {"base(B)", "Current numeric base."}

-- simplify constructor call
setmetatable(bigint, {__call = function (self, v) return bigint:new(v) end})
bigint.Int = 'Int'
bigint.about[bigint.Int] = {"Int(v)", "Create number from integer, string or table.", help.NEW}

-- free memory if need
if not LC_DIALOG then bigint.about = nil end

return bigint

--=================================
--TODO: factorization
--TODO: check for prime
--TODO: rename module, change description for val
