--//Exports

local Slices = require(script.Parent)

--//Variables

local ClientSlices = table.clone(Slices)

--//Types

export type States = Slices.States

export type Actions = Slices.Actions

--//Returner

return ClientSlices
