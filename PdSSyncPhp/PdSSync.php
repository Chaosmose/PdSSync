<?php

require_once 'api/v1/PdSSyncAPI.class.php';

// Requests from the same server don't have a HTTP_ORIGIN header
if (!array_key_exists('HTTP_ORIGIN', $_SERVER)) {
	$_SERVER['HTTP_ORIGIN'] = $_SERVER['SERVER_NAME'];
}

try {
	$API = new PdSSyncAPI($_REQUEST['request'], $_SERVER['HTTP_ORIGIN']);
	echo $API->run();
} catch (Exception $e) {
	echo json_encode(Array('error' => $e->getMessage()));
}
