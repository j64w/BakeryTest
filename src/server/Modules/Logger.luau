-- src/server/Modules/Logger.luau
local Logger = {}
local HttpService = game:GetService("HttpService")

local LOG_LEVELS = {
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4,
}

local CURRENT_LEVEL = LOG_LEVELS.DEBUG

function Logger:Log(level, message, data)
    if level < CURRENT_LEVEL then return end
    
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local logEntry = {
        timestamp = timestamp,
        level = level,
        message = message,
        data = data,
    }
    
    -- Imprimir en consola
    print("[" .. timestamp .. "] " .. message)
    if data then
        print(HttpService:JSONEncode(data))
    end
    
    -- Aquí podrías enviar a un webhook de Discord o servicio externo
end

function Logger:Debug(message, data) self:Log(LOG_LEVELS.DEBUG, message, data) end
function Logger:Info(message, data) self:Log(LOG_LEVELS.INFO, message, data) end
function Logger:Warn(message, data) self:Log(LOG_LEVELS.WARN, message, data) end
function Logger:Error(message, data) self:Log(LOG_LEVELS.ERROR, message, data) end

return Logger