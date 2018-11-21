--[[       sonatalib/files.lua

--- Routines for working with data files.
--  @author <a href="mailto:sonatalc@yandex.ru">Stanislav Mikhel</a>
--  @release This file is a part of <a href="https://github.com/mikhel1984/lc">sonatalib</a> collection, 2017-2018.

           module 'files'
--]]

--------------- Tests ------------
--[[TEST

-- import 'files'
File = require 'sonatalib.files'
-- prepare file name
nm = os.tmpname()

-- save table 
-- separate elements with ';'
t = {{1,2,3},{4,5,6}}
File.dsvWrite(nm, t, ';')

-- read table from file
-- with separator ';'
tt = File.dsvRead(nm, ';')
ans = tt[2][2]                       --> 5

-- get file text as string
s = File.read(nm)
ans = string.sub(s,1,5)              --> '1;2;3'

-- serialize table to file
a = {1, 2.0, a = 'pqr', b = {3,4,c='abc'}}
File.tblExport(nm, a)

-- deserialize table from file
aa = File.tblImport(nm)
ans = aa.b.c                         --> 'abc'

-- string split
str = 'abc//defg//hijkl//mnop'
ans = 0
-- iterate over string parts
for s in File.split(str, '//') do ans = ans+1 end  --> 4

--]]

--	LOCAL

-- compatibility
local Ver = require "sonatalib.versions"

local READ, WRITE = 'read', 'write'

-- serialization rules
local val2str = {
   ['string'] =   function (x) return string.format('"%s"', x) end,
   ['number'] =   function (x) return Ver.mathType(x) == 'float' and string.format('%a',x) or string.format('%d',x) end,
   ['function'] = function (x) x = tostring(x); print('Bad value: '..x); return x end,
   ['boolean'] =  function (x) return tostring(x) end,
   ['nil'] =      function (x) return 'nil' end,
}
val2str['table'] = function (x) return val2str.tbl(x) end
val2str['thread'] = val2str['function']

--- Table to string conversation.
--  @param t Lua table.
--  @return String representation of the table elements.
val2str.tbl = function (t)
   local res = {}
   for i,val in ipairs(t) do res[i] = val2str[type(val)](val) end
   for k,val in pairs(t) do
      if not Ver.isInteger(k) then res[#res+1] = string.format("['%s']=%s", tostring(k), val2str[type(val)](val)) end
   end
   return string.format('{%s}', table.concat(res,','))
end

--	INFO

local help = lc_version and (require "sonatalib.help") or {new=function () return {} end}

--	MODULE

local files = {
-- description
about = help:new("Routines for working with data files."),
}

--- Split string into substrings based on the given delimiter.
--  @param str Initial string.
--  @param delim Delimiter string.
--  @return Iterator over substrings.
files.split = function (str, delim)
   local i,j,k = 1,1,0
   -- return iterator
   return function ()
      if not str or i > #str then return nil end
      j,k = string.find(str, delim, k+1)
      local res
      if j then
         res = string.sub(str, i, j-1)
	 i = k+1
      else  -- no more delimiters
         res = string.sub(str, i)
	 i = #str+1
      end
      return res
   end
end
files.about[files.split] = {"split(str,delim)", "Return iterator over substrings separated by the delimiter.", help.OTHER}

--- Save Lua table in file, use given delimiter.
--  @param tbl Lua table.
--  @param fName File name.
--  @param delim Delimiter, default is coma.
files.dsvWrite = function (fName, tbl, delim)
   local f = assert(io.open(fName,'w'), "Can't create file "..tostring(fName))
   delim = delim or ','
   for _,v in ipairs(tbl) do
      if type(v) == 'table' then v = table.concat(v,delim) end
      f:write(v,'\n')
   end
   f:close()
   print('Done')
end
files.about[files.dsvWrite] = {"dsvWrite(fname,tbl,delim)", "Save Lua table as delimiter separated data into file.", WRITE}

--- Import data from text file, use given delimiter.
--  @param fName File name.
--  @param delim Delimiter, default is coma.
--  @return Lua table with data.
files.dsvRead = function (fName, delim)
   local f = assert(io.open(fName, 'r'), "Can't open file "..fName)
   delim = delim or ','
   local res = {}
   for s in f:lines('l') do
      -- read data
      s = string.match(s,'^%s*(.*)%s*$')
      local i,j = #res+1,1
      if #s > 0 then
         res[i] = {}
	 -- read string elements
	 for p in files.split(s,delim) do
	    res[i][j], j = (tonumber(p) or p), j+1
	 end
      end
   end
   f:close()
   return res
end
files.about[files.dsvRead] = {"dsvRead(fName,del)", "Read delimiter separated data as Lua table.", READ}

--- Returns text of the file.
--  @param fName
--  @return String or nil.
files.read = function (fName)
   local f, str = io.open(fName, 'r')
   if f then
      str = f:read('*a')
      f:close()
   end
   return str
end

--- Load Lua table from file.
--  @param fName File name.
--  @return Lua table or nil.
files.tblImport = function (fName)
   local str,f = files.read(fName)
   -- use Lua default import
   if str then f = Ver.loadStr('return '..str) end
   return f and f() or nil
end
files.about[files.tblImport] = {"tblImport(fName)", "Import Lua table, written into file.", READ}

--- Save Lua table to the file.
--  @param fName File name.
--  @param tbl Lua table.
files.tblExport = function (fName, tbl)
   assert(fName and tbl, 'Wrong arguments!')
   local str = val2str.tbl(tbl)
   local f = assert(io.open(fName,'w'), "Can't create file "..tostring(fName))
   f:write(str)
   f:close()
   print('Done')
end
files.about[files.tblExport] = {"tblExport(fName,tbl)", "Save Lua table into file.", WRITE}

-- free memory in case of standalone usage
if not lc_version then files.about = nil end

return files

--==================================
--TODO: improve dsv read/write according the specification
--TODO: fix export negative and fractional keys
--TODO: json read/write
