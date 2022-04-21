/* Hosting Portal plugin */
(function($){

// ENTRY POINT
var hPortal = function(data){
		
		// Test to see if data needs to be refreshed
// ### This may need to be changed if we use the override functionality in jsCom.
		if($.isEmptyObject(data)){
			$.jsCom.json({
				sData:{
					action_get:['notifications','hosts','custs','profile']
				}
			});
			return;
		};
		
		// Updating global options and creating short reference
		var opts = hPortal.glbs = $.extend(true,{},defaults,hPortal.glbs,data||{});
		
		// Should check for mobile device?
		if(opts.checkMobi){
			
			// Check mobile type and initialize
			if(checkMobiType()){
				
				// Is mobile device, no need to continue
				return;
			};
		};
		
		// Check if page has been initialized
		if($('#hPortal').length == 0){
			
			// Giving the page a name
			document.title = 'Hosting Portal';
			
			// Giving the page a stylesheet
			$.jsCom.style({
				path:'ext/bin/hPortal/default/'
			});
			
			// Loading needed libraries
			$.jsCom.lib({
				path:'ext/lib/',
				list:[
					{name:'address'},
					{name:'jStat'},
					{name:'dataTable'}
				]
			},
			function(){
				
				// Building initial page structure
				iniPage();
				
				// Loading data into page
				loadData();
				
				// Using dataTable() for notifications
				$('#notify > table').dataTable({
					'sPaginationType':'full_numbers',
					'bAutoWidth':false
				});
			});
		}else{
			
			// Loading data into page
			loadData();
			
			// Using dataTable() plugin
			$('#notify > table').dataTable({
				'sPaginationType':'full_numbers',
				'bAutoWidth':false
			});
		};
	},
	
	// DEFAULT OPTIONS
	defaults = {
		checkMobi:true
	};

// GLOBAL OPTIONS
hPortal.glbs = {};

// PAGE INITIALIZATION
function iniPage(){
	
	// Create initial page structure
	$(document.body).empty();
	$(jCt('div',{'id':'hPortal'},[
		jCt('div',{'id':'header'},[
			jCt('div',{'id':'logo'}),
			jCt('button',{'id':'logout'},['Logout']),
			jCt('div',{'class':'float-clear'}),
			jCt('div',{'id':'error'})
		]),
		jCt('div',{'id':'content'},[

// ### Adding 'id':'custs' needs to be conditional
			jCt('div',{'id':'custs'}),
			jCt('div',{'id':'hosts'}),
			jCt('div',{'id':'service'}),
			jCt('div',{'id':'notify'}),
			jCt('div',{'class':'float-clear'})
		])
	])).appendTo(document.body);
	
	// Host click animation
	$('.host-link:not(.selected)').live('click',function(){
		$('.host-link.selected').removeClass('selected');
		$(this).addClass('selected');
		$('#service > div:visible').hide();
		$('#'+$(this).attr('rel')).show();
	});

	// Customers click function
	$('#cust-list li').live('click',function(){

// ### Would like to do this in a better way
		if(this.id == $(document.body).data('profile').cust_code){
			return;
		}
		
		// Calling datasource from server
		$.jsCom.json({
			sData:{
				action_set:'profile',
				
// ### Profile needs to be updated per unit passed, not override the entire field.
				profile:'{"cust_code":"'+this.id+'"}',
				action_get:['notifications','custs','profile','hosts']
			}
		});
	});
	
	// Logout
	$('#logout').click(function(){
		$.jsCom.json({
			sData:{
				auth:0
			}
		});
	});
};

// LOAD DATA INTO PAGE
function loadData(){
	
	// Setting reference to global options
	var opts = hPortal.glbs;
	
	// Loop through and send data subsets to individual functions. Also attaching persistant
	//  data to each given tag.
	$.each(opts,function(idx,val){
		switch(idx){
		
// ### This should extend .data(), not reset the values. Having a problem with this. Think it is to
//  do with the asynchronous events being triggered. ###
			case 'profile':
				$(document.body).data('profile',val);
				break;
			case 'notifications':
				$('#notify').data('notify',val);
				updateNotify();
				break;
			case 'hosts':
				$('#hosts').data('hosts',val);
				updateHosts();
				break;
			case 'custs':
				$('#custs').data('custs',val);
				updateCusts();
				break;
			case 'error':
				$('#error').data('error',val);
				handleError();
			default:
				break;
		};
	});
};

// UPDATE NOTIFICATIONS
function updateNotify(){
	
	// Initializing an array object, instead of literal since I know will need Array.prototype.
	var nList = new Array();
	
	// Looping through all the data
	$.each($('#notify').data('notify'),function(){
		var nStatus = '';
		
		// Checking for Notification status
		switch(String(this.status)){
			case '0':
				nStatus = 'status-up';
				break;
			case '1':
				nStatus = 'status-warn';
				break;
			case '2':
				nStatus = 'status-crit';
				break;
			case '3':
				nStatus = 'status-unknown';
				break;
			default:
				nStatus = 'status-unknown';
		};
		
		// Adding table row elements to array
		nList.push(jCt('tr',{},[
			jCt('td',{'class':nStatus,'title':nStatus},[' ']),
			jCt('td',{},[this.service_description]),
			jCt('td',{},[this.lastupdate])
		]));
	});
	
// ### Quick and dirty way to build the table. Needs to be made smooth and dynamic
	// Removing contents of notification area
	$('#notify').empty();
	
	// Putting in header and data table
	$([jCt('h1',{},['Notifications']),jCt('table',{},[
		jCt('thead',{},[
			jCt('tr',{},[
				jCt('th',{},[' ']),
				jCt('th',{},['Description']),
				jCt('th',{},['Date'])
			])
		
		// Putting in nList array to populate table rows
		]),jCt('tbody',{},nList)
	])]).appendTo('#notify');
};

// UPDATE HOST LIST
function updateHosts(){
	
	// Setting variables to track service status
	var hostItems = new Array(),
		serviceStatus = true;
	$.each($('#hosts').data('hosts'),function(idx,val){
		var hostStatus = '';
		if(String(val.host_status) == '0'){
			hostStatus = 'status-up';
		}else{
			if(String(val.host_maintenance) == '1'){
				hostStatus = 'status-maint';
			}else{
				switch(String(val.host_status)){
					case '1':
						hostStatus = 'status-warn';
						break;
					case '2':
						hostStatus = 'status-crit';
						break;
					case '3':
						hostStatus = 'status-unknown';
						break;
					default:
						hostStatus = 'status-unknown';
				};
			};
		};
		
		// Moving Host Service Details to own div
		if($('#'+idx).length == 0){
			$(jCt('div',{'id':idx,'style':'display:none;'})).appendTo('#service');
		};
		$('#'+idx).data('service',val.status_detail);
		
		// Conserving memory and removing duplicate data
		delete $('#hosts').data('hosts')[idx].status_detail;
		var serviceOverview = updateService(idx);
		
		// Creating hosts table
		hostItems.push(jCt('tr',{'class':'host-link inner-link','rel':idx},[
			jCt('td',{},[idx]),
			jCt('td',{},[val.description]),
			jCt('td',{'class':hostStatus,'title':hostStatus}),
			jCt('td',{'class':serviceOverview,'title':serviceOverview})
		]));
	});
// ### Need to fix how hosts are appended to table
	$('#hosts').empty();
	$([jCt('h1',{'id':'server-column'},['Server Status']),jCt('table',{},[
		jCt('thead',{},[
			jCt('tr',{},[
				jCt('th',{},['Hostname']),
				jCt('th',{},['Server']),
				jCt('th',{},['Host']),
				jCt('th',{},['Svc'])
			])
		]),
		jCt('tbody',{},hostItems)
	])]).appendTo('#hosts');
};

// UPDATE HOST INFORMATION
function updateService(idx){
	var data = $('#'+idx).data('service'),
		hostData = $('#hosts').data('hosts')[idx],
		serviceOverview = '',
		serviceCount = 0,
		sList = new Array();
	$.each(data,function(){
		
		// Adding logic to create service icons
		var serviceStatus = '';
		if(String(this.current_state) == '0'){
			serviceStatus = 'status-up';
		}else{
			if(String(this.scheduled_downtime_depth) == '1' || String(this.problem_has_been_acknowledged) == '1' || String(hostData.host_status) == '1'){
				serviceStatus = 'status-maint';
				serviceCount = 4;
			}else{
				switch(String(this.current_state)){
					case '1':
						serviceStatus = 'status-warn';
						serviceCount = (serviceCount < 1) ? 1 : serviceCount;
						break;
					case '2':
						serviceStatus = 'status-crit';
						serviceCount = (serviceCount < 2) ? 2 : serviceCount;
						break;
					case '3':
						serviceStatus = 'status-unknown';
						serviceCount = (serviceCount < 3) ? 3 : serviceCount;
						break;
				};
			};
		};
		
		// Check if the object already exists. If not, insert. If does, update.
		sList.push(jCt('tr',{},[
			jCt('td',{'class':serviceStatus,'title':serviceStatus}),
			jCt('td',{},[this.service_description]),
			jCt('td',{},[this.plugin_output])
		]));
	});
// ### Quick fix to replace existing host data
	$('#'+idx).empty();
	
	// Adding header and table elements to service div
	$([
		jCt('h1',{},['Host Service Details - '+idx+' ('+hostData.ip_address+')']),
		jCt('table',{},[
			jCt('thead',{},[
				jCt('tr',{},[
					jCt('th',{},[' ']),
					jCt('th',{},['Description']),
					jCt('th',{},['Output']),
				])
			]),
			jCt('tbody',{},sList)
		])
	]).appendTo('#'+idx);
	
	// Send back the service status overview
	switch(serviceCount){
		case 0:
			var serviceOverview = 'status-up';
			break;
		case 1:
			var serviceOverview = 'status-warn';
			break;
		case 2:
			var serviceOverview = 'status-crit';
			break;
		case 3:
			var serviceOverview = 'status-unknown';
			break;
		case 4:
			var serviceOverview = 'status-maint';
			break;
		default:
			var serviceOverview = 'status-crit';
	};
	return serviceOverview;
};

// UPDATE CUSTOMER LIST
function updateCusts(){
	var custList = new Array();
// ### Quick fix to remove extra cust data boxes
	$('#custs').empty();
	$.each($('#custs').data('custs'),function(idx,val){
		custList.push(jCt('li',{'id':idx},[val]));
	});
	$([
		jCt('h1',{},['Customers']),
		jCt('ul',{'id':'cust-list'},custList)
	]).appendTo('#custs');
	
};

// DISPLAY SERVER ERROR
function handleError(){
	
};


///////////////////////////////
// MOBILE FUNCTIONS/SETTINGS //
//        BEGIN HERE         //
///////////////////////////////

// CHECK IF/TYPE OF MOBILE DEVICE
function checkMobiType(){
	
	// Set var for global settings
	var opts = new Object(hPortal.glbs);
	
	// Check if mobile device
	var mDev = navigator.userAgent||navigator.vendor||window.opera;
	if(/fennec|android|avantgo|blackberry|blazer|compal|elaine|fennec|hiptop|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|mobile|o2|opera m(ob|in)i|palm( os)?|p(ixi|re)\/|plucker|pocket|psp|smartphone|symbian|treo|up\.(browser|link)|vodafone|wap|windows ce; (iemobile|ppc)|xiino/i.test(mDev)||/1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|e\-|e\/|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(di|rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|xda(\-|2|g)|yas\-|your|zeto|zte\-/i.test((mDev).substr(0,4))){
		// Is mobile, so load mobile plugin
		$.jsCom.lib({
			path:'ext/lib/',
			list:[{name:'jMobi'}]
		},
		function(){
			
			// See if the page has already been created
			if($('#hPortal').length == 0){
				// Setup the initial page structure for mobile content
				iniMobile();
			};
			
			// Call/re-initialize jMobi with all options
			$.jMobi({
				generic:{
					style:'ext/bin/hPortal/gMobile/'
				},
				mAndriod:{
					fullScreen:true,
					style:'ext/bin/hPortal/mSafari/'
				},
				mSafari:{
					fullScreen:true,
					iconGloss:false,
					iconPath:'ext/bin/hPortal/mSafari/img/iphone_icon_tomax.png',
					splashScreen:'ext/bin/hPortal/mSafari/img/iphone_loading_screen.png',
					statusBar:'black',
					style:'ext/bin/hPortal/mSafari/'
				}
			});
			
			// Parse and place data received from server
			parseMobileData();
		});
		return true;
	}else{
		return false;
	};
};

// INITIALIZE MOBILE CONTENT
function iniMobile(){
	
	// Setting page name
	document.title = 'hPortal';
	
	// Build initial structure
	$(document.body).empty();
	$(jCt('div',{'id':'hPortal'},[
		jCt('div',{'id':'main-menu'},[
			jCt('div',{'class':'toolbar'},[
				jCt('h1',['Main Menu']),
				jCt('p',{'class':'back','id':'logout-link'},['Logout']),
				jCt('a',{'class':'button link','href':'#about'},['About'])
			]),
			jCt('ul',{'class':'rounded'},[
				jCt('li',{'class':'arrow'},[
					jCt('a',{'class':'link','href':'#host'},['Hosts'])
				]),
				jCt('li',{'class':'arrow'},[
					jCt('a',{'class':'link','href':'#notify'},['Notifications'])
				])
			]),
			jCt('div',{'class':'info'},[
				jCt('div',{'class':'mini-logo'})
			])
		]),
		jCt('div',{'id':'about'},[
			jCt('div',{'class':'toolbar'},[
				jCt('h1',['About hPortal']),
				jCt('a',{'class':'back link','href':'#main-menu'},['Menu'])
			]),
			jCt('div',{'id':'about-logo'},[
				jCt('img',{'src':'ext/bin/hPortal/mSafari/img/iphone_icon_tomax.png','alt':''}),
			]),
			jCt('div',{'id':'about-text'},[
				jCt('p',['Tomax hPortal Mobile']),
				jCt('p',['Copyright (c) 2010'])
			])
		]),
		jCt('div',{'id':'host','class':'amAlive'},[
			jCt('div',{'class':'toolbar'},[
				jCt('h1',['Hosts']),
				jCt('a',{'class':'back link','href':'#main-menu'},['Menu']),
				jCt('a',{'class':'button link','href':'#host-desc'},['Desc.'])
			]),
			jCt('ul',{'class':'rounded'}),
			jCt('div',{'class':'info'},[
				jCt('div',{'class':'mini-logo'})
			])
		]),
		jCt('div',{'id':'host-desc'},[
			jCt('div',{'class':'toolbar'},[
				jCt('h1',['Description']),
				jCt('a',{'class':'back link','href':'#main-menu'},['Menu']),
				jCt('a',{'class':'button link','href':'#host'},['Name'])
			]),
			jCt('ul',{'class':'rounded'}),
			jCt('div',{'class':'info'},[
				jCt('div',{'class':'mini-logo'})
			])
		]),
		jCt('div',{'id':'service'}),
		jCt('div',{'id':'host-detail'}),
		jCt('div',{'id':'notify'},[
			jCt('div',{'class':'toolbar'},[
				jCt('h1',['Notifications']),
				jCt('a',{'class':'back link','href':'#main-menu'},['Menu'])
			]),
			jCt('ul',{'class':'sidetoside'}),
			jCt('div',{'class':'info'},[
				jCt('div',{'class':'mini-logo'})
			])
		]),
		jCt('div',{'id':'error'})
	])).appendTo('body');
	
	// Setting logout buttons
	$('#logout-link').click(function(){
		$.jsCom.json({
			sData:{
				auth:0
			}
		},
		function(){
			hPortal.glbs = {};
		});
	});
	
// ### Trying out drop link functionality here, then need to move to jMobi
	$('.drop-link').live('click',function(e){
		e.preventDefault();
		$(this).parent().next().toggle();
	});
};

// PARSE MOBILE DATA
function parseMobileData(){
	var opts = new Object(hPortal.glbs);
	$.each(opts,function(idx,val){
		switch(idx){
			case 'profile':
				$('body').data('profile',val);
				break;
			case 'notifications':
				$('#notify').data('notify',val);
				mobileNotify();
				break;
			case 'hosts':
				$('#hosts').data('hosts',val);
				mobileHost();
				break;
			case 'custs':
				$('#custs').data('custs',val);
				mobileCust();
				break;
			case 'error':
				$('#error').data('error',val);
				mobileError();
			default:
				break;
		};
	});
};

// BUILD CUSTS LIST FOR MOBILE
function mobileCust(){
	var opts = new Object(hPortal.glbs);
	
	// Checking if customer div's have been added
	if($('#cust-link').length == 0){
		$(jCt('li',{'class':'arrow','id':'cust-link'},[
			jCt('a',{'class':'link','href':'#cust'},['Customers'])
		])).prependTo('#main-menu > ul:eq(0)');
		$(jCt('div',{'id':'cust'},[
			jCt('div',{'class':'toolbar'},[
				jCt('h1',['Customers']),
				jCt('a',{'class':'back link','href':'#main-menu'},['Menu'])
			]),
			jCt('ul',{'class':'rounded'}),
			jCt('div',{'class':'info'},[
				jCt('div',{'class':'mini-logo'})
			])
		])).appendTo('#hPortal');
	};
	var cusList = new Array();
	
	// Filling in customer list
	$.each(opts.custs,function(idx,val){
		cusList.push(jCt('li',[
			jCt('a',{'href':idx,'class':'cust-link'},[val])
		]));
	});
	
	// Attaching this to customer list
	$('#cust > ul').empty();
	$(cusList).appendTo('#cust > ul');
	
	// Click on customer link
	$('.cust-link').click(function(e){
		e.preventDefault();
		
		// Saving customer name
		var custName = $(this).text();
		if($(this).attr('href') == opts.profile.cust_code){
// ### Not the greatest way to direct views
			$('a[href=#host]:eq(0)').click();
			return;
		};
		
		// Setting loading screen
		$(jCt('div',{
			'id':'loading-screen',
			'style':'background-color: white; position: fixed; top: 0; left: 0; width: '+window.innerWidth+'px; height: 9999px; z-index: 999;'
		},[
			jCt('div',{'id':'loading-img'}),
			jCt('h3',{'style':'text-align: center;'},['Loading Customer '+custName])
		])).appendTo(document.body);
		
		// Doing some cleanup
		hPortal.glbs = {};
		$('#service').empty();
		$('#host-detail').empty();
		$('#host-desc > ul:eq(0)').empty();
		$('#host > ul:eq(0)').empty();
		var $this = $(this);
		
		// Getting data from server
		$.jsCom.json({
			sData:{
				action_set:'profile',
				profile:$.toJSON({cust_code:$this.attr('href')}),
				action_get:['notifications','custs','profile','hosts']
			}
		},
		function(){
			
			// Removing loading screen
			$('#loading-screen').remove();
// ### Redirect to host list, but not well done
			$('a[href=#host]:eq(0)').click();
		});
	});
};

// BUILD HOSTS for MOBILE
function mobileHost(){
	var opts = hPortal.glbs,
		hoList = new Array(),
		descList = new Array();
	
	// Loop through each host
	$.each(opts.hosts,function(idx,val){
		var servNum = val.status_detail.length
		
		// Create host service info if doesn't exist
		if($('#'+idx).length == 0){
			$(jCt('div',{'id':idx},[
				jCt('div',{'class':'toolbar'},[
					jCt('h1',['Service Status']),
					jCt('a',{'class':'back link','href':'#host'},['Hosts']),
					jCt('a',{'class':'button link','href':'#'+idx+'-detail'},['Details'])
				]),
				jCt('ul',{'class':'sidetoside'}),
				jCt('div',{'class':'info'},[
					jCt('div',{'class':'mini-logo'})
				])
			])).appendTo('#service');
		};
		
		// Create host details if doesn't exist
		if($('#'+idx+'-detail').length == 0){
			$(jCt('div',{'id':idx+'-detail'},[
				jCt('div',{'class':'toolbar'},[
					jCt('h1',['Host Details']),
					jCt('a',{'class':'back link','href':'#host'},['Hosts']),
					jCt('a',{'class':'button link','href':'#'+idx},['Service'])
				]),
				jCt('div',[
					jCt('p',['Description: '+val.description]),
					jCt('p',['Host Name: '+val.hostname]),
					jCt('p',['IP Address: '+val.ip_address])
				]),
				jCt('div',{'class':'info'},[
					jCt('div',{'class':'mini-logo'})
				])
			])).appendTo('#host-detail');
		};
		
		// Building service list and returning service overview status
		var hText = mobileService(idx);
		
		// Attaching host name to array
		hoList.push(jCt('li',[
			jCt('a',{'class':'link','href':'#'+idx},[
				idx,
				jCt('span',{
					'style':'border: 2px solid #CCC; float: right; padding: 2px; -webkit-border-radius: 4px; background-color: white;'
				},[' '])
			])
		]));
		
		// Attaching host description to array
		descList.push(jCt('li',[
			jCt('a',{'class':'link','href':'#'+idx},[
				val.description,
				jCt('span',{
					'style':'border: 2px solid #CCC; float: right; padding: 2px; -webkit-border-radius: 4px; background-color: white;'
				},[' '])
			])
		]));
		
		// Appending arrays to host name and description
		$(hoList).appendTo('#host > ul:eq(0)');
		$(descList).appendTo('#host-desc > ul:eq(0)');
	});
};

// BUILD SERVICES for MOBILE
function mobileService(idx){
	var opts = hPortal.glbs,
		seList = new Array(),
		hVal = 0;
	
	// Inserting host service information
	$.each(opts.hosts[idx].status_detail,function(idx,val){
		var sText = '';
		switch(val.current_state){
			case '0':
				sText = 'stat-ok';
				break;
			case '1':
				sText = 'stat-warn';
				hVal = (hVal < 1) ? 1 : hVal;
				break;
			case '2':
				sText = 'stat-crit';
				hVal = (hVal < 2) ? 2 : hVal;
				break;
			case '4':
				sText = 'stat-maint';
				break;
			default:
				sText = 'stat-unknown';
		};
		seList.push([
			jCt('li',{'class':sText+' arrow'},[
				jCt('a',{'href':'#','class':'drop-link'},[val.service_description])
			]),
			jCt('li',{'style':'display: none;','class':'drop-info'},[
				jCt('p',[val.plugin_output])
			])
		]);
	});
	$(seList).appendTo('#'+idx+' > ul:eq(0)');
	switch(String(hVal)){
		case '0':
			return 'stat-ok';
		case '1':
			return 'stat-warn';
		case '2':
			return 'stat-crit';
		default:
			return 'stat-unknown';
	};
};

// BUILD NOTIFICATIONS for MOBILE
function mobileNotify(){
	var opts = new Object(hPortal.glbs.notifications);
	var noList = new Array();
	var sText = '';

// ### Only displaying first 10 notifications. Need to build in ability to view additional.
	for(var ct=0;ct<10;ct++){
		switch(opts[ct].status){
			case '0':
				sText = 'stat-ok';
				break;
			case '1':
				sText = 'stat-warn';
				break;
			case '2':
				sText = 'stat-crit';
				break;
			case '4':
				sText = 'stat-maint';
				break;
			default:
				sText = 'stat-unknown';
		};
		noList.push(jCt('li',{'class':sText},[
			jCt('p',[opts[ct].service_description]),
			jCt('p',[opts[ct].plugin_output]),
			jCt('p',[opts[ct].lastupdate])
		]));
	};
	$('#notify > ul:eq(0)').empty();
	$(noList).appendTo('#notify > ul:eq(0)');
};

// HANDLE MOBILE ERROR
function mobileError(){
	var opts = hPortal.glbs;
	
};

// Exposing to jQuery object
$.hPortal = hPortal;

})(jQuery);