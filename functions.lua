local APPROXIMATION = 0.8

equals = function(num1, num2)
	if math.abs(num1-num2) <= APPROXIMATION then
		return true
	else
		return false
	end
end

pos_equals = function(pos1, pos2)
	if pos1.x == pos2.x and pos1.y == pos2.y and pos1.z == pos2.z then
		return true
	else
		return false
	end
end
