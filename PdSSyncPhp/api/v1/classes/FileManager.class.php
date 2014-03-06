<?php

include_once 'api/v1/PdSSyncConst.php';

/**
 * A file manager proxy
 * for future extensions like supporting google app engine
 * 
 * @author bpds
 *        
 */
class FileManager {
	
	
	public function repositoryAbsolutePath() {
		return MASTER_REPOSITORY_WRITING_PATH;
	}
	public function absoluteMasterPath($treeId, $relativePath) {
		return $this->repositoryAbsolutePath () . md5($treeId.SECRET_KEY) . DIRECTORY_SEPARATOR . $relativePath;
	}
	public function uriFor($treeId, $relativePath) {
		return REPOSITORY_HOST . md5($treeId.SECRET_KEY) . DIRECTORY_SEPARATOR . $relativePath;
	}
	public function saveHashMap($treeId, $hashMap) {
		$filePath = $this->absoluteMasterPath ( $treeId, METADATA_FOLDER . HASHMAP_FILENAME );
		try {
			if(($this->file_put_contents ( $filePath, $hashMap ) != false))
				return true;
		} catch ( Exception $e ) {
			return false;
		}
		return true;
	}
	
	// Proxy for Standard FS Functions
	// For future extensions
	
	
	public function file_exists($filename) {
		return file_exists ( $filename );
	}
	
	function file_put_contents($filename, $data) {
		return file_put_contents ( $filename, $data );
	}
	
	public function mkdir($dir) {
		if (! file_exists ( $dir )) {
			mkdir ( $dir, 0777, true );
		}
	}
	
	public function move_uploaded_file($filename, $destination) {
		$dir = dirname ( $destination );
		if (! file_exists ( $dir )) {
			mkdir ( $dir );
		}
		return move_uploaded_file ( $filename, $destination );
	}
	
	public function rename($oldname, $newname) {
		return rename ( $oldname, $newname );
	}
}
