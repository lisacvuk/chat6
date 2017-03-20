chat6 = {}
chat6.message_normal = "normal"
chat6.message_action = "action"
chat6.message_private = "private"

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
	local color = 0
	for i=1,string.len(nick),1 do
		color = color + string.byte(string.sub(nick,i,i))
	end
	color = color % #nick_colors
	return(nick_colors[color+1])
end

function chat6.send_colored_message(fromname,msg,toname,msgtype)
	if msgtype == chat6.message_private then
		local highlight = minetest.setting_get("chat6.highlight_color") or "#4E9A06"
		if (not toname) or (not msg) then
			minetest.chat_send_player(fromname,minetest.colorize("#FF0000","Error")..": Player name or message missing")
			return false
		end
		if not minetest.get_player_by_name(toname) then
			minetest.chat_send_player(fromname,minetest.colorize("#FF0000","Error")..": Target player is not online")
			return false
		end
		local colorednick = minetest.colorize(highlight,fromname)
		local coloredmessage = minetest.colorize(highlight,message)
		minetest.chat_send_player(fromname,"Message sent.")
		minetest.chat_send_player(toname,string.format("PM from %s: %s",fromname,coloredmessage))
	elseif msgtype == chat6.message_action then
		local outgoingnick = minetest.setting_get("chat6.outgoing_nick_color") or "#CC0000"
		local outgoingmsg = minetest.setting_get("chat6.outgoing_message_color") or "#CCCCCC"
		local highlight = minetest.setting_get("chat6.highlight_color") or "#4E9A06"
		local players = minetest.get_connected_players()
		for _,player in pairs(players) do
			local toname = player:get_player_name()
			if toname == fromname then
				local colorednick = minetest.colorize(outgoingnick,fromname)
				local coloredmessage = minetest.colorize(outgoingmsg,msg)
				minetest.chat_send_player(toname,string.format("* %s %s",colorednick,coloredmessage))
			elseif string.find(msg,toname) then
				local colorednick = minetest.colorize(highlight,fromname)
				local coloredmessage = minetest.colorize(highlight,msg)
				minetest.chat_send_player(toname,string.format("* %s %s",colorednick,coloredmessage))
			else
				local colorednick = minetest.colorize(get_nick_color(fromname),fromname)
				minetest.chat_send_player(toname,string.format("* %s %s",colorednick,msg))
			end
		end
	else
		local outgoingnick = minetest.setting_get("chat6.outgoing_nick_color") or "#CC0000"
		local outgoingmsg = minetest.setting_get("chat6.outgoing_message_color") or "#CCCCCC"
		local highlight = minetest.setting_get("chat6.highlight_color") or "#4E9A06"
		local players = minetest.get_connected_players()
		for _,player in pairs(players) do
			local toname = player:get_player_name()
			if toname == fromname then
				local colorednick = minetest.colorize(outgoingnick,fromname)
				local coloredmessage = minetest.colorize(outgoingmsg,msg)
				minetest.chat_send_player(toname,string.format("<%s> %s",colorednick,coloredmessage))
			elseif string.find(msg,toname) then
				local colorednick = minetest.colorize(highlight,fromname)
				local coloredmessage = minetest.colorize(highlight,msg)
				minetest.chat_send_player(toname,string.format("<%s> %s",colorednick,coloredmessage))
			else
				local colorednick = minetest.colorize(get_nick_color(fromname),fromname)
				minetest.chat_send_player(toname,string.format("<%s> %s",colorednick,msg))
			end
		end
	end
end

minetest.register_on_chat_message(function(fromname,msg)
	if string.sub(msg,1,1) == "/" then
		return false
	end
	chat6.send_colored_message(fromname,msg,nil,chat6.message_normal)
	if minetest.get_modpath("irc") then
		irc:say(string.format("<%s> %s",fromname,msg))
	end
	return true
end)

minetest.override_chatcommand("me",{func=function(fromname,msg)
	chat6.send_colored_message(fromname,msg,nil,chat6.message_action)
	if minetest.get_modpath("irc") then
		irc:say(string.format("* %s %s",fromname,msg))
	end
	return true
end})

minetest.override_chatcommand("msg",{func=function(fromname,msg)
	local toname, message = msg:match("^(%S+)%s(.+)$")
	chat6.send_colored_message(fromname,message,toname,chat6.message_private)
	return true
end})
