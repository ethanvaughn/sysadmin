/* Login Plugin
 ***************/
(function($){

// ENTRY POINT
var loginPage = function(data){
		
		// Store browser agent
		var mDev = navigator.userAgent||navigator.vendor||window.opera;
		
		// Checking if plugin wrapper exists
		if($('#loginPage').length === 0){
			
			// Preping and adding plugin wrapper
			$(document.body).empty();
			$(jCt('div',{'id':'loginPage'})).appendTo(document.body);
			$('#loginPage').data('iniPage',true);
		};
		
		// Extending data set
		$('#loginPage').data($.extend(true,{},defaults,$('#loginPage').data()||{},data));
		
		// Check for Mobile Device
		if($('#loginPage').data().checkMobi && /fennec|android|avantgo|blackberry|blazer|compal|elaine|fennec|hiptop|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|mobile|o2|opera m(ob|in)i|palm( os)?|p(ixi|re)\/|plucker|pocket|psp|smartphone|symbian|treo|up\.(browser|link)|vodafone|wap|windows ce; (iemobile|ppc)|xiino/i.test(mDev)||/1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|e\-|e\/|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(di|rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|xda(\-|2|g)|yas\-|your|zeto|zte\-/i.test((mDev).substr(0,4))){
			loadIsMobi();
		}else{
			loadNotMobi();
		};
	},

	// DEFAULTS
	defaults = {
		checkMobi:true
	};

// NOT MOBILE PREP
function loadNotMobi(){
	
	// Setting opts
	var opts = $('#loginPage').data();
	
	// Give page a name
	document.title = 'Login Page';
	
	// Get stylesheet
	// jsCom will auto-detect if style is loaded, and still run callback afterwards
	$.jsCom.style({
		path:'ext/bin/loginPage/default/'
	},
	function(){
		if($('#loginPage').data('iniPage')){
			
			// Initializing page structure
			iniPage();
		};
		
		// Parsing returned data
		$.each(opts,function(idx,val){
			if(idx == 'error'){
				displayError(val);
			};
		});
	});
};

// BUILD NORMAL PAGE
function iniPage(){
	
	// Create login elements
	$(jCt('form',{'id':'login-form'},[
		jCt('div',{'id':'username-div'},[
			jCt('label',{'id':'username'},['Username : ']),
			jCt('input',{'id':'username-input','name':'username-input','type':'text','value':''})
		]),
		jCt('div',{'id':'password-div'},[
			jCt('label',{'id':'password'},['Password : ']),
			jCt('input',{'id':'password-input','name':'password-input','type':'password','value':''})
		]),
		jCt('input',{'id':'login-submit','type':'submit','value':'Log In'})
	])).appendTo('#loginPage');
	
	// Giving focus to username text field
	$('#username-input').focus();
	
	// Creating login submission form
	$('#login-submit').click(function(e){
		e.preventDefault();
		
		// Making call to server
		$.jsCom.json({
			sData:{
				auth:1,
				password:$('#password-input').attr('value'),
				username:$('#username-input').attr('value')
			}
		});
	});
	
	// Changing initialization parameter
	$('#loginPage').data('iniPage',false);
};

// DISPLAY ERROR MESSAGE
function displayError(val){
	if($('#error-msg').length === 0){
		$(jCt('div',{'id':'error-msg'})).appendTo('#loginPage');
	};
	$('#error-msg').html(val.msg);
	
// ### Manually setting styles. Should be placed in stylesheet once finalized.
	$('#password-input').attr('value','').css({
		'border':'1px solid #981D26',
		'background-color':'#F4A2A8'
	}).focus();
};


///////////////////////////////
// MOBILE FUNCTIONS/SETTINGS //
//        BEGIN HERE         //
///////////////////////////////

// CHECK MOBILE TYPE
function loadIsMobi(){
	
	// Load mobile plugin
	$.jsCom.lib({
		path:'ext/lib/',
		list:[{name:'jMobi'}]
	},
	function(){
		
		// See if the page has already been created
		if($('#loginPage').data('iniPage')){
			
			// Setup the initial page structure for mobile content
			iniMobile();
			
			// Call/re-initialize jMobi with all options
			$.jMobi({
				generic:{
					style:'ext/bin/loginPage/gMobile/'
				},
				mAndriod:{
					fullScreen:true,
					style:'ext/bin/loginPage/mSafari/'
				},
				mSafari:{
					fullScreen:true,
					iconGloss:false,
					iconPath:'ext/bin/loginPage/mSafari/img/iphone_icon_tomax.png',
					splashScreen:'ext/bin/loginPage/mSafari/img/iphone_loading_screen.png',
					statusBar:'black',
					style:'ext/bin/loginPage/mSafari/'
				}
			});
		};
		
		// Parse and place data received from server
		parseMobiData();
	});
};

// BUILD MOBILE PAGE
function iniMobile(){
	
	// Give page title
	document.title = 'hPortal';
	
	// Creating main structure
	$([
		jCt('div',{'class':'toolbar'},[
			jCt('h1',['hPortal Login'])
		]),
		jCt('div',{'id':'error'}),
		jCt('form',{'id':'login-form'},[
			jCt('ul',{'class':'form'},[
				jCt('li',[
					jCt('input',{'id':'username-input','type':'text'})
				]),
				jCt('li',[
					jCt('input',{'id':'password-input','type':'password'})
				])
			]),
			jCt('input',{'type':'submit','value':'Submit'})
		]),
		jCt('div',{'class':'info'},[
			jCt('div',{'class':'mini-logo'})
		])
	]).appendTo('#loginPage');
	
	// Handle Form Submit
	$('#login-form').bind('submit',function(e){
		e.preventDefault();
		$.jsCom.json({
			sData:{
				auth:1,
				password:$('#password-input').attr('value'),
				username:$('#username-input').attr('value')
			}
		});
	});
	
	// Setting page initialization value
	$('#loginPage').data('iniPage',false);
};

// PARSE MOBILE DATA
function parseMobiData(){
	
	// Setting opts
	var opts = $('#loginPage').data();
	
	// Parsing returned data
	$.each(opts,function(idx,val){
		if(idx == 'error'){
			displayMobileError(val);
		};
	});
};

// DISPLAY MOBILE ERROR MESSAGE
function displayMobileError(val){
	$('#error').empty();
	$(jCt('p',[val.msg])).appendTo('#error');
	$('#password-input').attr('value','').focus();
};

// Expose to jQuery object
$.loginPage = loginPage;

})(jQuery);