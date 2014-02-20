<?php

// ///////////////
// Boot strap
// ///////////////

require_once 'api/v1/PdSSyncAPI.class.php';

define("REPOSITORY_PATH", __DIR__. '/repository/' );
define("HASH_MAPS_FOLDER_PATH",__DIR__.'/hashMaps/');
try {
	$API = new PdSSyncAPI ();
	echo $API->run ();
} catch ( Exception $e ) {
	echo json_encode ( Array (
			'error' => $e->getMessage ()
	) );
}
