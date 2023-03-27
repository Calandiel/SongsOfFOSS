local sun = {}

--[[ --  From old C# code:
public static float GetYearlyIrradiance(float colatitude)
{
	/// (L - 0)(L - pi) ~ approx sin
	/// See: https://upload.wikimedia.org/wikipedia/commons/7/78/Insolation.png
	// TODO: vary it based on cloud cover
	return math.max(0.0f, (-1.0f) * colatitude * (colatitude - 3.1415f) + 1.7f);
}
--]]
function sun.yearly_irradiance(latitude_in_degrees)

	local colatitude = 3.1415 * 0.5 * (90.0 - latitude_in_degrees) / 90.0

	local ret = -colatitude * (colatitude - 3.1415) + 1.7

	if ret > 0.0 then
		return ret
	else
		return 0.0
	end
end

return sun
