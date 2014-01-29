///////////////////////////////////////////////////
//
// Attract-Mode Frontend - Orbit layout
//
///////////////////////////////////////////////////
fe.layout.width = 800
fe.layout.height = 600

const MWIDTH = 300;
const MHEIGHT = 100;
const SPIN_MS = 200;

function get_y( x ) {
	return ( 225 + sqrt( pow( 270, 2 ) - pow( x - 400, 2 ) ) );
}

function set_bright( x, o ) {
	o.set_rgb( x, x, x );
}

class Marquee {
	ob=null; 
	base_io=0;
	xl=0; xm=0; xr=0; 
	sl=0.0; sm=0.0; sr=0.0;

	constructor( pio, pxl, pxm, pxr, psl, psm, psr ) {
		xl=pxl; xm=pxm; xr=pxr; sl=psl; sm=psm; sr=psr;
		ob = fe.add_artwork( "marquee" );
		ob.index_offset = base_io = pio;
		reset();
	}

	function move_left( p ) {
		local scale = ( sm - ( sm - sl ) * p );
		local nx = xm - ( xm - xl ) * p;

		ob.width = MWIDTH * scale;
		ob.height = MHEIGHT * scale;
		ob.x = nx - ob.width / 2;
		ob.y = get_y( nx ) - ob.height / 2;
		set_bright( scale * 255, ob );
	}

	function move_right( p ) {
		local scale = ( sm - ( sm - sr ) * p );
		local nx = xm + ( xr - xm ) * p;

		ob.width = MWIDTH * scale;
		ob.height = MHEIGHT * scale;
		ob.x = nx - ob.width / 2;
		ob.y = get_y( nx ) - ob.height / 2;
		set_bright( scale * 255, ob );
	}

	function reset() {
		ob.width = MWIDTH * sm;
		ob.height = MHEIGHT * sm;
		ob.x = xm - ob.width / 2;
		ob.y = get_y( xm ) - ob.height / 2;
		set_bright( sm * 255, ob );
	}
	function swap_art( o ) {
		local temp = o.ob;
		o.ob = ob;
		ob = temp;
	}
}

fe.add_artwork( "screen", 224, 59, 352, 264 );
local frame = fe.add_image( "frame.png", 220, 55, 360, 270 );

local l = fe.add_text( "[ListFilterName] [[ListEntry]/[ListSize]]", 400, 580, 400, 20 );
l.set_rgb( 180, 180, 70 );
l.align = Align.Right;

local l = fe.add_text( "[Category]", 0, 580, 400, 20 );
l.set_rgb( 180, 180, 70 );
l.align = Align.Left;

local marquees = [
	Marquee( -2, 200, 150, 145, 0.7, 0.4, 0.1 ), 
	Marquee( -1, 400, 200, 150, 1.0, 0.7, 0.4 ), 
	Marquee(  0, 600, 400, 200, 0.7, 1.0, 0.7 ),
	Marquee(  1, 650, 600, 400, 0.4, 0.7, 1.0 ),
	Marquee(  2, 655, 650, 600, 0.1, 0.4, 0.7 )
];

l = fe.add_text( "[ListTitle]", 0, 0, 800, 55 );
l.set_rgb( 180, 180, 70 ); 
l.style = Style.Bold;

l = fe.add_text( "[Title], [Manufacturer] [Year]", 0, 550, 800, 30 );
l.set_rgb( 255, 255, 255 );

fe.add_transition_callback( "orbit_transition" );

local last_move=0;

function orbit_transition( ttype, var, ttime ) {
	switch ( ttype )
	{
	case Transition.ToNewSelection:
		if ( ttime < SPIN_MS )
		{
			local moves = abs( var );
			local jump_adjust = 0;
			if ( moves > marquees.len() )
			{
				jump_adjust = moves - marquees.len();
				moves = marquees.len();
			}

			local move_duration = SPIN_MS / moves;
			local curr_move = ttime / move_duration;

			local change_index=false;
			if ( curr_move > last_move )
			{
				last_move=curr_move;
				change_index=true;
			}

			local progress = ( ttime % move_duration ).tofloat() / move_duration;

			if ( var < 0 )
			{

				if ( change_index )
				{
					// marquees[marquees.len()-1].ob will get swapped through to the leftmost position
					marquees[marquees.len()-1].ob.index_offset = marquees[0].base_io - curr_move - jump_adjust;
					for ( local i=marquees.len()-1; i>0; i-=1 )
					{
						marquees[i].swap_art( marquees[i-1] );
						marquees[i].reset();
					}
				}

				foreach ( m in marquees )
					m.move_left( progress );
			}
			else
			{
				if ( change_index )
				{
					// marquees[0].ob will get swapped through to the rightmost position
					marquees[0].ob.index_offset = marquees[marquees.len()-1].base_io + curr_move + jump_adjust;
					for ( local i=0; i<marquees.len()-1; i+=1 )
					{
						marquees[i].swap_art( marquees[i+1] );
						marquees[i].reset();
					}
				}
				foreach ( m in marquees )
					m.move_right( progress );
			}
			return true;
		}

		foreach ( m in marquees )
		{
			m.reset();
			m.ob.index_offset = m.base_io;
		}
		last_move=0;
		break;

	case Transition.StartLayout:
	case Transition.FromGame:
		if ( ttime < 255 )
		{
			foreach (o in fe.obj)
				o.alpha = ttime;

			return true;
		}
		else
		{
			foreach (o in fe.obj)
				o.alpha = 255;
		}
		break;

	case Transition.EndLayout:
	case Transition.ToGame:
		if ( ttime < 255 )
		{
			foreach (o in fe.obj)
				o.alpha = 255 - ttime;

			return true;
		}
		break;
	}

	return false;
}

fe.add_ticks_callback( "orbit_tick" );

function orbit_tick( ttime ) {
	local block = ttime / 30000;

	if ( block % 2 )
		set_bright( ( ( ttime % 30000 ) / 30000.0 ) * 255, frame );
	else
		set_bright( 255 - ( ( ttime % 30000 ) / 30000.0 ) * 255, frame );
}