local Job = {}

---Creates a new job
---@param o job_id_data_blob_definition
---@return job_id
function Job:new(o)
	local new_id = DATA.create_job()
	DATA.setup_job(new_id, o)


	if RAWS_MANAGER.jobs_by_name[o.name] ~= nil then
		local msg = "Failed to load a job (" .. tostring(o.name) .. ")"
		print(msg)
		error(msg)
	end
	RAWS_MANAGER.jobs_by_name[o.name] = new_id
	return new_id
end

return Job
