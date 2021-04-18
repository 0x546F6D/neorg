--[[
--	ROOT NEORG FILE
--	This file is the begininng of the entire plugin. It's here that everything fires up and start pumping.
--]]

neorg = {}

-- Require the most important modules
require('neorg.events')
require('neorg.modules')

-- Configuration template
neorg.configuration = {

	user_configuration = {
		load = {
			--[[
				["name"] = { git_address = "address", config = { ... } }
			--]]
		},
	},

}

-- Grab OS info on startup
neorg.configuration.os_info = (function()

	if vim.fn.has("win32") == 1 then
		return "windows"
	elseif vim.fn.has("unix") == 1 then
		return "linux"
	elseif vim.fn.has("mac") == 1 then
		return "mac"
	end

end)()

-- @Summary Sets up neorg
-- @Description This function takes in a user configuration, parses it, initializes everything and launches neorg if inside a .norg or .org file
-- @Param  config (table) - a table that reflects the structure of neorg.configuration.user_configuration
function neorg.setup(config)
	neorg.configuration.user_configuration = config or {}

	-- Create a new global instance of the neorg logger
	require('neorg.external.log').new(neorg.configuration.user_configuration.logger or log.get_default_config(), true)

	-- If we are launching a .norg or .org file, fire up the modules!
	local ext = vim.fn.expand("%:e")

	if ext == "org" or ext == "norg" then neorg.org_file_entered(config.load) end
end

-- @Summary Neorg startup function
-- @Description This function gets called after setup() and loads all of the user-defined modules.
-- @Param  module_list (table) - a table that reflects the structure of neorg.configuration.user_configuration.load
function neorg.org_file_entered(module_list)

	-- If no module list was defined, don't do anything
	if not module_list then return end

	-- Loop through all the modules and load them one by one
	-- In the future this function will be async, but because of issues with pcall(...) we can't do that right now
	for name, module in pairs(module_list) do
		if not neorg.modules.load_module(name, module.git_address, module.config) then
			log.error("Halting loading of modules due to error...")
			break
		end
	end

	-- Even though we couldn't run that previous function asynchronously we can however run this one!
	local async

	async = vim.loop.new_async(function()

		-- Goes through each loaded module and invokes neorg_post_load()
		for _, module in pairs(neorg.modules.loaded_modules) do
			module.neorg_post_load()
		end

		async:close()

	end)

	async:send()

end

return neorg
