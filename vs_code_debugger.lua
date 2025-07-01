function load_all_lua_files()
    -- Get the directory path of the current script
    local script_path = debug.getinfo(1, "S").source:match("@?(.+)")
    local script_dir = script_path:match("(.+)[/\\][^/\\]*$") or "."
    
    -- Platform-specific directory listing for Windows
    local function get_lua_files(directory)
        local files = {}
        local handle = io.popen('dir "' .. directory .. '\\*.lua" /b 2>nul')
        if handle then
            for file in handle:lines() do
                if file ~= "vs_code_debugger.lua" then -- Don't include this debugger file
                    table.insert(files, file)
                end
            end
            handle:close()
        end
        return files
    end
    
    -- Load each Lua file
    local relative_path = script_dir .. "\\..\\"
    local lua_files = get_lua_files(relative_path)
    print("Found Lua files: " .. table.concat(lua_files, ", "))
    
    for _, file in ipairs(lua_files) do
        local file_path = relative_path .. file
        print("Loading: " .. file)
        local success, err = pcall(dofile, file_path)
        if not success then
            print("Error loading " .. file .. ": " .. tostring(err))
        else
            print("Successfully loaded: " .. file)
        end
    end
end

function compatibility()


    COMPATIBILITY_GLOBALS = {
        tree = {
            parts = {},
            groups = {},
            lines = {},
        },
        dialogs = {},
    }
    
    if not pyloc then
        pyloc = function (str)
            return str
        end
    end

    local get_dialog_handle = function ()
        local dialog_handle = {
            data = {},
            end_modal_ok = function ()
                print("ending_modal_dialog ok")
            end,
            end_modal_cancel = function ()
                print("ending_modal_dialog cancel")
            end,
            set_window_title = function (dialog_handle, title)
                dialog_handle.title = title
            end,
            create_text_box = function (dialog_handle, col_tbl, text, options)
                local text_box = {
                    col_tbl = col_tbl,
                    text = text,
                    options = options or {},
                    set_control_text = function (self, text)
                        self.text = text
                    end,
                    delete_control = function (self)
                        for i, v in pairs (self) do
                            self[i] = nil
                        end
                    end,
                    enable_control = function (self, state)
                        self.enabled = state or nil
                    end,
                    show_control = function (self, state)
                        self.visible = state or nil
                    end,
                    set_on_change_handler = function (self, handler)
                        self.on_change_handler = handler
                    end,
                }
                table.insert(dialog_handle.data, text_box)
                print("pyui.create_text_box: " .. table_tostring(text_box))
                return text_box
            end,
            create_button = function (dialog_handle, col_tbl, text, options)
                local button = {
                    col_tbl = col_tbl,
                    text = text,
                    options = options or {},
                    set_control_text = function (self, text)
                        self.text = text
                    end,
                    delete_control = function (self)
                        for i, v in pairs (self) do
                            self[i] = nil
                        end
                    end,
                    enable_control = function (self, state)
                        self.enabled = state or nil
                    end,
                    show_control = function (self, state)
                        self.visible = state or nil
                    end,
                    set_on_click_handler = function (self, handler)
                        self.on_click_handler = handler
                    end,
                }
                table.insert(dialog_handle.data, button)
                print("pyui.create_button: " .. table_tostring(button))
                return button
            end,
        }
        dialog_handle.create_label = dialog_handle.create_text_box
        dialog_handle.create_text_spin = dialog_handle.create_text_box
        dialog_handle.create_ok_button = function (dialog_handle, col_tbl, text, options)
            local button = dialog_handle:create_button(col_tbl, text, options)
            button:set_on_click_handler(function()
                dialog_handle.end_modal_ok()
            end)
            return button
        end
        dialog_handle.create_cancel_button = function (dialog_handle, col_tbl, text, options)
            local button = dialog_handle:create_button(col_tbl, text, options)
            button:set_on_click_handler(function()
                dialog_handle.end_modal_cancel()
            end)
            return button
        end

        return dialog_handle
    end

    -- create dummy functions for debuging outside of pytha
    if not pyui then
        pyui = {
            alert = function(msg)
                print("pyui.alert: " .. tostring(msg))
            end,
            format_number = function (number, decimals)
                decimals = decimals or 2
                return string.format("%." .. decimals .. "f", number)
            end,
            format_length = function(length)
                return length
            end,
            parse_length = function(length_str)
                return length_str
            end,
            parse_number = function(number_str)
                return tonumber(number_str)
            end,
            run_modal_dialog = function (dialog_func, ...)
                local dialog_handle = get_dialog_handle()
                table.insert(COMPATIBILITY_GLOBALS.dialogs, dialog_handle)
                dialog_func(dialog_handle, ...)
            end,
        }
    end

    if not pyux then
        pyux = {
            set_on_left_click_handler = function(handler)
                COMPATIBILITY_GLOBALS.set_on_left_click_handler = handler
            end,
            identify_coordinate_in_area = function(coos_vp, area)
                print("pyux.identify_coordinate_in_area: " .. tostring(coos_vp) .. ", " .. tostring(area))
                -- Dummy implementation, always returns false
                return false
            end,
            highlight_line = function (origin, terminus, options)
                table.insert(COMPATIBILITY_GLOBALS.tree.lines, { origin = origin, terminus = terminus, options = options })
                print("pyux.highlight_line: " .. tostring(origin) .. ", " .. tostring(terminus) .. ", " .. tostring(options))
            end,
            clear_highlights = function ()
                COMPATIBILITY_GLOBALS.tree.lines = {}
                print("pyux.clear_highlights")
            end,
        }
    end

    if not pytha then
        pytha = {
            create_block = function(length, width, height, origin)
                local element_handle = {
                    type = "block",
                    name = nil,
                    group = nil,

                    length = length,
                    width = width,
                    height = height,
                    origin = origin or {0, 0, 0},
                }
                table.insert(COMPATIBILITY_GLOBALS.tree.parts, element_handle)
                print("pytha.create_block: " .. table_tostring(element_handle))
                return element_handle
            end,
            create_group = function (elements, attributes)
                local element_handle = {
                    type = "group",
                    name = attributes and attributes.name or nil,
                }
                if #elements > 0 then
                    element_handle.elements = elements or {}
                else
                    element_handle.elements = {elements}
                end
                table.insert(COMPATIBILITY_GLOBALS.tree.groups, element_handle)
                print("pytha.create_group: " .. table_tostring(element_handle))
                return element_handle
            end,
            delete_element = function(element_handle)
                print("pytha.delete_element: " .. table_tostring(element_handle))
                if element_handle.type == "block" then
                    for i, part in ipairs(COMPATIBILITY_GLOBALS.tree.parts) do
                        if part == element_handle then
                            table.remove(COMPATIBILITY_GLOBALS.tree.parts, i)
                            break
                        end
                    end
                elseif element_handle.type == "group" then
                    for i, group in ipairs(COMPATIBILITY_GLOBALS.tree.groups) do
                        if group == element_handle then
                            table.remove(COMPATIBILITY_GLOBALS.tree.groups, i)
                            break
                        end
                    end
                end
            end,
            set_element_attributes = function (element_handle, attributes)
                if element_handle.type == "block" or element_handle.type == "group" then
                    element_handle.name = attributes.name or element_handle.name
                    print("pytha.set_element_attributes: " .. table_tostring(element_handle))
                else
                    print("pytha.set_element_attributes: Unsupported element type")
                end
                
            end,
            push_local_coordinates = function (origin)
                print("pytha.push_local_coordinates: " .. tostring(origin))
                -- Dummy implementation, just prints the origin
            end,
            pop_local_coordinates = function ()
                print("pytha.pop_local_coordinates")
                -- Dummy implementation, just prints a message
            end,
        }
    end

end

function debug_main()
    print("Debugging main function")
    -- Add your debugging code here
    compatibility()
    load_all_lua_files()

    test_calculate_sizing_fit()
    test_calculate_sizing_grow()
    test_complex_sizing()
    test_fixed_divisions()
    test_positioning_calculation()
end

debug_main()