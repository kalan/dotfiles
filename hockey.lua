--[[
  DISCLAIMER: SCRIPT IS PROVIDED AS IS USE AT YOUR OWN RISK!

  Save this script as "hockey.lua"
  Place this script in:
    - Windows (all users):   %ProgramFiles%\VideoLAN\VLC\lua\sd\
    - Windows (current user):   %APPDATA%\VLC\lua\sd\
    - Linux (all users):     /usr/share/vlc/lua/sd/
    - Linux (current user):  ~/.local/share/vlc/lua/sd/
    - Mac OS X (all users):  VLC.app/Contents/MacOS/share/lua/sd/
--]]

SCOREBOARD_URL = 'http://live.nhl.com/GameData/Scoreboard.json'
FEED_SOURCE_URL = 'http://smb.cdnak.neulion.com/fs/nhl/mobile/feed_new/data/streams/%s/ipad/%s_%s.json'

MILITARY_TIME=true
SHOW_LOCAL_TIME=true

SCRIPT_NAME="/r/hockey"
API_USERNAME="rhockeyvlc"
--Alternative User-Agents:
-- USER_AGENT="PS4Application libhttp/1.000 (PS4) CoreMedia libhttp/1.76 (PlayStation 4)"
USER_AGENT="Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.2; Trident/6.0; Xbox; Xbox One)"
-- USER_AGENT="iTunes-AppleTV/4.1"

json = nil
function lazy_load()
    if lazy_loaded then return nil end
    json = require "dkjson"
    json["parse_url"] = function(url)
        local string = ""
        local line = ""
        local stream = vlc.stream(url)
        repeat
            line = stream:readline()
            string = string..line
        until line ~= nil
        return json.decode(string)
    end
    lazy_loaded = true
end

function log(msg)
    vlc.msg.info("[" .. SCRIPT_NAME .. "] " .. msg)
end

function descriptor()
    return { title=SCRIPT_NAME }
end

