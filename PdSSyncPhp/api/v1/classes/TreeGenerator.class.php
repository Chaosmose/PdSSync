<?php

include 'api/v1/PdSSyncConst.php';

class TreeGenerator {
	
	/**
	 * Creates the tree for the relative paths
	 * 
	 * @param array $relativePaths        	
	 */
	public function treeForRelativePaths(array $relativePaths = array()) {
		
		$fileName = crc32 ( json_encode ( $relativePaths ) ) . TREE_SUFFIX;
		$filePath = TREES_FOLDER_PATH . $fileName;
		$locker = $fileName . LOCKED_SUFFIX;
		$lockerPath = TREES_FOLDER_PATH . $locker;
		
		// Create the locker
		if (file_put_contents ( $lockerPath, '' . time () ) !== false) {
			$nb = count ( $paths );
			if ($nb) {
				// Recursive exploration of REPOSITORY_PATH
				// $paths add all the relative path
				// @TODO
			}
			$descriptor = array ();
			foreach ( $relativePaths as $path ) {
				$data = file_get_content ( $path );
				$crc32 = crc32 ( $data );
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
