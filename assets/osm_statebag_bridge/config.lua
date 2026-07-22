Bridge = {}

--- How often (ms) the server re-reads each mirrored key per player.
--- 200ms is responsive enough for gameplay gates without meaningful cost.
Bridge.interval = 200

--- Keys mirrored from the server's player state bag down to the owning client.
---
--- ONLY list keys the SERVER owns. Client-owned keys (crouch, seatbelt, proximity,
--- invOpen, harness, syncWeather, ...) already work on Enhanced and must NOT be
--- listed — mirroring a stale server value would clobber the client's own write.
Bridge.keys = {
    -- qbx_core — the critical one. Gates QBX.IsLoggedIn, ox_inventory's session
    -- handling, qbx_medical's death/laststand, and qbx_hud's needs display.
    'isLoggedIn',

    -- qbx_medical
    'isDead',
    'inLastStand',
    'qbx_medical:deathState',
    'bleedLevel',

    -- qbx_smallresources / qbx_core qb-bridge (HUD needs & stats)
    'hunger',
    'thirst',
    'stress',
    'armor',

    -- qbx_core routing buckets, PVP & instances
    'instance',
    'PVPEnabled',

    -- qbx_vehiclekeys & garages
    'keysList',
    'canSteal',
    'inGarage',

    -- qbx_vehicleshop / appearance
    'isInTestDrive',
    'isDressing',

    -- pma-voice
    'radioChannel',
    'callChannel',
    'assignedChannel',
    'submix',
    'disableRadio',

    -- ox_inventory
    -- NOTE: ox_inventory also writes invBusy client-side. The server is authoritative,
    -- so mirroring is normally correct, but if you ever see the inventory stuck
    -- refusing to open, comment this line out first — it is the likeliest culprit.
    'invBusy',
    'loadInventory',
}
