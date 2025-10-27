--local a = iAm("admin") or Modules.Get("admin")

local a = Module.New("admin", "modules/admin")
a:Description("Admin module")
a:Author("unionVolt Studios")
a:Version("1.0.0")
a:Dependency("es_extended")

a:OnStart(function()
	print("Admin module loaded.")
end)

function openBetterAdmin() end
