function SendInfobox(player, ntype, text, opts)
    if not isElement(player) then 
        return false 
    end
    triggerClientEvent(player, 'Hayees.Notify > Add', resourceRoot, ntype or 'info', tostring(text or ''), opts)
    return true
end

function SendInfoboxAll(ntype, text, opts)
    triggerClientEvent(root, 'Hayees.Notify > Add', resourceRoot, ntype or 'info', tostring(text or ''), opts)
    return true
end