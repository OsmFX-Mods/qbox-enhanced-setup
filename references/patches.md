# Resource patches

Exact changes for step 4. Apply only what's installed. Line numbers drift between
versions — match on the code, not the line.

Add a short comment on every edit noting it's an Enhanced fix, so the next person
updating the resource knows to re-apply it.

---

## vehiclehandler — missing native

`modules/handler.lua`, in `Handler:setActive`.

`GetIsVehicleElectric` does not exist on Enhanced. It throws
`attempt to call a nil value (global 'GetIsVehicleElectric')` and kills the handler
thread the moment a player enters any vehicle.

```lua
-- before
self.private.electric = GetIsVehicleElectric(self.private.model)

-- after
self.private.electric = GetIsVehicleElectric and GetIsVehicleElectric(self.private.model) or false
```

---

## qbx_garbagejob / qbx_mechanicjob / qbx_truckerjob — job read before login

All three run setup from `onResourceStart`, which on a fresh join fires before the
player has logged in. `QBX.PlayerData.job` is nil and the whole setup function aborts,
so blips and targets are never created.

Qbox is Lua 5.4 with safe navigation (`?.`) — already used across the codebase, so this
matches house style.

**qbx_garbagejob** — `client/main.lua`, in `setupClient`:

```lua
-- before
if playerJob.name == 'garbage' then
-- after
if playerJob?.name == 'garbage' then
```

**qbx_mechanicjob** — `client/main.lua`, in `registerDutyTarget`:

```lua
-- before
if QBX.PlayerData.job.type ~= 'mechanic' then
-- after
if QBX.PlayerData.job?.type ~= 'mechanic' then
```

**qbx_truckerjob** — `client/main.lua`, in `createElements`:

```lua
-- before
if QBX.PlayerData.job.name ~= 'trucker' then return end
-- after
if QBX.PlayerData.job?.name ~= 'trucker' then return end
```

Confirm the resource's `fxmanifest.lua` has `lua54 'yes'` before using `?.`. Qbox
resources do.

---

## qbx_medical — metadata read before login

`client/load-unload.lua`. `onResourceStart` calls `onPlayerLoaded()` unconditionally, so
on a fresh join it runs before login and throws on nil metadata. The real
`QBCore:Client:OnPlayerLoaded` fires again later with data, so an early return is safe.

```lua
-- before
CreateThread(function()
    Wait(1000)
    initHealthAndArmor(cache.ped, cache.playerId, QBX.PlayerData.metadata)
    initDeathAndLastStand(QBX.PlayerData.metadata)
end)

-- after
CreateThread(function()
    Wait(1000)

    local metadata = QBX.PlayerData.metadata
    if not metadata then return end

    initHealthAndArmor(cache.ped, cache.playerId, metadata)
    initDeathAndLastStand(metadata)
end)
```

---

## Renewed-Weathersync — GlobalState read at file scope

`client/weather.lua`, first line. The value is read before the global state bag has
replicated, so `setWeather()` throws on nil. The state bag handler further down assigns
the real value as soon as it arrives; the default just stops the first call erroring.

```lua
-- before
local serverWeather = GlobalState.weather
-- after
local serverWeather = GlobalState.weather or { weather = 'EXTRASUNNY' }
```

---

## npwd — dead `screenshot-basic` dependency

`fxmanifest.lua`. Enhanced doesn't resolve `provide`, so the manifest dependency check
fails even though the screencapture resource registers those exports under the literal
`screenshot-basic` name at runtime. Only the manifest check was broken.

```lua
-- before
dependency({
    "screenshot-basic",
    "pma-voice",
})

-- after
dependency({
    "pma-voice",
})
```

Do **not** rename the screencapture resource — that breaks anything calling
`exports.screencapture` directly.

---

## ox_lib — startup log spam (optional, cosmetic)

`init.lua`, in `loadModule`. Purely a log-volume fix: ox_lib probes for
`imports/<module>/<context>.lua` and `imports/<module>/shared.lua` unconditionally, and
most of those files don't exist. Silent on Legacy; Enhanced logs every failed read, so a
boot carries roughly 500 lines of `Failed to open file cfx_resource_ox_lib:...`.

Nothing is broken — but it buries real errors, which matters while migrating.

Generate the module lists from the installed copy:

```bash
cd resources/[ox]/ox_lib/imports
for ctx in server client shared; do
  echo "$ctx:"; for d in */; do [ -f "$d$ctx.lua" ] && printf "%s " "${d%/}"; done; echo
done
```

Then gate both reads on those lists, keyed to the installed version so an update falls
back to the original behaviour rather than breaking:

```lua
local PATCHED_FOR_VERSION = '<the installed ox_lib version>'

local moduleFiles = {
    server = { --[[ generated list ]] },
    client = { --[[ generated list ]] },
    shared = { --[[ generated list ]] },
}

local knownContext, knownShared
if GetResourceMetadata(ox_lib, 'version', 0) == PATCHED_FOR_VERSION then
    knownContext, knownShared = moduleFiles[context], moduleFiles.shared
end

local function loadModule(self, module)
    local dir = ('imports/%s'):format(module)
    local chunk = (not knownContext or knownContext[module])
        and LoadResourceFile(ox_lib, ('%s/%s.lua'):format(dir, context)) or nil
    local shared = (not knownShared or knownShared[module])
        and LoadResourceFile(ox_lib, ('%s/shared.lua'):format(dir)) or nil
    -- ... rest of the original function unchanged
```

A module absent from all three lists is skipped entirely, which reproduces the original
behaviour exactly — both reads returned nil and the function fell through.

Expect around 4 lines to remain: ox_lib has a second loader at `resource/init.lua` for
its own startup. Not worth patching.

---

## Re-applying after updates

Every patch here edits a vendored resource and will be lost on update. Keep a list in
the server's own notes. The two that break gameplay rather than just logging are the
framework detection fallback (step 3) and `vehiclehandler` — check those first after any
update.
