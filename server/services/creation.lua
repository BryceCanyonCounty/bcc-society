RegisterServerEvent("bcc-society:InsertSocietyToDB", function(name, ownerCharId, ownerSource, taxAmount, invLimit, coords, blipHash, stages, societyJob, maxJobGrade)
    local _source = source
    local getAllSocieties = MySQL.query.await("SELECT * FROM bcc_society")
    local exist = false
    if societyJob == "" then societyJob = "none" end -- Default value setting
    if #getAllSocieties > 0 then
        for k, v in pairs(getAllSocieties) do
            if v.business_name == name then
                exist = true
                Core.NotifyRightTip(_source, _U("societyNameAlreadyExists"), 4000) break
            end
            if v.society_job == societyJob and v.society_job ~= 'none' then
                exist = true
                Core.NotifyRightTip(_source, _U("jobNameAlreadyExists"), 4000) break
            end
        end
    end
    if not exist then
        
        local creatorChar = Core.getUser(_source).getUsedCharacter
        local ownerChar = Core.getUser(ownerSource).getUsedCharacter
        local creatorName = (creatorChar.firstname or "Unknown") .. " " .. (creatorChar.lastname or "Unknown")
        local ownerName = (ownerChar.firstname or "Unknown") .. " " .. (ownerChar.lastname or "Unknown")

        if Config.employeeWorksAtMultiple then
            MySQL.query.await("INSERT INTO bcc_society (business_name, owner_id, tax_amount, inv_limit, coords, blip_hash, inventory_upgrade_stages, society_job, max_job_grade) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)", { name, ownerCharId, taxAmount, invLimit, json.encode(coords), blipHash, stages, societyJob, maxJobGrade })
            Core.NotifyRightTip(_source, _U("societyCreated"), 4000)
            local retval = MySQL.query.await("SELECT * FROM bcc_society WHERE owner_id = ? AND business_name = ?", { ownerCharId, tostring(name) })
            if #retval > 0 then
                BccUtils.Discord.sendMessage(Config.adminLogsWebhook, Config.WebhookTitle, Config.WebhookAvatar, _U("societyCreated"), _U("societyCreatedBy") .. creatorName .. _U("societyName") .. name .. _U("societyOwner") .. ownerName .. _U("societyId") .. retval[1].business_id)
                TriggerClientEvent("bcc-society:SocietyStart", tonumber(ownerSource), true, retval[1])
            end
        else
            local ownedSocieties = MySQL.query.await("SELECT * FROM bcc_society WHERE owner_id = ?", { ownerCharId })
            if #ownedSocieties > 0 then
                Core.NotifyRightTip(_source, _U("alreadyOwnSociety"), 4000)
            else
                local employedAtSocieties = MySQL.query.await("SELECT * FROM bcc_society_employees WHERE employee_id = ?", { ownerCharId })
                if #employedAtSocieties > 0 then
                    Core.NotifyRightTip(_source, _U("alreadyEmployed"), 4000)
                else
                    MySQL.query.await("INSERT INTO bcc_society (business_name, owner_id, tax_amount, inv_limit, coords, blip_hash, inventory_upgrade_stages, society_job, max_job_grade) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)", { name, ownerCharId, taxAmount, invLimit, json.encode(coords), blipHash, stages, societyJob, maxJobGrade })
                    Core.NotifyRightTip(_source, _U("societyCreated"), 4000)
                    local retval = MySQL.query.await("SELECT * FROM bcc_society WHERE owner_id = ? AND business_name = ?", { ownerCharId, tostring(name) })
                    if #retval > 0 then
                        BccUtils.Discord.sendMessage(Config.adminLogsWebhook, Config.WebhookTitle, Config.WebhookAvatar, _U("societyCreated"), _U("societyCreatedBy") .. creatorName  .. _U("societyName") .. name .. _U("societyOwner") .. ownerName .. _U("societyId") .. retval[1].business_id)
                        TriggerClientEvent("bcc-society:SocietyStart", tonumber(ownerSource), true, retval[1])
                    end
                end
            end
        end
    end
end)