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

define ('PdSCreateOrUpdate'	,	0);        // W source - un prefix the asset
define ('PdSMove'	,					1); 		// R source W destination
define ('PdSCopy'	,					2); 		// R source W destination
define ('PdSDelete'	,					3);		// W source

// PdSSyncCMDParamsRank
define ('PdSCommand'   , 			0);
define ('PdSDestination'	,			1);
define ('PdSSource'			,			2);
