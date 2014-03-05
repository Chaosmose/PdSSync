<?php

// You can set up with your own values.
define ( 'REPOSITORY_HOST'										,	'http://PdsSync.repository.local/' );
define ( 'MASTER_REPOSITORY_WRITING_PATH'		,	 __DIR__. '/repository/'  );
define ( 'SECRET_KEY'													,	'6ca0c48126a159392c938833d4678913' );

require_once 'api/v1/PdSSyncAPI.class.php';

try {
	$API = new PdSSyncAPI ();
	echo $API->run ();
} catch ( Exception $e ) {
	echo json_encode ( Array (
			'error' => $e->getMessage ()
	) );
}
