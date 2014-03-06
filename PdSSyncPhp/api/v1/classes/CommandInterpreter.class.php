<?php

include_once 'api/v1/PdSSyncConst.php';
include_once 'api/v1/classes/FileManager.class.php';

class CommandInterpreter {
	
	/**
	 * The filemanager
	 *
	 * @var FileManager
	 */
	protected   $fileManager = NULL;
	
	/**
	 *  References the current list of files to be used for finalization.
	 * @var array
	 */
	private  $listOfFiles=array();
	
	/**
	 * @return the $fileManager
	 */
	public function getFileManager() {
		if(!$this->fileManager){
			$this->fileManager=new  FileManager();
		}
		return $this->fileManager;
	}

	/**
	 * @param FileManager $fileManager
	 */
	public function setFileManager($fileManager) {
		$this->fileManager = $fileManager;
	}

	/**
	 *  Interprets the command bunch and 
	 * @param string $treeId
	 * @param string $syncIdentifier
	 * @param array $bunchOfCommand
	 * @param string $finalHashMap
	 * @return null on success and a string with the error in case of any error
	 */
	function interpretBunchOfCommand($treeId, $syncIdentifier, array $bunchOfCommand,  $finalHashMap) {
		$failures=array();
		foreach ($bunchOfCommand as $command) {
			if(is_array($command)){
				$result=$this->_decodeAndRunCommand($syncIdentifier,$command);
				if($result!=NULL){
					$failures[]=$result;
				}
			}else{
				$failures[]=$command.' is not an array';
			}
			if(isset($result)){
				$failures[]=$result;
			}
			$result=NULL;
		}
		if(count($failures)>0){
			return $failures;
		}else{
			return $this->_finalize($treeId, $syncIdentifier, $finalHashMap);
		}
	}
	
	
	/**
	 *  Finalizes the bunch of command
	 *  
	 * @param string $syncIdentifier
	 * @param string $finalHashMap
	 */
	private function _finalize($treeId, $syncIdentifier,$finalHashMap){
		$failures=array();
		foreach ($this->listOfFiles  as $file) {
			$protectedPath= $this->fileManager->absoluteMasterPath($treeId, dirname($file).DIRECTORY_SEPARATOR.$syncIdentifier.basename($file));
			if($this->fileManager->file_exists($protectedPath)){
				$this->fileManager->rename($protectedPath, $this->fileManager->absoluteMasterPath($treeId, $file));
			}else{
				$failures[]='Unexisting path : '.$protectedPath;
			}
		}
		if(count($failures)>0){
			return $failures;
		}else{
			$this->fileManager->mkdir($this->fileManager-> absoluteMasterPath($treeId, METADATA_FOLDER));
			
			if($this->fileManager->saveHashMap($treeId,$finalHashMap)){
				return NULL;
			}else{
				$failures[]='Error when saving the hashmap';
				return  $failures;
			}
		}
	}	
	
	
	/**
	 *  Decodes and runs the command 
	 *  @param $syncIdentifier
	 * @param array $cmd
	 * @return string on error, or null on success
	 */
	private function _decodeAndRunCommand($syncIdentifier, array $cmd) {
		if (count ( $cmd > 1 )) {
			$command = $cmd [0];
			switch ($command) {
				case PdSCreateOrUpdate :
					if(!isset($cmd[PdSDestination])){
							return 'PdSDestination must be non null :'.  $cmd;
					}
					if($this->_isAllowedTo(W_PRIVILEGE, $cmd[PdSDestination]) ){
						// There is no real FS action to perform 
						// We just added the file for finalization.
						$this->listOfFiles[]= $cmd[PdSDestination];
						return NULL;
					}else{
						return 'PdSCreateOrUpdate W_PRIVILEGE required for :'.  $cmd[PdSDestination];
					}
					break;
				case PdSCopy :
					if($this->_isAllowedTo(R_PRIVILEGE, $cmd[PdSSource]) &&
						$this->_isAllowedTo(R_PRIVILEGE, $cmd[PdSDestination]) ){
							// we copy directly  
						return NULL;
					}else{
						return 'PdSCopy R_PRIVILEGE required on '. $cmd[PdSSource] . 'AND R_PRIVILEGE required on  '.$cmd[PdSDestination];
					}
					break;
				case PdSMove :
					break;
				case PdSDelete :
					break;
				case PdsSanitize :
					if (count ( $cmd > 2 )) {
						$cmd[PdSPoi];
						$cmd[PdSDepth];
						$cmd[PdSValue];
					}
					break;
				case PdSChmod :
					if (count ( $cmd > 2 )) {
						$cmd[PdSPoi];
						$cmd[PdSDepth];
						$cmd[PdSValue];
					}
					break;
				case PdSForget :
				if (count ( $cmd > 2 )) {
						$cmd[PdSPoi];
						$cmd[PdSDepth];
						$cmd[PdSValue];
					}
					break;
				default ;
					break;
			}
		}
		return 'CMD '.json_encode($cmd).' is not valid';
	}
	

	private function _isAllowedTo($privilege,$relativePath){
		//define ('R_PRIVILEGE', 2);
		//define ('W_PRIVILEGE', 4);
		//define ('X_PRIVILEGE', 8);
		return true;
	}

	
	
}