local json = require "json"
local socket = require "socket"
local address, port = "localhost", 12345
local entity
local updaterate = 0.1
local world = {}
local t

function love.load()
    udp = socket.udp()
    udp:settimeout(0)
    udp:setpeername(address, port)
    love.graphics.setBackgroundColor(255, 255, 255)
    entity_img = love.graphics.newImage("unitR.png")
    math.randomseed(os.time()) 
    entity = tostring(math.random(9999))
    t = 0
end

function love.update(deltatime)
    t = t + deltatime
    if t > updaterate then
        local x, y = 0, 0
        if love.keyboard.isDown("up") or love.keyboard.isDown("w") then y = y - (70 * t) end
        if love.keyboard.isDown("down") or love.keyboard.isDown("s") then y = y + (70 * t) end
        if love.keyboard.isDown("left") or love.keyboard.isDown("a") then x = x - (70 * t) end
        if love.keyboard.isDown("right") or love.keyboard.isDown("d") then x= x + (70 * t) end
        local dg = string.format("%s %s %f %f", entity, "move", x, y)
        udp:send(dg)
        t = t - updaterate
    end

    repeat
        data, msg = udp:receive()
        if data then
            world = json.decode(data)
        elseif msg ~= "timeout" then print("Unknown network error: " .. tostring(msg)) end
    until not data 
end

function love.draw()
    for k, v in pairs(world) do
        love.graphics.draw(entity_img, v.x, v.y)
    end
end

function love.quit()
    udp:send(string.format("%s %s %d %d", entity, "quit", 0, 0))
end
