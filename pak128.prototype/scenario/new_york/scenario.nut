/**
 * New York City scenario
 */

/// version of script
version <- 2
// version 0: initial
// version 1: corrected forbidden tools on hudson river
// version 2: new savegame, jfk airport moved

/// specify the savegame to load
map.file = "new_york.sve"

/// short description to be shown in finance window
/// and in standard implementation of get_about_text
scenario.short_description = "New York"

scenario.author = "ny911 (scripting by Dwachs)"
scenario.version = "0." + (version + 1)


function get_info_text(pl)
{
	return ttextfile("info.txt")
}

function get_rule_text(pl)
{
	return ttextfile("rule.txt")
}

function get_goal_text(pl)
{
	return ttextfile("goal.txt")
}

function get_result_text(pl)
{
	local text1 = ttext("You satisfied the demand for transporting passengers in Midtown up to {ratio}%.")
	text1.ratio = get_pax_ratio()

	local text2 = ttext("You provided service to {airports} airports.")
	text2.airports = get_served_airports()
	local text3 = has_hq(pl) ? ttext("You build a luxurious headquarter.")
	                         : ttext("You did not build a headquarter yet. Go earn more money.")

	return text1.tostring() + "<br><br>" + text2.tostring() + "<br><br>" + text3.tostring()
}

city_midtown <- null

// just save positions
// halt handles might get invalid, if player makes own halt public
airports <- {
	jfk = { /* will be set in resume_game to persistent.jfk */ }
	lag = { pos = [601, 265] }
	new = { pos = [207, 731] }
	tet = { pos = [162, 283] }
}

/// stores version of script, init with default 0
persistent.version <- 0

function start()
{
	forbid_tools_on_hudson()

	persistent.version = version
	persistent.jfk    <- { pos = [968, 494] }

	resume_game()
}

function sum(a,b)
{
	return a+b
}

function has_hq(pl)
{
	// headquarters
	local pos = player_x(pl).headquarter_pos
	return (pos.x >= 0)
}

function get_served_airports()
{
	local served = 0
	foreach(airp in airports) {
		local halt = square_x( airp.pos[0], airp.pos[1] ).get_ground_tile().get_halt()
		local flying_pax = halt.happy.reduce( sum )
		if (flying_pax > 0) {
			served ++
		}
	}
	return served
}

function get_pax_ratio()
{
	local pax_generated = city_midtown.generated_pax.reduce(sum)
	local pax_transported = city_midtown.transported_pax.reduce(sum)
	return (pax_transported*100) / pax_generated
}

function is_scenario_completed(pl)
{
	local percentage = 0
	// transported passengers in midtown
	percentage = min( get_pax_ratio(), 95 )
	// headquarter
	if (has_hq(pl)) percentage ++
	// airports
	percentage += get_served_airports() // this gives max 4%
	return percentage
}

function resume_game()
{
	// check for script version
	if ( !("version" in persistent) ){
		persistent.version <- 0
	}
	// update forbidden tools if necessary
	if ( persistent.version < version ) {
		if (persistent.version==0) {
			update_v0_to_v1()
		}
		if (persistent.version==1) {
			update_v1_to_v2()
		}
	}
	persistent.version = version

	// position of jfk airport
	airports.jfk = persistent.jfk

	city_midtown = city_x(398, 421)

	// correct settings of savegame: no industries will be created
	settings.set_industry_increase_every(0)
}


governors_island <- { x1=418, x2=437, y1=617, y2=650 }

// no bridge across any of these tiles
hudson_river <- [
	{x=390, y=617},
	{x=373, y=532},
	{x=350, y=512},
	{x=371, y=497},
	{x=345, y=488},
	{x=340, y=333},
	{x=326, y=133},
	{x=308, y=0}
]

tools_not_allowed_on_hudson <- [tool_build_bridge, tool_build_tunnel, tool_raise_land, tool_setslope]
error_hudson <- [
	"No new bridge allowed across Hudson River.",
	"No new tunnel allowed under Hudson River.",
	"No terraforming allowed on Hudson River. It would destroy the legendary view.",
	"No terraforming allowed across Hudson River. The mayor does not like to view ledgers from his office."
]

function forbid_tools_on_hudson()
{
	for(local j=0; j<tools_not_allowed_on_hudson.len(); j++) {
			for(local i=0; i<hudson_river.len()-1; i++) {
				rules.forbid_way_tool_rect(player_all, tools_not_allowed_on_hudson[j], wt_all, hudson_river[i], hudson_river[i+1], ttext(error_hudson[j]))
			}
	}
}

function is_work_allowed_here(pl, tool_id, pos, tool)
{
	// headquarter only on governors island
	if (tool_id == tool_headquarter) {
		if (pos.x<governors_island.x1  ||  governors_island.x2<pos.x || pos.y<governors_island.y1  ||  governors_island.y2<pos.y) {
			return ttext("According to the contract with the city, you have to build your headquarter on Governors Island.")
		}
		return null
	}
	return null // null is equivalent to 'allowed'
}

// ----------- compatibility code follows --------------------------------------------------
// version 0 of scenario had different forbidden rectangles
hudson_river_compatibility <- [
	[ // version 0
		{x=393, y=617},
		{x=382, y=532},
		{x=345, y=488},
		{x=340, y=333},
		{x=326, y=133},
		{x=308, y=0}
	]
]

// update forbidden tools
function update_v0_to_v1()
{
	local old_hudson_river = hudson_river_compatibility[ persistent.version ]
	local pl_list = [0, player_all]

	for(local j=0; j<tools_not_allowed_on_hudson.len(); j++) {
		foreach(pl in pl_list) {
			for(local i=0; i<old_hudson_river.len()-1; i++) {
				rules.allow_way_tool_rect(pl, tools_not_allowed_on_hudson[j], wt_all, old_hudson_river[i], old_hudson_river[i+1])
			}
		}
	}
	forbid_tools_on_hudson()
	persistent.version = 1;
}

// set position of jfk airport (old start savegame)
function update_v1_to_v2()
{
	persistent.jfk <- { pos = [961, 494] }
	persistent.version = 2;
}
