Notify = {
    server = function(player, message, type, opts)
        if not isElement(player) then 
            return false 
        end
        triggerClientEvent(player, 'Hayees.Notify > Add', resourceRoot, type or 'info', tostring(message or ''), opts)
        return true
    end;

    client = function(_, message, type, opts)
        Infobox(type or 'info', tostring(message or ''), opts)
    end;
};