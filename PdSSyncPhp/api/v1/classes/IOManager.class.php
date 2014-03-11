<?php

include_once 'v1/PdSSyncConst.php';

/**
 *  Standard IO Functions
 *  Implement those method to create 
 *  a new persistency layer
 * @author bpds
 */
interface IOManagerPersistency {
	
	public function exists($filename) ;
	
	public function put_contents($filename, $data);
	
	public function get_contents($filename);
	
	public function mkdir($dir);
	
	public function rename($oldname, $newname);
	
	public function copy( $source, $destination );
	
	public function delete($filename);
	
	public function move_uploaded($filename, $destination);
	
	public function shouldRedirectURIByDefault();
	
}

interface  IOManager extends IOManagerPersistency{
	
	


	/**
	 * Returns the absolute path of a given resource
	 * @param string $treeId
	 * @param string $relativePath
	 * @return string|NULL
	 */
	public function absolutePath($treeId, $relativePath);
	
	/**
	 *  Returns the current public uri for a given resource
	 * @param string $treeId
	 * @param string $relativePath
	 * @param boolean $returnValue if set to true reads the contents and returns it
	 * @return string|NULL
	 */
	public function uriFor($treeId, $relativePath,$returnValue=false);
	
	
	/**
	 * The tree id is persistent not the currentPublicId
	 * That  may change during the life cycle
	 *  For example in case of ACL invalidation for a group member
	 *   It is the public exposed tree root folder
	 * @param string $treeId
	 * @return array|NULL
	 */
	public function createTree( $treeId);
	
	
	/**
	 * Changes the public identifier.
	 *
	 * @param unknown_type $treeId
	 */
	public function touchTree($treeId);
	
	
	/**
	 *  Saves the Hash map
	 * @param string $treeId
	 * @param string $hashMap
	 * @return boolean
	 */
	public function saveHashMap($treeId, $hashMap);
	
	
	/**
	 *  Creates the repository
	 *  And could perform any installation related task
	 */
	public function install();

}
 

/**
 *  IOmanager abstract class
 * @author bpds
 *        
 */
abstract  class IOManagerAbstract  {
	
	/**	
	 *  Used to define a status code
	 * @var integer
	 */
	public $status=0;
	
	
	/**
	 *  The current tree data 
	 * @var array
	 */
	protected   $treeData=NULL;
	

	public function repositoryAbsolutePath() {
		return MASTER_REPOSITORY_WRITING_PATH;
	}
	

	public function absolutePath($treeId, $relativePath) {
		$currentId=$this->_currentPublicId($treeId);
		if($currentId!=NULL){
			return $this->repositoryAbsolutePath () . $this->_currentPublicId($currentId). DIRECTORY_SEPARATOR . $relativePath;
		}return NULL;
	}
	

	public function uriFor($treeId, $relativePath,$returnValue=false) {
		$currentId = $this->_currentPublicId ( $treeId );
		$absolutePath = $this->absolutePath ( $treeId, $relativePath );
		if ($currentId != NULL) {
			if ($this->exists ( $absolutePath )) {
				$uri = REPOSITORY_HOST . $currentId . DIRECTORY_SEPARATOR . $relativePath;
				$redirectByDefault = $this->shouldRedirectURIByDefault ();
				if ($redirectByDefault && $returnValue == false) {
					header ( 'Location:  ' . $uri, true, 307 );
					exit ();
				} else {
					$this->status = 200;
					// @todo 401 if not authorized;
					// $this->status=401
					
					if ($returnValue == true) {
						return $this->get_contents ( $absolutePath );
					} else {
						return $uri;
					}
				}
			} else {
				if ($this->shouldRedirectURIByDefault () && $returnValue == false) {
					header ( 'Location:  ' . $uri, true, 404 );
				} else {
					$this->status = 404;
					return NULL;
				}
			}
		} else {
			$this->status = 404;
			return NULL;
		}
	}
	
