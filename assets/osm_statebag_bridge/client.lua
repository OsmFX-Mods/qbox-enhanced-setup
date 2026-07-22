--[[
    osm_statebag_bridge — client

    Writes the server's value into LocalPlayer.state with replicate = false.

    That is the whole trick: a LOCAL write to the player's own bag still fires
    every AddStateBagChangeHandler registered for 'player:<serverId>' on this
    client. So qbx_core, ox_inventory, qbx_hud, qbx_medical and pma-voice all keep
    their existing handlers and need no changes — they simply start receiving the
    values Enhanced refuses to replicate.

    replicate = false matters: it keeps the value local, so we never echo back to
    the server and never fight the authoritative value.
]]

RegisterNetEvent('osm_sb:set', function(key, value)
    LocalPlayer.state:set(key, value, false)
end)

---Ask for a full snapshot once the session is live, and again whenever this
---resource restarts, so we're never left waiting on the next value change.
CreateThread(function()
    while not NetworkIsSessionStarted() do
        Wait(100)
    end

    TriggerServerEvent('osm_sb:request')
end)

---Diagnostic: /sbbridge in the F8 console prints what actually landed locally.
RegisterCommand('sbbridge', function()
    local state = LocalPlayer.state
    local parts = {}

    for i = 1, #Bridge.keys do
        local key = Bridge.keys[i]
        local value = state[key]

        if value ~= nil then
            parts[#parts + 1] = ('%s=%s'):format(key, type(value) == 'table' and json.encode(value) or tostring(value))
        end
    end

    print(('[osm_sb] local player bag: %s'):format(#parts > 0 and table.concat(parts, ' ') or '(empty — bridge is NOT working)'))
end, false)
