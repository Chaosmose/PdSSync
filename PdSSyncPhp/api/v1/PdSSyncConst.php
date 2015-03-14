<?php

// Responses key consts

define('INFORMATIONS_KEY','informations');
define('METHOD_KEY','method');

define ('HASHMAP_FILENAME','hashMap.hash');
define ('TREE_INFOS_FILENAME','treeInfos');
define('SYSTEM_DATA_PREFIX', '.');
define('METADATA_FOLDER','.PdSSync/');
define ('SYNC_PREFIX_SIGNATURE','.PdSSync');

///////////////////////////////
// PdSSyncCommands
///////////////////////////////

define ('PdSCreate'	,					0);        // W source - un prefix the asset
define ('PdSUpdate'	,					1);        // W source - un prefix the asset
define ('PdSMove'	,					2);        // R source W destination
define ('PdSCopy'	,					3); 	   // R source W destination
define ('PdSDelete'	,					4);		   // W source

// PdSSyncCMDParamsRank
define ('PdSCommand'   , 			    0);
define ('PdSDestination'	,			1);
define ('PdSSource'			,			2);
