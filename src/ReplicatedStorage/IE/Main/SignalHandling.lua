local module = {} --// Houses signals here

--// Returns the Signal, Type = "Audio" or "Lighting"
function module:GetSignal(Type: string, SignalName: string)
    local SignalName = Type.. SignalName

    local Signal: RBXScriptSignal = module[SignalName]

    if not Signal then
        warn(SignalName, "not found in SignalHandling")
        return
    end

    return Signal
end

return module