<?php

require_once 'api/v1/PdSSyncAPI.php';

// ///////////////
// Boot strap
// ///////////////

define ( "REPOSITORY_PATH",   __DIR__ . '/repository/' );
define ("TREES_FOLDER_PATH", __DIR__.'/trees/');

try {
	$API = new PdSSyncAPI ();
	echo $API->run ();
} catch ( Exception $e ) {
	echo json_encode ( Array (
			'error' => $e->getMessage ()
	) );
}
