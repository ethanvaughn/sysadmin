
//the window.onload wrapper around these object constructors is just for demo purposes
//in practise you would put them in an existing load function, or use a scaleable solution:
//http://www.brothercake.com/site/resources/scripts/domready/
//http://www.brothercake.com/site/resources/scripts/onload/
window.onload = function()
{



	//initialise the docking boxes manager
	var manager = new dbxManager('main'); 	//session ID [/-_a-zA-Z0-9/]



	//onstatechange fires when any group state changes
	manager.onstatechange = function()
	{
		//the box order and state string for all groups
		document.forms['events']['state'].value = this.state + '   [' + Math.random() + ']';

		//the session id
		document.forms['events']['sid'].value = this.sid + '   [' + Math.random() + ']';


		//return value determines whether cookie is set
		return true;
	};


	//ondrag fires while the mouse drags a box, or when the keyboard initiates a move
	manager.onboxdrag = function()
	{
		//the group container element
		document.forms['events']['drag-group'].value = this.group + '   [' + Math.random() + ']';

		//the box element
		document.forms['events']['drag-box'].value = this.box + '   [' + Math.random() + ']';

		//the window event
		document.forms['events']['drag-event'].value = this.event + '   [' + Math.random() + ']';


		//return value determines whether the operation is allowed
		return true;
	};


	//onopen fires when a box is opened
	manager.onboxopen = function()
	{
		//the group container element
		document.forms['events']['open-group'].value = this.group + '   [' + Math.random() + ']';

		//the box element
		document.forms['events']['open-box'].value = this.box + '   [' + Math.random() + ']';

		//the toggle button
		document.forms['events']['open-toggle'].value = this.toggle + '   [' + Math.random() + ']';


		//return value determines whether the operation is allowed
		return true;
	};


	//onopen fires when a box is closed
	manager.onboxclose = function()
	{
		//the group container element
		document.forms['events']['close-group'].value = this.group + '   [' + Math.random() + ']';

		//the box element
		document.forms['events']['close-box'].value = this.box + '   [' + Math.random() + ']';

		//the toggle button
		document.forms['events']['close-toggle'].value = this.toggle + '   [' + Math.random() + ']';


		//return value determines whether the operation is allowed
		return true;
	};



	//create new docking boxes group
	var servers= new dbxGroup(
		'dbx-group', 		// container ID [/-_a-zA-Z0-9/]
		'vertical', 		// orientation ['vertical'|'horizontal']
		'7', 			// drag threshold ['n' pixels]
		'yes',			// restrict drag movement to container axis ['yes'|'no']
		'5', 			// animate re-ordering [frames per transition, or '0' for no effect]
		'yes', 			// include open/close toggle buttons ['yes'|'no']
		'open', 		// default state ['open'|'closed']

		'open', 		// word for "open", as in "open this box"
		'close', 		// word for "close", as in "close this box"
		'click-down and drag to move this box', // sentence for "move this box" by mouse
		'click to %toggle% this box', // pattern-match sentence for "(open|close) this box" by mouse
		'use the arrow keys to move this box', // sentence for "move this box" by keyboard
		', or press the enter key to %toggle% it',  // pattern-match sentence-fragment for "(open|close) this box" by keyboard
		'%mytitle%  [%dbxtitle%]' // pattern-match syntax for title-attribute conflicts
		);



};
