local event_utils = require "game.raws.events._utils"

return function ()
	event_utils.notification_event(
		'invalid-target',
		function (self, root, associated_data)
			return "INVALID_TARGET"
		end,
		function (root, associated_data)
			return "INVALID_TARGET"
		end,
		function (root, associated_data)
			return "INVALID_TARGET"
		end
	)

	event_utils.notification_event(
		'invalid-target-remove-busy-status',
		function (self, root, associated_data)
			return "INVALID_TARGET"
		end,
		function (root, associated_data)
			return "INVALID_TARGET"
		end,
		function (root, associated_data)
			return "INVALID_TARGET"
		end,
		function (root, associated_data)
			UNSET_BUSY(root)
		end
	)
end