---@class PermissionSystem
local PermissionSystem = {}
local groups = {}
local permissionList = {}

function PermissionSystem:CreateGroup(name, startPermissions)
    if groups[name] then
        return false
    end

    local res = exports.oxmysql:insert_async('INSERT INTO groups (name, permissions, inherits) VALUES (?, ?, ?)',
        { name, json.encode(startPermissions or {}), json.encode({}) })

    for _, v in ipairs(startPermissions or {}) do
        ExecuteCommand(('add_ace %s %s allow'):format(name, v))
        table.insert(permissionList, v)
    end

    if res then
        groups[name] = { permissions = startPermissions or {}, inheriets = {} }
        return true
    else
        return false
    end
end

function PermissionSystem:AddPermissionToGroup(group, permission)
    if not groups[group] then
        return false
    end

    table.insert(groups[group].permissions, permission)

    exports.oxmysql:insert_async('UPDATE groups SET permissions = ? WHERE name = ?',
        { json.encode(groups[group].permissions), group })


    table.insert(permissionList, permission)

    ExecuteCommand(('add_ace %s %s allow'):format(group, permission))

    return true
end

function PermissionSystem:AddPermissionsToGroup(group, permissions)
    if not groups[group] then
        return false
    end

    for _, v in ipairs(permissions) do
        table.insert(groups[group].permissions, v)
        ExecuteCommand(('add_ace %s %s allow'):format(group, v))
        table.insert(permissionList, v)
    end

    exports.oxmysql:insert_async('UPDATE groups SET permissions = ? WHERE name = ?',
        { json.encode(groups[group].permissions), group })

    return true
end

function PermissionSystem:RemovePermissionFromGroup(group, permission)
    if not groups[group] then
        return false
    end

    for k, v in ipairs(groups[group].permissions) do
        if v == permission then
            table.remove(groups[group].permissions, k)
            break
        end
    end

    exports.oxmysql:insert_async('UPDATE groups SET permissions = ? WHERE name = ?',
        { json.encode(groups[group].permissions), group })

    ExecuteCommand(('remove_ace %s %s allow'):format(group, permission))

    return true
end

function PermissionSystem:RemovePermissionsFromGroup(group, permissions)
    if not groups[group] then
        return false
    end

    for _, v in ipairs(permissions) do
        for k, v2 in ipairs(groups[group].permissions) do
            if v2 == v then
                table.remove(groups[group].permissions, k)
                break
            end
        end

        ExecuteCommand(('remove_ace %s %s allow'):format(group, v))
    end

    exports.oxmysql:insert_async('UPDATE groups SET permissions = ? WHERE name = ?',
        { json.encode(groups[group].permissions), group })

    return true
end

function PermissionSystem:AddInheriet(group, inheriet)
    if not groups[group] then
        return false
    end

    table.insert(groups[group].inheriets, inheriet)

    exports.oxmysql:insert_async('UPDATE groups SET inherits = ? WHERE name = ?',
        { json.encode(groups[group].inheriets), group })

    ExecuteCommand(('add_principal %s %s'):format(group, inheriet))

    return true
end

function PermissionSystem:RemoveInheriet(group, inheriet)
    if not groups[group] then
        return false
    end

    for k, v in ipairs(groups[group].inheriets) do
        if v == inheriet then
            table.remove(groups[group].inheriets, k)
            break
        end
    end

    exports.oxmysql:insert_async('UPDATE groups SET inherits = ? WHERE name = ?',
        { json.encode(groups[group].inheriets), group })

    ExecuteCommand(('remove_principal %s %s'):format(group, inheriet))

    return true
end

function PermissionSystem:SetUserGroup(userId, group)
    if not groups[group] then
        return false
    end

    local player = exports.wxs_framework:GetPlayerByUserId(userId)
    local identifer = GetPlayerIdentifierByType(player.source, 'license2')

    if not player then
        return false
    end

    local currentGroup = player.userData.group

    if currentGroup then
        ExecuteCommand(('remove_principal identifer.%s %s'):format(identifer, currentGroup))
    end

    ExecuteCommand(('add_principal identifer.%s %s'):format(identifer, group))

    player.userData.group = group

    exports.oxmysql:insert_async('UPDATE users SET group = ? WHERE id = ?', { group, userId })
end

function PermissionSystem:FetchSavedGroups()
    exports.oxmysql:fetch('SELECT * FROM groups', {}, function(results)
        for k, v in ipairs(results) do
            local perms = json.decode(v.permissions)
            local inhrs = json.decode(v.inherits)

            for _, v2 in ipairs(perms or {}) do
                ExecuteCommand(('add_ace %s %s allow'):format(v.name, v2))
                table.insert(permissionList, v2)
            end

            for _, v2 in ipairs(inhrs or {}) do
                ExecuteCommand(('add_principal %s %s'):format(v.name, v2))
            end

            groups[v.name] = { permissions = perms, inheriets = inhrs }
        end
    end)
end

AddEventHandler("WXS:Server:UserJoined", function(playerData)
    if playerData.userData.id == 1 and playerData.isNew then
        PermissionSystem:CreateGroup(GeneralConfig.ManagementGroup, {
            "command"
        })
    end
end)

return PermissionSystem
