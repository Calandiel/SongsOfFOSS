---@class (exact) EventData
---@field name string
---@field automatic boolean Automatic events are rolled each month on every root in the game
---@field base_probability number For automatic events, controlls the base chance for an event to occur
---@field fallback fun(self:Event,associated_data:table|number|nil) Clearing up events for deleted characters
---@field trigger? fun(self:Event, root:Character):boolean A closure that returns whether or not an event will trigger
---@field on_trigger? fun(self:Event, root:Character, associated_data:table|number|nil) A function responsible for enqueuing itself in the event queue (if necessary). It's called after an event is triggered by the automatic event system (but NOT when the event is enqueued...). Associated data is set to something only if it's called by an emited action!
---@field event_text? fun(self:Event, root:Character, associated_data:table|number|nil):string Text to display with the event, for the player.
---@field event_background_path string
---@field options? fun(self:Event, root:Character, associated_data:table|number|nil):table<number,EventOption> Returns options. Keep in mind that it has to return at least one viable option. Otherwise the game will crash.


---@class (exact) Event
---@field __index Event
---@field new fun(self:Event, e:EventData):Event
---@field name string
---@field automatic boolean Automatic events are rolled each month on every root in the game
---@field base_probability number For automatic events, controlls the base chance for an event to occur
---@field fallback fun(self:Event, associated_data:table|number|nil) Clearing up events for deleted characters
---@field trigger fun(self:Event, root:Character):boolean A closure that returns whether or not an event will trigger
---@field on_trigger fun(self:Event, root:Character, associated_data:table|number|nil) A function responsible for enqueuing itself in the event queue (if necessary). It's called after an event is triggered by the automatic event system (but NOT when the event is enqueued...). Associated data is set to something only if it's called by an emited action!
---@field event_text fun(self:Event, root:Character, associated_data:table|number|nil):string Text to display with the event, for the player.
---@field event_background_path string
---@field options fun(self:Event, root:Character, associated_data:table|number|nil):table<number,EventOption> Returns options. Keep in mind that it has to return at least one viable option. Otherwise the game will crash.

---@class (exact) EventOption
---@field text string
---@field tooltip string
---@field viable fun():boolean Returns whether or not an action can be taken at all
---@field outcome fun() Applies action outcome.
---@field ai_preference fun():number Returns a number larger than 0 that represents the "weight" of the option. The AI will select the one with the highest weight.

---@class Event
local Event = {}
Event.__index = Event
---@param e EventData
---@return Event
function Event:new(e)
	if RAWS_MANAGER.do_logging then
		print("Event: " .. tostring(e.name))
	end
	---@type Event
	local o = {}

	o.name = "<event>"
	o.automatic = true
	o.base_probability = 1 / 12 / 5 -- Once every 5 years
	o.event_text = function(self, root, data)
		return "This is an event!"
	end
	o.trigger = function(self, root)
		return true
	end
	o.on_trigger = function(self, root, associated_data)
		WORLD:emit_event(self.name, root, associated_data)
	end
	o.options = function(self, root, associated_data)
		return {
			{
				text = "Default option",
				viable = function()
					return true
				end,
				outcome = function()
					print("Default event option selected!")
				end,
				ai_preference = function()
					return 1
				end
			},
			{
				text = "A special option!",
				viable = function()
					return true
				end,
				outcome = function()
					print("Special default event option selected!")
				end,
				ai_preference = function()
					return 0
				end
			}
		}
	end

	for k, v in pairs(e) do
		o[k] = v
	end
	setmetatable(o, Event)

	if RAWS_MANAGER.events_by_name[o.name] ~= nil then
		local msg = "Duplicate event (" .. tostring(o.name) .. ")"
		print(msg)
		error(msg)
	end
	RAWS_MANAGER.events_by_name[o.name] = o

	return o
end

return Event
