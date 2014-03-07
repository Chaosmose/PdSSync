<?php

include_once 'api/v1/PdSSyncConst.php';

/**
 * An IOmanager proxy
 * for future extensions like supporting
 * google app engine (with no file system)
 * or redis implementation 
 * @author bpds
 *        
 */
class IOManager {
	

	/**
	 * Returns the absolute path of a given resource
	 * @param string $treeId
	 * @param string $relativePath
	 * @return string
	 */
	public function absolutePath($treeId, $relativePath) {
		return $this->repositoryAbsolutePath () . $this->_currentPublicId($treeId). DIRECTORY_SEPARATOR . $relativePath;
	}
	
	/**
	 *  Returns the current public uri for a given resource
	 * @param string $treeId
	 * @param string $relativePath
	 * @return string
	 */
	public function uriFor($treeId, $relativePath) {
		return REPOSITORY_HOST . $this->_currentPublicId($treeId) . DIRECTORY_SEPARATOR . $relativePath;
	}
		
	/**
	 * The tree id is persistent not the currentPublicId
	 * That  may change during the life cycle
	 *  For example in case of ACL invalidation for a group member
	 *   It is the public exposed tree root folder
	 * @param string $treeId
	 * @return string|NULL
	 */
	public function createTree( $treeId){
		$currentPublicId = uniqid ();
		$systemDataFolder = $this->_systemdataFolderPathFor($treeId);
		if($this->exists($systemDataFolder)){
			return $treeId.' is already existing';
		}
		if(!$this->mkdir ($systemDataFolder)){
			return $treeId.' mkdir error';
		}
		if($this->put_contents($metadataFolderPath.UID_FILENAME, $currentPublicId)==false){
			return  $treeId.'UID_FILENAME file_put_contents error';
		}
		return NULL;
	}
	
	
	/**
	 *  Saves the Hash map 
	 * @param string $treeId
	 * @param string $hashMap
	 * @return boolean
	 */
	public function saveHashMap($treeId, $hashMap) {
		$filePath = $this->absolutePath ( $treeId, METADATA_FOLDER . HASHMAP_FILENAME );
		try {
			if(($this->put_contents ( $filePath, $hashMap ) != false))
				return true;
		} catch ( Exception $e ) {
			return false;
		}
		return true;
	}
	
	/**
	 *  The repository absolute path
	 * @return string
	 */
	public function repositoryAbsolutePath() {
		return MASTER_REPOSITORY_WRITING_PATH;
	}
	
	/**
	 * The system data folder for a given tree
	 * @param string $treeId
	 * @return string
	 */
	private  function _systemdataFolderPathFor($treeId){
		// The metadata folder uses the unique  tree id
		 return SYSTEM_DATA_PREFIX.$treeId;
	}
	
	/**
	 *  Returns the current public id of a given tree
	 * @param string $treeId
	 * @return string
	 */
	private function _currentPublicId($treeId){
	 	return $this->get_contents($this->_systemdataFolderPathFor($treeId).UID_FILENAME);	
	}
	
	/**
	 *  Creates the repository 
	 *  And could perform any installation related task
	 */
	public function install() {
		$path = $this->repositoryAbsolutePath();
		if (! $this->exists ( $path )) {
			$this->mkdir ( $path );
		}
	}
	
	// Proxy for Standard FS Functions
	// For future extensions cache etc... 

	
	public function exists($filename) {
		return file_exists ( $filename );
	}
	
	function put_contents($filename, $data) {
		return file_put_contents ( $filename, $data );
	}
	
	function get_contents($filename){
		return file_get_contents($filename);
	}
	
	
	public function mkdir($dir) {
		if (! file_exists ( $dir )) {
			mkdir ( $dir, 0777, true );
		}
	}
	
	public function move_uploaded($filename, $destination) {
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
