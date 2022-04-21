
//the window.onload wrapper around these object constructors is just for demo purposes
//in practise you would put them in an existing load function, or use a scaleable solution:
//http://www.brothercake.com/site/resources/scripts/domready/
//http://www.brothercake.com/site/resources/scripts/onload/
window.onload = function()
{



	//initialise the docking boxes manager
	var manager = new dbxManager('icons'); 	//session ID [/-_a-zA-Z0-9/]



	//onstatechange fires when any group state changes
	manager.onstatechange = function()
	{
		//copy the state string to a local var
		var state = this.state;

		//remove group name and open/close state tokens
		state = state.replace('cute=', '').replace(/[\-\+]/g, '');

		//split into an array
		state = state.split(',');

		//iterate through the array, testing every other member
		//begin with full marks and deduct points for non-conformance
		var score = 14;
		var len = state.length;
		for(var i=0; i<len; i+=2)
		{
			//the icons might be in any order
			//but from each one we know what the next one should be
			//so deduct both points if a pair of numbers doesn't match
			if(state[i] == '0' && state[i + 1] != '7' || state[i] == '7' && state[i + 1] != '0') { score-=2; }
			if(state[i] == '1' && state[i + 1] != '9' || state[i] == '9' && state[i + 1] != '1') { score-=2; }
			if(state[i] == '2' && state[i + 1] != '11' || state[i] == '11' && state[i + 1] != '2') { score-=2; }
			if(state[i] == '3' && state[i + 1] != '13' || state[i] == '13' && state[i + 1] != '3') { score-=2; }
			if(state[i] == '8' && state[i + 1] != '4' || state[i] == '4' && state[i + 1] != '8') { score-=2; }
			if(state[i] == '5' && state[i + 1] != '10' || state[i] == '10' && state[i + 1] != '5') { score-=2; }
			if(state[i] == '6' && state[i + 1] != '12' || state[i] == '12' && state[i + 1] != '6') { score-=2; }
		}

		//output field
		var field = document.forms['events']['score'];

		//if the score is correct output the winning message
		if(score == 14)
		{
			field.value = 'Hooray! Now everyone has a friend :-)';
			field.style.fontWeight = 'bold';
		}

		//otherwise output the state data and score
		else
		{
			field.value = state + '     [' + score + '/14]';
			field.style.fontWeight = 'normal';
		}

		//return value determines whether cookie is set
		return false;
	};


	//create new docking boxes group
	var cute = new dbxGroup(
		'cute', 		// container ID [/-_a-zA-Z0-9/]
		'horizontal', 		// orientation ['vertical'|'horizontal']
		'15', 			// drag threshold ['n' pixels]
		'no',			// restrict drag movement to container axis ['yes'|'no']
		'10', 			// animate re-ordering [frames per transition, or '0' for no effect]
		'no', 			// include open/close toggle buttons ['yes'|'no']
		'', 			// default state ['open'|'closed']

		'', 			// vocabulary for "open", as in "open this box"
		'', 			// vocabulary for "close", as in "close this box"
		'click-down and drag to move this icon', // sentence for "move this box" by mouse
		'', 			// pattern-match sentence for "(open|close) this box" by mouse
		'use the arrow keys to move this icon', // sentence for "move this box" by keyboard
		'',  			// pattern-match sentence-fragment for "(open|close) this box" by keyboard
		'%mytitle%  [%dbxtitle%]' // pattern-match syntax for title-attribute conflicts
		);



};
