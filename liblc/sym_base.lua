
-- basic transformatins
local OPERATION, VARIABLE, NUMBER, FUNCTION = 1, 2, 3, 4

local sym_base = {}
local rules = {}

sym_base._num_calc = {0,0,0,0}

sym_base._num_calc[VARIABLE] = function (s) return s end

sym_base._num_calc[NUMBER] = function (s) return s end

sym_base._num_calc[FUNCTION] = function (s)
   for i = 1,#s.args do 
      local tmp = s.args[i]
      --s.args[i] = s.args[i]:collectNum() 
      s.args[i] = sym_base._num_calc[tmp.cls](tmp)
   end
end

sym_base._num_calc[OPERATION] = function (s)
   --print(s, s.op)
   local L, R = s.left, s.right
   s.left = sym_base._num_calc[L.cls](L)
   s.right = sym_base._num_calc[R.cls](R)
   local op, root = s.op, sym_base.root
   -- order elements
   if s.right.value then 
      if s.left.value then
      -- evaluate
         return root._num(root[op](s.left.value, s.right.value))  
      elseif op == '*' or op == '+' then  -- root[op].commutative - ?
      -- swap, number should be in the left
         s.left, s.right = s.right, s.left   
      elseif op == '-' then
         s.right.value = -s.right.value
	 s = root._op('+', s.right, s.left)
      elseif op == '/' then
         s.right.value = 1/s.right.value
	 s = root._op('*', s.right, s.left)
      end 
      op = s.op
   end
   -- apply rules
   L, R = s.left, s.right
   local lvl = root[op].level
   if R.op and lvl == root[R.op].level and R.left.value then
      if L.value then
         s = rules.num[(lvl==root['+'].level) and '+' or '*'][op][R.op](L, root.NULL, R.left, R.right)
	 sym_base._remove_null(s)
      elseif lvl == root[L.op].level and L.left.value then
         s = rules.num[L.op][op][R.op](L.left, L.right, R.left, R.right)
      end
   elseif L.op and lvl == root[L.op].level and L.left.value then
      s = rules.num[L.op][op][(lvl==root['+'].level) and '+' or '*'](L.left, L.right, (lvl==root['+'].level) and root.ZERO or root.ONE, R)
   end
   return s
end

sym_base._remove_null = function (s)
   local t, root = s.right, sym_base.root
   if rawequal(t.right,root.NULL) then
      s.right = t.left
   elseif rawequal(t.left,root.NULL) then
      s.right = t.right
      if s.op == '+' or s.op == '*' then
	 s.op = t.op
      else
         if     t.op == '-' then s.op = '+'
	 elseif t.op == '/' then s.op = '*'
	 end
      end
   end
   --return s
end

sym_base.simplify = function (s)
   return sym_base._num_calc[s.cls](s)
end

rules.num = {
['+'] = {
  ['+'] = {
    ['+'] = function (n1,s1,n2,s2) return sym_base.root._op('+', sym_base.root._num(n1.value+n2.value), sym_base.root._op('+',s1,s2)) end,
    ['-'] = function (n1,s1,n2,s2) return sym_base.root._op('+', sym_base.root._num(n1.value+n2.value), sym_base.root._op('-',s1,s2)) end,
  },
  ['-'] = {
    ['+'] = function (n1,s1,n2,s2) return sym_base.root._op('+', sym_base.root._num(n1.value-n2.value), sym_base.root._op('-',s1,s2)) end,
    ['-'] = function (n1,s1,n2,s2) return sym_base.root._op('+', sym_base.root._num(n1.value-n2.value), sym_base.root._op('+',s1,s2)) end,
  },
},
['-'] = {
  ['+'] = {
    ['+'] = function (n1,s1,n2,s2) return sym_base.root._op('+', sym_base.root._num(n1.value+n2.value), sym_base.root._op('-',s2,s1)) end,
    ['-'] = function (n1,s1,n2,s2) return sym_base.root._op('-', sym_base.root._num(n1.value+n2.value), sym_base.root._op('+',s1,s2)) end,
  },
  ['-'] = {
    ['+'] = function (n1,s1,n2,s2) return sym_base.root._op('-', sym_base.root._num(n1.value-n2.value), sym_base.root._op('+',s1,s2)) end,
    ['-'] = function (n1,s1,n2,s2) return sym_base.root._op('+', sym_base.root._num(n1.value-n2.value), sym_base.root._op('-',s2,s1)) end,
  },
},
['*'] = {
  ['*'] = {
    ['*'] = function (n1,s1,n2,s2) return sym_base.root._op('*', sym_base.root._num(n1.value*n2.value), sym_base.root._op('*',s1,s2)) end,
    ['/'] = function (n1,s1,n2,s2) return sym_base.root._op('*', sym_base.root._num(n1.value*n2.value), sym_base.root._op('/',s1,s2)) end,
  },
  ['/'] = {
    ['*'] = function (n1,s1,n2,s2) return sym_base.root._op('*', sym_base.root._num(n1.value/n2.value), sym_base.root._op('/',s1,s2)) end,
    ['/'] = function (n1,s1,n2,s2) return sym_base.root._op('*', sym_base.root._num(n1.value/n2.value), sym_base.root._op('*',s1,s2)) end,
  },
},
['/'] = {
  ['*'] = {
    ['*'] = function (n1,s1,n2,s2) return sym_base.root._op('*', sym_base.root._num(n1.value*n2.value), sym_base.root._op('/',s2,s1)) end,
    ['/'] = function (n1,s1,n2,s2) return sym_base.root._op('/', sym_base.root._num(n1.value*n2.value), sym_base.root._op('*',s1,s2)) end,
  },
  ['/'] = {
    ['*'] = function (n1,s1,n2,s2) return sym_base.root._op('/', sym_base.root._num(n1.value/n2.value), sym_base.root._op('*',s1,s2)) end,
    ['/'] = function (n1,s1,n2,s2) return sym_base.root._op('*', sym_base.root._num(n1.value/n2.value), sym_base.root._op('/',s2,s1)) end,
  },
},
}

return sym_base
