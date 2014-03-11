<?php 

///////////////////////
// REPOSITORY  
///////////////////////


//define ( 'REPOSITORY_HOST'										,	'http://PdsSync.repository.local/' );
define ( 'REPOSITORY_HOST'										,	'http://PdsSync.api.local/Repository/' );
define ( 'MASTER_REPOSITORY_WRITING_PATH'		,	dirname( dirname(__DIR__)). '/Repository/'  );

///////////////////////
// PERSITENCY
///////////////////////

//require_once 'v1/classes/IOManagerFS.class.php';  // Default adapter
require_once 'v1/classes/IOManagerRedis.class.php';
define('PERSISTENCY_CLASSNAME'								,	 'IOManagerRedis');

///////////////////////
// KEYS
///////////////////////

define ( 'CREATIVE_KEY'												,	'6ca0c48126a15939-2c938833d4678913' ); // Used to validate a tree creation
define ( 'SECRET'															,	'S-DEKuLAL088986HHDkKDODE02039DKOPZD?' ); // Used create the data system folder
