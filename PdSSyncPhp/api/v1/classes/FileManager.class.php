<?php

include_once 'api/v1/PdSSyncConst.php';
/**
 *  A file manager proxy 
 *  for future extensions.
 * @author bpds
 *
 */
class FileManager {
	
	public  function repositoryAbsolutePath(){
		return MASTER_REPOSITORY_WRITING_PATH;
	}
	
	public function absoluteMasterPath($treeId,$relativePath){
		return $this->repositoryAbsolutePath().$treeId.DIRECTORY_SEPARATOR.$relativePath;
	}
	
	public function uriFor($treeId,$relativePath){
		return REPOSITORY_HOST.$treeId.DIRECTORY_SEPARATOR.$relativePath;
	}
	

	// Proxy for Standard FS Functions 
	// For future extensions 
	
	public  function file_exists($filename){
		return  file_exists($filename);
	}
	
	public function mkdir ($pathname) {
		mkdir($pathname,0777,true);
	}
	
	public  function  move_uploaded_file($filename, $destination){
	$dir=dirname($destination);
		if(!file_exists($dir)){
			mkdir($dir);
		}
		return move_uploaded_file($filename, $destination);
	}
	
	
}

?>