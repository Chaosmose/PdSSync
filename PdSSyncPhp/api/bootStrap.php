<?php

include_once 'v1/PdSSyncConfig.php';
require_once 'v1/PdSSyncAPI.class.php';

try {
	$API = new PdSSyncAPI ();
	echo $API->run ();
} catch ( Exception $e ) {
	echo json_encode ( Array (
			'error' => $e->getMessage ()
	) );
}
