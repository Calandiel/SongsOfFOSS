local oi = {}

-- open issue due the original comment
function oi.waterflow_weathering_base(water_movement)
    return math.pow(water_movement, 0.333) / 10 --* NEEDS REVISION BASED ON ELEVATION CHANGE TO INFER INTENSITY OF DRAINAGE
end

return oi