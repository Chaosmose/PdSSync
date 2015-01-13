<?php

include_once 'v1/PdSSyncConst.php';
include_once 'v1/PdSSyncConfig.php';
require_once 'v1/PdSSyncAPI.php';

try {
	$API = new PdSSyncAPI ();
	echo $API->run ();
} catch ( Exception $e ) {
	$status=500;
	$header = 'HTTP/1.1 ' . $status . ' ' . $API->requestStatus ( $status );
	header ( $header );
	echo json_encode ( Array (
			'error' => $e->getMessage ()
	) );
}