local function get_date_parts(date_str)
  _,_,y,m,d,h,M,s=string.find(date_str, "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
  return {year=tonumber(y),month=tonumber(m),day=tonumber(d),hour=tonumber(h),min=tonumber(M),sec=tonumber(s)}
end


local function get_et_diff()
    if not SHOW_LOCAL_TIME then
        return nil
    end

    local status, et_date = pcall(get_et_date)
    if (status == false or et_date == nil) then
        vlc.msg.warn("Couldn't get ET time, showing default times: " .. et_date)
        return nil
    end
    local local_time = os.time()
    local et_time = os.time(get_date_parts(et_date))
    local diff_seconds = os.difftime(local_time, et_time)

    -- Round to closest 5mins
    local excess = diff_seconds % 300
    if (excess < 150) then
        diff_seconds = diff_seconds - excess
    else
        diff_seconds = diff_seconds + (300 - excess)
    end
    return diff_seconds
end

local function convert_to_local(datetime, diff)
    local time, local_time, local_date

    if diff == nil then
        diff = 0
    end

    time = os.time(get_date_parts(datetime))
    adjusted_time = time + diff;
    local_time = os.date(time_display_format, adjusted_time)
    local_date = os.date("%Y/%m/%d", adjusted_time)

    -- Strip leading zero from 12 hour format
    if not MILITARY_TIME then
        local_time = local_time:gsub("^0", "")
    end
    return local_time, local_date
end

local function set_time_display_format(diff)
    if MILITARY_TIME then
        time_display_format = "%H:%M"
    else
        time_display_format = "%I:%M %p"
    end
    if (diff == nil) then
        time_display_format = time_display_format .. " ET"
    end
end

local function convert_game_time_string_to_date(game_time)

    _,_,m,d,y,h,M,s=string.find(game_time, "(%d+)/(%d+)/(%d+) (%d+):(%d+):(%d+)")

    return string.format("%d-%d-%d %d:%d:%d", y, m, d, h, M, 0)
end

local function get_feed_date()
    -- Calculate date for -10:00
    local timestamp = os.time()
    -- ! gives GMT time
    local format = "%Y/%m/%d"
    -- Offset causes date to only switch over at 10am GMT
    -- which is 5am ET
    local tzoffset = -36000
    return os.date(format, timestamp + tzoffset)
end


function main()
    lazy_load()
    log("main")
    local et_diff = get_et_diff()
    set_time_display_format(et_diff)

    local todays_date = get_feed_date()
    local todays_games = {}
    local scoreboard = json.parse_url(SCOREBOARD_URL)
    for _, game in ipairs( scoreboard["games"] ) do
        local game_id, game_time, game_date, home_team, away_team, title = getInfoForGame(game, et_diff)
        if(game_date == todays_date) then
            table.insert(todays_games, game)
        end
    end


    if #(todays_games) == 0 then
        vlc.sd.add_node({path="", title="No games today."})
        return
    end

    for _, game in ipairs( todays_games ) do
        add_node_for_game(game)
    end
end

function getInfoForGame(game, et_diff)

    local game_id = game["id"]
    local game_date = convert_game_time_string_to_date(""..game["longStartTime"])
    local local_game_time, local_game_date = convert_to_local(game_date, et_diff)
    local home_team = full_name(""..game["homeTeamName"])
    local away_team = full_name(""..game["awayTeamName"])
    local title = game_id .. " " .. local_game_time .. " - " .. away_team .. " @ " .. home_team

    return game_id, local_game_time, local_game_date, home_team, away_team, title
end

function add_node_for_game_team_type(parentNode, node, prefix)
    local quality = {400, 800, 1200, 1600, 3000, 4500, 5000}

    if (node ~= nil) then
        for _, q in ipairs(quality) do
            local url = string.gsub(node, "ipad", q)
            parentNode:add_subitem({
                path = url,
                title = prefix .. ' - ' .. q .. ' kbps ',
                options = {
                    "http-user-agent=" .. USER_AGENT
                }
            })
        end
    end
end

local function add_missing_feed_node(parent_node, game, game_state)
    if game_state == 6 then
        parent_node:add_subnode({title = "Game has finished. No replay or highlights available yet."})
    else
        parent_node:add_subnode({title = "No stream available yet."})
    end
end

local function add_node_for_game_team(parentNode, node, game_state)
    local nodeAdded = false
    if (node["live"] ~= nil) then
        add_node_for_game_team_type(parentNode, node["live"]["bitrate0"], "Live")
        nodeAdded = true
    end

    if (node["vod-condensed"] ~= nil) then
        add_node_for_game_team_type(parentNode, node["vod-condensed"]["bitrate0"], "Condensed VOD")
        nodeAdded = true
    end
    if (node["vod-continuous"] ~= nil and node["vod-condensed"] ~= nil) then
        local url = string.gsub(node["vod-condensed"]["bitrate0"], "condensed", "continuous")
        add_node_for_game_team_type(parentNode, url, "Continuous VOD")
        nodeAdded = true
    end

    if(nodeAdded ~= true) then
        add_missing_feed_node(parentNode, node, game_state)
    end

end

function add_node_for_game(game)

    local game_id, game_time, game_date, home_team, away_team, title = getInfoForGame(game, et_diff)

    local parentNode = vlc.sd.add_node( { path = "", title = title } )
    local home_feed_node = parentNode:add_subnode({ title = home_team })
    local away_feed_node = parentNode:add_subnode({ title = away_team })

    local id_year = string.sub(game_id, 1, 4)
    local id_season = string.sub(game_id, 5, 6)
    local id_game = string.sub(game_id, 7, 10)

    local feed_url = string.format(FEED_SOURCE_URL, id_year, id_season, id_game)

    local streams = json.parse_url(feed_url)
    if (streams ~= nil) then
        local ipad = streams['gameStreams']['ipad']
        local game_state = streams["gameState"]

        log(game_state .." ".. game_time .." ".. game_date .." ".. home_team .." ".. away_team .." (".. title .. ")")

        local home = ipad["home"]
        local away = ipad["away"]

        if (home ~= nil) then
            add_node_for_game_team(home_feed_node, home, game_state)
        else
            add_missing_feed_node(home_feed_node, game, game_state)
        end
        if (away ~= nil) then
            add_node_for_game_team(away_feed_node, away, game_state)
        else
            add_missing_feed_node(away_feed_node, game, game_state)
        end
    else
        add_missing_feed_node(home_feed_node, game, game_state)
        add_missing_feed_node(away_feed_node, game, game_state)
    end

end

function full_name(abr)
    local all_names = {
        BOS = "Boston Bruins",
        BUF = "Buffalo Sabres",
        CGY = "Calgary Flames",
        CHI = "Chicago Blackhawks",
        DET = "Detroit Red Wings",
        EDM = "Edmonton Oilers",
        CAR = "Carolina Hurricanes",
        LAK = "Los Angeles Kings",
        MTL = "Montreal Canadiens",
        DAL = "Dallas Stars",
        NJD = "New Jersey Devils",
        NYI = "New York Islanders",
        NYR = "New York Rangers",
        PHI = "Philadelphia Flyers",
        PIT = "Pittsburgh Penguins",
        COL = "Colorado Avalanche",
        STL = "St. Louis Blues",
        TOR = "Toronto Maple Leafs",
        VAN = "Vancouver Canucks",
        WSH = "Washington Capitals",
        ARI = "Arizona Coyotes",
        SJS = "San Jose Sharks",
        OTT = "Ottawa Senators",
        TBL = "Tampa Bay Lightning",
        ANA = "Anaheim Ducks",
        FLA = "Florida Panthers",
        CBJ = "Columbus Blue Jackets",
        MIN = "Minnesota Wild",
        NSH = "Nashville Predators",
        WPG = "Winnipeg Jets"
    }
    local name = all_names[abr]
    if name == nil then
        name = abr
    end
    return(name)
end
