local json = require "json"
local socket = require "socket"
local udp = socket.udp()
udp:settimeout(0)
udp:setsockname("*", 12345)
local world = {}
local data, msg_or_ip, port_or_nil
local entity, cmd, parms

-- Server wakes up every 0.1 sec, updates game state based on incoming data, sends update to clients
while true do
    repeat
        data, msg_or_ip, port_or_nil = udp:receivefrom()
        if data then
            entity, cmd, parms = data:match("^(%S*) (%S*) (.*)")
            if cmd == "move" then
                local x, y = parms:match("^(%-?[%d.e]*) (%-?[%d.e]*)$")
                if x and y then
                    local ent = world[entity] or {x = 0, y = 0}
                    x, y = ent.x + tonumber(x), ent.y + tonumber(y)
                    if x >= 0 and x <= 775 and y >= 0 and y <= 575 then
                        local collision = false
                        for k, v in pairs(world) do
                            if k ~= entity then
                                local p1x, p1y = math.max(x, v.x), math.max(y, v.y)
                                local p2x, p2y = math.min(x + 32, v.x + 32), math.min(y + 32, v.y + 32)
                                if p2x - p1x >= 0 and p2y - p1y >= 0 then
                                    collision = true
                                    break
                                end
                            end
                        end
                        if not collision then
                            world[entity] = {x = x, y = y, ip = msg_or_ip, port = port_or_nil}
                        end
                    end
                end
            elseif cmd == "quit" then
                world[entity] = nil
            else print("Unknown command: ", cmd, data) end
        elseif msg_or_ip ~= "timeout" then print("Unknown network error: " .. tostring(msg_or_ip)) end
    until not data
    
    -- Global push of world state, limited by fog of war
    for k, v in pairs(world) do
        local payload = {}
        for k1, v1 in pairs(world) do
            -- If in vision range, add to world state update
            if math.sqrt((v.x + 16 - v1.x)^2 + (v.y + 16 - v1.y)^2) < (32 * 4) then
                payload[k1] = {x = v1.x, y = v1.y}
            end
        end
        udp:sendto(json.encode(payload), v.ip, v.port)
    end
    socket.sleep(0.1)
end
