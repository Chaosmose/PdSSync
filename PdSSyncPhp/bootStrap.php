<?php

// ///////////////
// Boot strap
// ///////////////

define('REPOSITORY_PATH', __DIR__. '/repository/' );
define('ADMIN_PRIVILEGE_KEY','6ca0c48126a159392c938833d4678913');

require_once 'api/v1/PdSSyncAPI.class.php';

try {
	$API = new PdSSyncAPI ();
	echo $API->run ();
} catch ( Exception $e ) {
	echo json_encode ( Array (
			'error' => $e->getMessage ()
	) );
}
