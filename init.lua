chat6 = {}

local player_name = "UNKNOWN"
minetest.register_on_connect(function()
	player_name = minetest.localplayer:get_name()
end)

local function default_settings()
	chat6.settings.fields.highlight_color = "#4E9A06"
	chat6.settings.fields.send_nick_color = "#A40000"
	chat6.settings.fields.send_message_color = "#888A85"
	chat6.settings.fields.join_color = "#CE5C00"
	chat6.settings.fields.part_color = "#C4A000"
	chat6.settings.fields.timestamps = "true"
	chat6.settings.fields.initialized = "true"
	chat6.storage:from_table(chat6.settings)
	minetest.display_chat_message("[chat6] Default settings loaded")
	minetest.display_chat_message("[chat6] You can edit the settings with the \".chat6\" command.")
end

local function display_settings()
	minetest.show_formspec("chat6:settings",
		"size[4,7]"..
		"label[1.25,0;chat6 Settings]"..
		"field[0.75,1;3,1;highlight;Highlight Color;"..chat6.settings.fields.highlight_color.."]"..
		"field[0.75,2;3,1;sendnick;Sent Message Nick Color;"..chat6.settings.fields.send_nick_color.."]"..
		"field[0.75,3;3,1;sendmsg;Sent Message Color;"..chat6.settings.fields.send_message_color.."]"..
		"field[0.75,4;3,1;join;Join Color;"..chat6.settings.fields.join_color.."]"..
		"field[0.75,5;3,1;part;Part Color;"..chat6.settings.fields.part_color.."]"..
		--"checkbox[0.75,5.5;timestamps;Show Timestamps;"..chat6.settings.fields.timestamps.."]"..
		"button_exit[1,6.25;2,1;save;OK]"
	)
end

chat6.storage = minetest.get_mod_storage()
chat6.settings = chat6.storage:to_table()
if chat6.settings.fields.initialized ~= "true" then
	default_settings()
end

minetest.register_chatcommand("chat6",{
	params = "",
	description = "Open the chat6 settings menu",
	func = display_settings,
})

local function validate_hex_color(color,default)
	local ret = string.match(color,"^#?(%x%x%x%x%x%x)$")
	if ret then return "#"..ret end
	minetest.display_chat_message(string.format("[chat6] \"%s\" is not a valid hex color",color))
	return default
end

minetest.register_on_formspec_input(function(formname,fields)
	if formname ~= "chat6:settings" then return false end
	if fields.save then
		print(dump(fields))
		chat6.settings.fields.highlight_color = validate_hex_color(fields.highlight,chat6.settings.fields.highlight_color)
		chat6.settings.fields.send_nick_color = validate_hex_color(fields.sendnick,chat6.settings.fields.send_nick_color)
		chat6.settings.fields.send_message_color = validate_hex_color(fields.sendmsg,chat6.settings.fields.send_message_color)
		chat6.settings.fields.join_color = validate_hex_color(fields.join,chat6.settings.fields.join_color)
		chat6.settings.fields.part_color = validate_hex_color(fields.part,chat6.settings.fields.part_color)
		--chat6.settings.fields.timestamps = (fields.timestamps and "true" or "false")
		chat6.storage:from_table(chat6.settings)	
	end
	return true
end)

local nick_colors = {
	"#4E9A06", --19
	"#CC0000", --20
	"#5C3566", --22
	"#C4A000", --24
	"#73D216", --25
	"#11A879", --26
	"#58A19D", --27
	"#57799E", --28
	"#A04265", --29
}

local function get_nick_color(nick)
	local username,extra = string.match(nick,"^(.*)@(.*)$")
	if extra then nick = username end
	local color = 0
	for i=1,string.len(nick),1 do
		color = color + string.byte(nick,i,i)
	end
	color = color % #nick_colors
	return(nick_colors[color+1])
end

minetest.register_on_receiving_chat_message(function(message)
	if color and type(color.strip_colors) == "function" then
		message = color.strip_colors(message)
	end
	local msgtype
	local user
	local text
	local timestamp = ""
	if chat6.settings.fields.timestamps == "true" then
		local date = os.date("*t",os.time())
		timestamp = string.format("[%02d:%02d:%02d] ",date.hour,date.min,date.sec)
	end
	if string.sub(message,1,1) == "<" then
		msgtype = "channel"
		user,text = string.match(message,"^<([^%c ]*)> (.*)$")
		if not user then
			msgtype = "special"
			text = message
		elseif (user == player_name) or (string.match(user,"^(.*)@") == player_name) then
			msgtype = "sent_channel"
		elseif string.find(text,player_name) then
			msgtype = "highlight_channel"
		end
	elseif string.sub(message,1,3) == "***" then
		user,msgtype,text = string.match(message,"^*** ([^%c ]*) ([^%c ]*) the game. ?(.*)$")
		if not text or text == "" then
			text = "(Client Quit)"
		end
	elseif string.sub(message,1,1) == "*" then
		msgtype = "action"
		user,text = string.match(message,"^* ([^%c ]*) (.*)$")
		if not user then
			msgtype = "special"
			text = message
		elseif (user == player_name) or (string.match(user,"^(.*)@") == player_name) then
			msgtype = "sent_action"
		elseif string.find(text,player_name) then
			msgtype = "highlight_action"
		end
	else
		msgtype = "special"
		text = message
	end
	if msgtype == "special" then
		minetest.display_chat_message(timestamp..text)
	elseif msgtype == "joined" then
		local coloredmsg = minetest.colorize(chat6.settings.fields.join_color,string.format("* %s has joined",user))
		minetest.display_chat_message(timestamp..coloredmsg)
	elseif msgtype == "left" then
		local coloredmsg = minetest.colorize(chat6.settings.fields.part_color,string.format("* %s has quit %s",user,text))
		minetest.display_chat_message(timestamp..coloredmsg)
	elseif msgtype == "channel" then
		local colorednick = minetest.colorize(get_nick_color(user),user)
		minetest.display_chat_message(timestamp..string.format("<%s> %s",colorednick,text))
	elseif msgtype == "action" then
		local colorednick = minetest.colorize(get_nick_color(user),user)
		minetest.display_chat_message(timestamp..string.format("* %s %s",colorednick,text))
	elseif msgtype == "sent_channel" then
		local colorednick = minetest.colorize(chat6.settings.fields.send_nick_color,user)
		local coloredtext = minetest.colorize(chat6.settings.fields.send_message_color,text)
		minetest.display_chat_message(timestamp..string.format("<%s> %s",colorednick,coloredtext))
	elseif msgtype == "sent_action" then
		local colorednick = minetest.colorize(chat6.settings.fields.send_nick_color,user)
		local coloredtext = minetest.colorize(chat6.settings.fields.send_message_color,text)
		minetest.display_chat_message(timestamp..string.format("* %s %s",colorednick,coloredtext))
	elseif msgtype == "highlight_channel" then
		minetest.display_chat_message(timestamp..minetest.colorize(chat6.settings.fields.highlight_color,string.format("<%s> %s",user,text)))
	elseif msgtype == "highlight_action" then
		minetest.display_chat_message(timestamp..minetest.colorize(chat6.settings.fields.highlight_color,string.format("* %s %s",user,text)))
	end
	return true
end)
