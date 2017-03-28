local player_name = "cheapie"
local highlight_color = "#4E9A06"
local send_nick_color = "#A40000"
local send_message_color = "#888A85"
local join_color = "#CE5C00"
local part_color = "#C4A000"
local timestamps = true

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

minetest.register_on_receiving_chat_messages(function(message)
	if color and type(color.strip_colors) == "function" then
		message = color.strip_colors(message)
	end
	local msgtype
	local user
	local text
	local timestamp = ""
	if timestamps then
		local date = os.date("*t",os.time())
		timestamp = string.format("[%02d:%02d:%02d] ",date.hour,date.min,date.sec)
	end
	if string.sub(message,1,1) == "<" then
		msgtype = "channel"
		user,text = string.match(message,"^<(%g*)> (.*)$")
		if not user then
			msgtype = "special"
			text = message
		end
		if (user == player_name) or (string.match(user,"^(.*)@") == player_name) then
			msgtype = "sent_channel"
		elseif string.find(text,player_name) then
			msgtype = "highlight_channel"
		end
	elseif string.sub(message,1,3) == "***" then
		user,msgtype,text = string.match(message,"^*** (%g*) (%g*) the game. ?(.*)$")
		if not text or text == "" then
			text = "(Client Quit)"
		end
	elseif string.sub(message,1,1) == "*" then
		msgtype = "action"
		user,text = string.match(message,"^* (%g*) (.*)$")
		if not user then
			msgtype = "special"
			text = message
		end
		if (user == player_name) or (string.match(user,"^(.*)@") == player_name) then
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
		local coloredmsg = minetest.colorize(join_color,string.format("* %s has joined",user))
		minetest.display_chat_message(timestamp..coloredmsg)
	elseif msgtype == "left" then
		local coloredmsg = minetest.colorize(part_color,string.format("* %s has quit %s",user,text))
		minetest.display_chat_message(timestamp..coloredmsg)
	elseif msgtype == "channel" then
		local colorednick = minetest.colorize(get_nick_color(user),user)
		minetest.display_chat_message(timestamp..string.format("<%s> %s",colorednick,text))
	elseif msgtype == "action" then
		local colorednick = minetest.colorize(get_nick_color(user),user)
		minetest.display_chat_message(timestamp..string.format("* %s %s",colorednick,text))
	elseif msgtype == "sent_channel" then
		local colorednick = minetest.colorize(send_nick_color,user)
		local coloredtext = minetest.colorize(send_message_color,text)
		minetest.display_chat_message(timestamp..string.format("<%s> %s",colorednick,coloredtext))
	elseif msgtype == "sent_action" then
		local colorednick = minetest.colorize(send_nick_color,user)
		local coloredtext = minetest.colorize(send_message_color,text)
		minetest.display_chat_message(timestamp..string.format("* %s %s",colorednick,coloredtext))
	elseif msgtype == "highlight_channel" then
		minetest.display_chat_message(timestamp..minetest.colorize(highlight_color,string.format("<%s> %s",user,text)))
	elseif msgtype == "highlight_action" then
		minetest.display_chat_message(timestamp..minetest.colorize(highlight_color,string.format("* %s %s",user,text)))
	end
	return true
end)
