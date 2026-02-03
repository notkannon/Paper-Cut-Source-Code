local package = script.Parent

local baseEffect = require(package.baseEffect)
local client = require(package.client)
local configuration = require(package.configuration)
local wrapper = require(package.wrapper)

return {
	BaseEffect = baseEffect,
	VisualEffectDecorator = wrapper.VisualEffectDecorator,
	CreateEffect = wrapper.CreateEffect,
	Register = client.Register,
	Start = client.Start,
	Configure = configuration.Configure,
	Config = configuration.Config,
}
