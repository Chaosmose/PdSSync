<?php 

///////////////////////
// REPOSITORY  
///////////////////////


define ( 'REPOSITORY_HOST'										,	((array_key_exists('HTTPS', $_SERVER))?($_SERVER['HTTPS'])?'https://':'http://':'http://').$_SERVER['SERVER_NAME'].'/PdSSyncPhp/Repository/' );
define ( 'REPOSITORY_WRITING_PATH'		                ,	dirname( dirname(__DIR__)). '/Repository/'  );

///////////////////////
// PERSITENCY
///////////////////////

require_once 'v1/classes/IOManagerFS.class.php';  // Default adapter
//require_once 'v1/classes/IOManagerRedis.class.php';
define('PERSISTENCY_CLASSNAME'								,	 'IOManagerFS');

///////////////////////
// KEYS
///////////////////////

define ( 'CREATIVE_KEY'												,	'default-creative-key' ); // Used to validate a tree creation
define ( 'SECRET'															,	'default-secret-key' ); // Used create the data system folder



//////////////////////
// MISC 
//////////////////////

define ( 'MIN_TREE_ID_LENGTH'		                ,	1  );



//////////////////////
// DEBUG
//////////////////////

define ('DEBUG_INPUTS',FALSE); // Should be FALSE and turned to TRUE only for exceptionnal purposes
define ('DEBUG_INPUTS_IS_SELECTIVE',TRUE);// Allows to selectively debug inputs calls
define ('DEBUG_INPUTS_FOR_METHOD','GET');
define ('DEBUG_INPUTS_FOR_ENDPOINT','hashMap'); 
