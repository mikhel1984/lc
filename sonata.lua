#!/usr/local/bin/lua -i
-- Lua based calculator 
-- This file is a part of 'liblc' collection, 2017-2018.

--================= CONFIGURATION ====================

--	Uncomment to set the localization file
LC_LOCALIZATION = "ru.lng"

--	Text coloring
LC_USE_COLOR = true

--	Load after start (optional)
--LC_DEFAULT_MODULES = {'matrix','numeric'}

--	Path (optional, for bash alias lc='path/to/sonata.lua') 
--LC_ADD_PATH = path/to/?.lua

--=====================  CODE  ========================

-- Version
lc_version = '0.8.5'

-- Add path to the libraries
if LC_ADD_PATH then
   package.path = package.path..';'..LC_ADD_PATH
end

-- Table for program variables. Import base functions 
liblc = {main=require('liblc.main')}

-- Text colors 
lc_help.usecolors(LC_USE_COLOR) 

-- Quick exit 
quit = function () print(lc_help.CMAIN.."\n              --======= Buy! =======--\n"..lc_help.CRESET); os.exit() end

-- Modules 
import = {
--   name     alias
   array    = "Arr",
   bigint   = "Big",
   complex  = "Comp",
   const    = "_C",
   files    = "File",
   gnuplot  = "Gnu",
   graph    = "Graph",
   matrix   = "Mat",
   numeric  = "Num",
   polynom  = "Poly",
   rational = "Rat",
   set      = "Set",
   special  = "Spec",
   stat     = "Stat",
   struct   = "DS",
   units    = "Unit",
}
about[import] = {"import", ""}

-- Update help information about imported modules 
function liblc.import_state_update()
   local m = {string.format("%-12s%-9s%s", "MODULE", "ALIAS", "LOADED")}
   for k,v in pairs(import) do
      m[#m+1] = string.format("%-13s%-10s%s", k, v, (_G[v] and 'v' or '-'))
   end
   m[#m+1] = about:get('use_import')
   return table.concat(m, '\n')
end

-- Import actions 
function liblc.doimport(tbl,name)
   local var = tbl[name]
   if not var then
      if not liblc.alias then 
         liblc.alias = {}
	 for k,v in pairs(import) do liblc.alias[v] = k end
      end
      var = name
      name = assert(liblc.alias[name], "Wrong module name: "..name.."!")
   end
   if not _G[var] then
      _G[var] = require('liblc.'..name)
      about:add(_G[var].about, var)
      if _G[var].onimport then _G[var].onimport() end
   end
   return var, name
end

-- Add modules 
setmetatable(import, 
{ __tostring = function (x) io.write(lc_help.CHELP); return about:get('done') end,
  __call = function (self, name) 
    if name == 'all' then 
       for k,v in pairs(self) do liblc.doimport(self,k) end
    elseif type(name) == 'table' then
       for _,v in ipairs(name) do import(v) end
    else
       local var, nm = liblc.doimport(self,name)
       io.write(lc_help.CHELP)
       print(string.format(about:get('alias'), lc_help.CBOLD..var..lc_help.CNBOLD, nm))
    end
    about[import][2] = liblc.import_state_update()
    return import
  end,
})

-- Process command line arguments
if #arg > 0 then
   local command = liblc.main.args[arg[1]]
   if type(command) == 'string' then command = liblc.main.args[command] end
   if not command then command = liblc.main.args['no flags'] end
   command.process(arg)
   if command.exit then os.exit() end
end

-- Read localization file and update descriptions 
if LC_LOCALIZATION then 
   about:localization(LC_LOCALIZATION) 
end
about[import][2] = liblc.import_state_update()

-- Run! 
io.write(lc_help.CMAIN)
print("\n   # #       --===== Sonata LC =====--       # #\n    # #         --==== "..lc_version.." ====--         # #\n")
io.write(lc_help.CHELP)
print(about:get('intro'))

_PROMPT = lc_help.CMAIN..'lc:'..lc_help.CRESET..' '
_PROMPT2= lc_help.CMAIN..'..:'..lc_help.CRESET..' '

-- Import default modules
if LC_DEFAULT_MODULES then
   import(LC_DEFAULT_MODULES)  
end

--===============================================
