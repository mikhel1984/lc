

local gnuplot = {}
gnuplot.__index = gnuplot

gnuplot.type = 'gnuplot'


function gnuplot:new(o)
   local o = o or {}
   setmetatable(o, self)
   return o
end

gnuplot.cmd = function (g, cmd)
   if g.handle then
      g.handle:write(cmd, '\n')
      g.handle:flush()
   end
end

gnuplot.set_fn = function (g, f, l) table.insert(g, {f,legend=l}) end

gnuplot.set_xrange = function (g, x1, x2, dx) 
   g.xrange = {x1, x2, dx} 
   gnuplot.cmd(g, string.format("set xrange [%d:%d]", x1, x2))
end

gnuplot.set_yrange = function (g, y1, y2, dy) 
   g.yrange = {y1, y2, dy} 
   gnuplot.cmd(g, string.format("set yrange [%d:%d]", y1, y2))
end


gnuplot.set_xlabel = function (g, lbl) 
   g.xlabel = lbl 
   gnuplot.cmd(g, string.format('set xlabel "%s"', lbl))
end

gnuplot.set_ylabel = function (g, lbl) 
   g.ylable = lbl 
   gnuplot.cmd(g, string.format('set ylabel "%s"', lbl))
end

gnuplot.set_title = function (g, txt) 
   g.title = txt 
   gnuplot.cmd(g, string.format('set title "%s"', txt))
end

gnuplot.set_permanent = function (g, b) g.permanent = (b or true) end

gnuplot.close = function (g) 
   if g.handle then g.handle:close() end 
end


gnuplot.plot = function (g)
   -- reopen window
   if g.handle then g.handle:close() end
   g.handle = io.popen('gnuplot' .. (g.permanent and ' -p' or ''), 'w')
   -- set range
   if g.xrange then gnuplot.set_xrange(g, table.unpack(g.xrange)) end
   if g.yrange then gnuplot.set_yrange(g, table.unpack(g.yrange)) end
   if g.xlabel then gnuplot.set_xlabel(g, g.xlabel) end
   if g.ylabel then gnuplot.set_ylabel(g. g.ylabel) end
   if g.title then gnuplot.set_title(g, g.title) end

   -- prepare command set
   local plot = {}
   for _,f in ipairs(g) do
      local str
      if type(f[1]) == 'string' then 
         str = f[1]
      end
      if f.legend then str = string.format('%s title "%s"', str, f.legend) end
      plot[#plot+1] = str
   end
   local plot_fn = 'plot ' .. table.concat(plot, ',')
   gnuplot.cmd(g, plot_fn)
   -- settings
   
   return getmetatable(g) and g or gnuplot:new(g)
end

----------------------------------------

g = gnuplot:new()
g:set_xrange(0, 5)
g:set_xlabel("A")
g:set_ylabel("B")
g:set_permanent()
g:set_fn('sin(x)*x', 'legend')
g:set_fn('cos(x)', 'other')
g:set_title("Test")

g:plot()
os.execute('sleep 1')
