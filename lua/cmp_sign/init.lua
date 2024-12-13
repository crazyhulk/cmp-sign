-- ~/.config/nvim/lua/my_autocomplete/init.lua

-- Require nvim-cmp
local cmp = require('cmp')

-- Define a custom source
local source = {}

-- key: completion item menu
-- value: string, {{sign}} would be replaced with the signature
local custom_completion_items = {}

-- find the start index of the raw code
--    s.Name(⁁(*ReviewServer).GetReviewDetailByComicID. -> (*ReviewServer).GetReviewDetailByComicID
--    ⁁(*ReviewServer).GetReviewDetailByComicID. -> (*ReviewServer).GetReviewDetailByComicID
--    ⁁GetReviewDetailByComicID. -> GetReviewDetailByComicID
local function findRawCodeIndex(rawstr)
	print("rawstr:", rawstr)
	for i = 1, #rawstr do
		local j = #rawstr - i
		if rawstr:sub(j,j):match("%s") then
			return j + 1
		end
		if j == 1 then
			return j
		end

		if rawstr:sub(j,j) == "(" and rawstr:sub(j-1,j-1) == "(" then
			return j
		end
		if rawstr:sub(j,j) == "(" and rawstr:sub(j-1,j-1) ~= "." then
			return j + 1
		end
	end
end


source.new = function()
	local self = setmetatable({}, { __index = source })
	self.buffers = {}
	return self
end

source.setup = function (completion_items)
	custom_completion_items = completion_items
end

-- Method to determine if the source is available in the current context
function source:is_available()
  return true
end

source._get_client = function(self)
	local get_clients = vim.lsp.get_clients or vim.lsp.buf_get_clients
	for _, client in pairs(get_clients()) do
		if self:_get(client.server_capabilities, { 'signatureHelpProvider' }) then
			return client
		end
	end
	return nil
end

source._get = function(_, root, paths)
  local c = root
  for _, path in ipairs(paths) do
    c = c[path]
    if not c then
      return nil
    end
  end
  return c
end

source.complete = function(self, params, callback)
	local client = self:_get_client()
	-- for _, c in ipairs(self:_get(client.server_capabilities, { 'signatureHelpProvider', 'triggerCharacters' }) or {}) do
	-- 	table.insert(trigger_characters, c)
	-- end
	-- for _, c in ipairs(self:_get(client.server_capabilities, { 'signatureHelpProvider', 'retriggerCharacters' }) or {}) do
	-- 	table.insert(trigger_characters, c)
	-- end

	-- local trigger_character = nil
	-- for _, c in ipairs(trigger_characters) do
	-- 	local s, e = string.find(params.context.cursor_before_line, '(' .. vim.pesc(c) .. ')%s*$')
	-- 	if s and e then
	-- 		trigger_character = string.sub(params.context.cursor_before_line, s, s)
	-- 		break
	-- 	end
	-- end
	-- print("before===========", vim.inspect(trigger_character))
	-- if not trigger_character then
	-- 	return callback({ isIncomplete = true })
	-- end

	if not client then
		return
	end
	local request = vim.lsp.util.make_position_params(0, client.offset_encoding)
	local position = request.position
	request.position = {
		line = position.line,
		character = position.character - 2,
	}

	request.context = {
		triggerKind = 2,
		triggerCharacter = ".",
		-- isRetrigger = not not self.signature_help,
		activeSignatureHelp = self.signature_help,
	}
	-- local xparams = vim.lsp.util.make_position_params()
	-- position = xparams.position
	-- xparams.position = {
	-- 	line = position.line,
	-- 	character = position.character - 1,
	-- }
        --
	-- vim.lsp.buf_request(0, 'textDocument/signatureHelp', xparams, function(err, result, context, config)
	-- 	print("========2",err, vim.inspect(result))
	-- end)
	local line = vim.api.nvim_get_current_line()
	-- client.request('textDocument/hover', request, function(err, signature_help, ctx)
	client.request('textDocument/signatureHelp', request, function(err, signature_help, ctx)
		if err or not signature_help then
			callback({})
			return
		end

		if #signature_help.signatures < 1 then
			callback({})
			return
		end


		local raw_func_sign = "func " .. signature_help.signatures[1].label
		if not raw_func_sign then
			callback({})
			return
		end

		local pattern = "func%s*([%w%s(%.%*)]*)%s+([%w%.]+)(%b())%s*(.*)"
		local member_object, func_name, param_list, returns = raw_func_sign:match(pattern)


		local func_sign = raw_func_sign:gsub(func_name, "", 1)

		local index = findRawCodeIndex(line:sub(1, position.character))
		local raw_code = line:sub(index, position.character-1)

		local start_pos = {
			line = position.line,
			character = position.character - #raw_code - 1
		}
		local end_pos = {
			line = position.line,
			character = position.character
		}

		local sign = {
			label = 'sign',
			insertText = func_sign,
			insertTextFormat = 2,  -- Snippet format
			-- textEdit = {
			-- 	range = {
			-- 		start = signature_help.range.start,
			-- 		["end"] = {
			-- 			line = signature_help.range["end"].line,
			-- 			character = signature_help.range["end"].character + 1
			-- 		},
			-- 	},
			-- 	newText = "111"
			-- },
			additionalTextEdits = {
				{
					range = {
						start = start_pos,
						["end"] = end_pos,
					},
					newText = "",
				}
			},

			kind = cmp.lsp.CompletionItemKind.Snippet,
			documentation = {
				kind = cmp.lsp.MarkupKind.Markdown,
				value = raw_func_sign
			},
		}


		-- local mockey_text = "mockey.Mock(" .. func_name .. ").To(" .. func_sign .. " {\n\treturn\n}).Build()"
		-- local mockey_text = "mockey.Mock(" .. line:sub(#line-position.character, #line-1) .. ").To(" .. func_sign .. " {\n\treturn\n}).Build()"
		local mockey_text = "mockey.Mock(" .. raw_code .. ").To(" .. func_sign .. " {\n\treturn\n}).Build()"
		local mockey = {
			label = 'mockey',
			insertText = mockey_text,
			insertTextFormat = 2,  -- Snippet format
			-- textEdit = {
			-- 	range = {
			-- 		start = signature_help.range.start,
			-- 		["end"] = {
			-- 			line = signature_help.range["end"].line,
			-- 			character = signature_help.range["end"].character + 1
			-- 		},
			-- 	},
			-- 	newText = "111"
			-- },
			additionalTextEdits = {
				{
					range = {
						start = start_pos,
						["end"] = end_pos,
					},
					newText = "",
				}
			},

			kind = cmp.lsp.CompletionItemKind.Snippet,
			documentation = {
				kind = cmp.lsp.MarkupKind.Markdown,
				value = mockey_text
			},
		}

		local items = {
			sign,
			mockey
		}
		for i,v in pairs(custom_completion_items) do
			local text = v:gsub("{{name}}", func_name)
			text = text:gsub("{{sign}}", func_sign)
			local xitem = {
				label = i,
				insertText = text,
				insertTextFormat = 2,  -- Snippet format
				additionalTextEdits = {
					{
						range = {
							start = start_pos,
							["end"] = end_pos,
						},
						newText = "",
					}
				},

				kind = cmp.lsp.CompletionItemKind.Snippet,
				documentation = {
					kind = cmp.lsp.MarkupKind.Markdown,
					value = text
				},
			}
			table.insert(items, xitem)
		end


		callback({
			isIncomplete = false,
			items = items
		})
	end)
end

source.get_trigger_characters = function()
  return { '.' }
end

return source
-- cmp.register_source('nvim-cmp-sign', source)
