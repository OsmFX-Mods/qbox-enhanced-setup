--[[
    osm_statebag_bridge — server

    Enhanced never delivers server-written player state bag values to the owning
    client (citizenfx/rfc#77). Server-side reads are correct, so we poll the bag
    here and push changes down a plain net event, which does still work.

    Polling rather than hooking the writes deliberately: there is no global hook
    for state bag writes, and polling means ZERO edits to qbx_core, ox_inventory,
    pma-voice or anything else. Delete this resource and everything reverts.
]]

local keys = Bridge.keys
local keyCount = #keys
local interval = Bridge.interval

---Last value we pushed, per player, in comparable (serialised) form.
---@type table<number, table<string, any>>
local sent = {}

---Tables come back from the state bag as a fresh table each read, so identity
---comparison always reports a change. Serialise those; leave scalars alone.
---@param value any
---@return any comparable
local function comparable(value)
    if type(value) == 'table' then return json.encode(value) end
    return value
end

---Push every mirrored key whose value changed since the last pass.
---@param src number
---@param force? boolean send everything, changed or not
local function syncPlayer(src, force)
    local state = Player(src).state
    if not state then return end

    local last = sent[src]

    if not last then
        last = {}
        sent[src] = last
    end

    for i = 1, keyCount do
        local key = keys[i]
        local value = state[key]
        local now = comparable(value)

        if force or now ~= last[key] then
            last[key] = now
            TriggerClientEvent('osm_sb:set', src, key, value)
        end
    end
end

CreateThread(function()
    while true do
        Wait(interval)

        local players = GetPlayers()

        for i = 1, #players do
            syncPlayer(tonumber(players[i]))
        end
    end
end)

---Client asks for a full snapshot when it (re)starts, so a resource restart or a
---mid-session join doesn't leave it waiting for the next value change.
RegisterNetEvent('osm_sb:request', function()
    local src = source

    sent[src] = nil
    syncPlayer(src, true)
end)

AddEventHandler('playerDropped', function()
    sent[source] = nil
end)

---Diagnostic: compare what the server holds against what we've pushed.
RegisterCommand('sbbridge', function(source)
    if source ~= 0 then return end

    local players = GetPlayers()

    print(('[osm_sb] interval=%dms keys=%d players=%d'):format(interval, keyCount, #players))

    for i = 1, #players do
        local src = tonumber(players[i])
        local state = Player(src).state
        local parts = {}

        for j = 1, keyCount do
            local key = keys[j]
            local value = state[key]

            if value ~= nil then
                parts[#parts + 1] = ('%s=%s'):format(key, comparable(value))
            end
        end

        print(('[osm_sb]   %d: %s'):format(src, #parts > 0 and table.concat(parts, ' ') or '(no mirrored keys set)'))
    end
end, true)
