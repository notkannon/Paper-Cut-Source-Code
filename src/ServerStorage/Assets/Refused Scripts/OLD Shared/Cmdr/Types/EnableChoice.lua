return function (registry)
	-- registry
	registry:RegisterType("enableChoice", registry.Cmdr.Util.MakeEnumType("Enable choice", {'enabled', 'disabled'}))
end