	public function createTree( $treeId){
		$currentPublicId = $this->_createAPublicId();
		$systemDataFolder = $this->_treeInfosFolderPathFor($treeId);
		$messages=array();
		// Create the system data folder
		if($this->exists($systemDataFolder)){
			$messages[]= $systemDataFolder.' is already existing';
			return $messages;
		}
		 if (!$this->mkdir ($systemDataFolder)){
			$messages[]= $systemDataFolder.' mkdir error';
			return $messages;
		}
		
		// Put the current public id, owner, and an array of groups
		$this->treeData=array( $currentPublicId, ANONYMOUS,  array(ANONYMOUS), 777);
		
		if($this->put_contents($systemDataFolder.TREE_INFOS_FILENAME, json_encode($this->treeData))==false){
			$messages[]=$treeId.'createTree tree infos file_put_contents error '.$systemDataFolder.TREE_INFOS_FILENAME;
		}
		// Create the public id folder
		$currentPublicIdFolder=$this->repositoryAbsolutePath ().$currentPublicId. DIRECTORY_SEPARATOR ;
		if(!$this->mkdir($currentPublicIdFolder)){
			$messages[]= $currentPublicIdFolder.' mkdir error';
		}
		// Create the meatdata folder in the public id folder
		if(!$this->mkdir($currentPublicIdFolder.METADATA_FOLDER)){
			$messages[]= $currentPublicIdFolder.METADATA_FOLDER.'   mkdir error';
		}
		if(count($messages)>0){
			return $messages;
		}
		return NULL;
	}
	

	
	public function touchTree($treeId) {
		$messages = array ();
		$currentPublicId = $this->_currentPublicId ( $treeId ); // populates $this->treeData
		if ($currentPublicId == NULL) {
			$messages [] = 'tree does not exists';
		} else {
			
			$currentPublicIdFolder = $this->repositoryAbsolutePath () . $currentPublicId . DIRECTORY_SEPARATOR;
			$oldPublicId = $this->treeData [0];
			$newPublicId = $this->_createAPublicId ();
			$newPublicIdFolder = $this->repositoryAbsolutePath () . $newPublicId . DIRECTORY_SEPARATOR;
			$this->treeData [0] = $newPublicId;
			if ($this->exists ( $currentPublicIdFolder )) {
				
				if ($this->put_contents ( $this->_treeInfosFolderPathFor ( $treeId ) . TREE_INFOS_FILENAME, json_encode ( $this->treeData ) ) == false) {
					$messages [] = $treeId . ' tree infos file_put_contents error ' . $this->_treeInfosFolderPathFor ( $treeId ) . TREE_INFOS_FILENAME;
				} else {
					if ($this->rename ( $currentPublicIdFolder, $newPublicIdFolder ) == false) {
						$messages [] = $treeId . ' moving folder error ';
						// we need to try to reset the tree infos (fault resilience)
						$this->treeData [0] = $oldPublicId;
						$this->put_contents ( $this->_treeInfosFolderPathFor ( $treeId ) . TREE_INFOS_FILENAME, json_encode ( $this->treeData ) );
					}
				}
			} else {
				$messages [] = $currentPublicIdFolder . ' does not exist';
			}
		}
		if (count ( $messages ) > 0) {
			return $messages;
		}
		return NULL;
	}
	

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


	public function install() {
		$path = $this->repositoryAbsolutePath();
		if (! $this->exists ( $path )) {
			$this->mkdir ( $path );
		}
	}

	public function shouldRedirectURIByDefault(){
		return false;	
	}
	
	// Protected 
	
	/**
	 * Creates a unique public id for a given server.
	 * @return string
	 */
	protected  function _createAPublicId(){
		return md5(uniqid());
	}
	
	
	/**
	 * The infos folder for a given tree
	 * @param string $treeId
	 * @return string
	 */
	protected  function _treeInfosFolderPathFor($treeId){
		// The metadata folder uses the unique  tree id
		return $this->repositoryAbsolutePath() .SYSTEM_DATA_PREFIX.md5(SECRET.$treeId).DIRECTORY_SEPARATOR;
	}
	
	/**
	 *  Returns the current public id of a given tree
	 * @param string $treeId
	 * @return string
	 */
	protected function _currentPublicId($treeId){
		if($this->treeData==NULL){
			$p=$this->_treeInfosFolderPathFor($treeId).TREE_INFOS_FILENAME;
			if($this->exists($p)){
				$this->treeData= json_decode( $this->get_contents($p));
				return $this->treeData[0];
			}
			return NULL;
		}else{
			return $this->treeData[0];
		}
	
	}
}
?>