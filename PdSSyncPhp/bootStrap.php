<?php

// You can set up with your own values.


//define ( 'REPOSITORY_HOST'										,	'http://PdsSync.repository.local/' );
define ( 'REPOSITORY_HOST'										,	'http://PdsSync.api.local/Repository/' );

define ( 'MASTER_REPOSITORY_WRITING_PATH'		,	 __DIR__. '/Repository/'  );
define ( 'CREATIVE_KEY'												,	'6ca0c48126a15939-2c938833d4678913' ); // Used to validate a tree creation


require_once 'api/v1/PdSSyncAPI.class.php';

try {
	$API = new PdSSyncAPI ();
	echo $API->run ();
} catch ( Exception $e ) {
	echo json_encode ( Array (
			'error' => $e->getMessage ()
	) );
}
