local _, addonTable = ...

local L = {}
local locales = {}
local display_locales = {}
function addonTable.NewLocale(name, displayName, parentName)
	local L = locales[name] or {}
	locales[name] = L
	display_locales[name] = displayName
	if parentName then
		setmetatable(L, { __index = locales[parentName] } )
	end
	return L
end

-- returns true if the locale was set, false otherwise
function addonTable.SetLocale(name)
	if locales[name] then
		setmetatable(L, { __index = locales[name] } )
		return true
	end
	return false
end

function addonTable.GetLocale()
	return L
end

function addonTable.GetDisplayLocales()
	return display_locales
end

function addonTable.WipeLocales()
	table.wipe(locales)
end
