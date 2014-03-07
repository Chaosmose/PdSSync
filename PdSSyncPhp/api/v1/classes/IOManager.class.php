<?php

include_once 'v1/PdSSyncConst.php';

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
	 *  The current tree data 
	 * @var array
	 */
	private   $treeData=NULL;
	
	
	/**
	 * Returns the absolute path of a given resource
	 * @param string $treeId
	 * @param string $relativePath
	 * @return string|NULL
	 */
	public function absolutePath($treeId, $relativePath) {
		$currentId=$this->_currentPublicId($treeId);
		if($currentId!=NULL){
			return $this->repositoryAbsolutePath () . $this->_currentPublicId($currentId). DIRECTORY_SEPARATOR . $relativePath;
		}return NULL;
	}
	
	/**
	 *  Returns the current public uri for a given resource
	 * @param string $treeId
	 * @param string $relativePath
	 * @return string|NULL
	 */
	public function uriFor($treeId, $relativePath) {
		$currentId=$this->_currentPublicId($treeId);
		if($currentId!=NULL && $this->exists($this->absolutePath($treeId, $relativePath))){
			return REPOSITORY_HOST.$currentId .DIRECTORY_SEPARATOR . $relativePath;
		}else{
			return NULL;
		}
	}
		
	/**
	 * The tree id is persistent not the currentPublicId
	 * That  may change during the life cycle
	 *  For example in case of ACL invalidation for a group member
	 *   It is the public exposed tree root folder
	 * @param string $treeId
	 * @return array|NULL
	 */
	public function createTree( $treeId){
		$currentPublicId = $this->_createAPublicId();
		$systemDataFolder = $this->_treeInfosFolderPathFor($treeId);
		$messages=array();
		// Create the system data folder
		if($this->exists($systemDataFolder)){
			$messages[]= $systemDataFolder.' is already existing';
		}
		 if (!$this->mkdir ($systemDataFolder)){
			$messages[]= $systemDataFolder.' mkdir error';
		}
		
		// Put the current public id, owner, and an array of groups
		$this->treeData=array( $currentPublicId, ANONYMOUS,  array(ANONYMOUS), 777);
		
		if($this->put_contents($systemDataFolder.TREE_INFOS_FILENAME, json_encode($this->treeData))==false){
			$messages[]=$treeId.'createTree tree infos file_put_contents error '.$systemDataFolder.TREE_INFOS_FILENAME;
		}
		// Create the public id folder
		$currentPublicIdFolder=$this->repositoryAbsolutePath ().$currentPublicId. DIRECTORY_SEPARATOR ;
		if(!$this->mkdir($currentPublicIdFolder)){
			$messages[]= $currentPublicIdFolder.' createTree mkdir error';
		}
		// Create the meatdata folder in the public id folder
		if(!$this->mkdir($currentPublicIdFolder.METADATA_FOLDER)){
			$messages[]= $currentPublicIdFolder.METADATA_FOLDER.' createTree mkdir error';
		}
		if(count($messages)>0){
			return $messages;
		}
		return NULL;
	}
	
	private  function _createAPublicId(){
		return md5(uniqid());
	}
	
	
	/**
	 * Changes the public identifier.
	 * 
	 * @param unknown_type $treeId
	 */
	public function touchTree($treeId){
		$messages=array();
		$currentPublicId=$this->_currentPublicId($treeId);// populates $this->treeData
		$currentPublicIdFolder=$this->repositoryAbsolutePath ().$currentPublicId. DIRECTORY_SEPARATOR ;
		$newPublicId = $this->_createAPublicId();
		$newPublicIdFolder=$this->repositoryAbsolutePath ().$newPublicId. DIRECTORY_SEPARATOR ;
		$this->treeData[0]=$newPublicId;
		if($this->put_contents($this->_treeInfosFolderPathFor($treeId).TREE_INFOS_FILENAME, json_encode($this->treeData))==false){
			$messages[]=$treeId.'touchTree tree infos file_put_contents error '.$this->_treeInfosFolderPathFor($treeId).TREE_INFOS_FILENAME;
		}else{
			if($this->rename($currentPublicIdFolder, $newPublicIdFolder)==false){
				$messages[]=$treeId.' moving folder error ';
			}
		}
		if(count($messages)>0){
			return $messages;
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
	 *  Creates the repository
	 *  And could perform any installation related task
	 */
	public function install() {
		$path = $this->repositoryAbsolutePath();
		if (! $this->exists ( $path )) {
			$this->mkdir ( $path );
		}
	}
	
	
	/**
	 * The infos folder for a given tree
	 * @param string $treeId
	 * @return string
	 */
	private  function _treeInfosFolderPathFor($treeId){
		// The metadata folder uses the unique  tree id
		return $this->repositoryAbsolutePath() .SYSTEM_DATA_PREFIX.md5(SECRET.$treeId).DIRECTORY_SEPARATOR;
	}
	
	/**
	 *  Returns the current public id of a given tree
	 * @param string $treeId
	 * @return string
	 */
	private function _currentPublicId($treeId){
		if($this->treeData==NULL){
			$p=$this->_treeInfosFolderPathFor($treeId).TREE_INFOS_FILENAME;
			if($this->exists($p)){
				$this->treeData= json_decode( $this->get_contents($p));
				return $this->treeData[0];
			}
			return '';
		}else{
				return $this->treeData[0];
		}

	}

	
	// Proxy for Standard FS Functions
	// For future extensions cache ... 

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
			return mkdir ( $dir, 0777, true );
		}
		return true;
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
