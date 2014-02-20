<?php

include 'api/v1/PdSSyncConst.php';

class HashMapGenerator {
	
	/**
	 * Creates a server side hash map for the relative paths
	 *  Use the method if it is not possible to proceed the HashMap on the client side. 
	 * 
	 * @param array $relativePaths        	
	 */
	public function HashMapForRelativePaths(array $relativePaths = array()) {
		
		$fileName = crc32 ( json_encode ( $relativePaths ) ) . HASH_MAP_SUFFIX;
		$filePath = HASH_MAPS_FOLDER_PATH . $fileName;
		$locker = $fileName . LOCKED_SUFFIX;
		$lockerPath = HASH_MAPS_FOLDER_PATH . $locker;
		// Create the locker
		if (file_put_contents ( $lockerPath, '' . time () ) !== false) {
			$nb = count ( $relativePaths );
			if ($nb) {
				// Recursive exploration of REPOSITORY_PATH
				// $paths add all the relative path
				// @TODO
			}
			$descriptor = array ();
			foreach ( $relativePaths as $path ) {
				$crc32 = crc32 ( file_get_content ( $path ) );
				gc_collect_cycles (); // Invoke the GC
				$descriptor [$path] = $crc32;
			}
			$json = json_encode ( $descriptor );
			if (file_put_contents ( $filePath, $json ) !== false) {
				// Remove the locker
				unlink ( $lockerPath );
			}
		}
	}
}
