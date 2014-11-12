<?php

include_once 'v1/PdSSyncConst.php';

class CommandInterpreter {
	
	/**
	 * The $ioManager
	 *
	 * @var IOManager
	 */
	protected   $ioManager = NULL;
	
	/**
	 *  References the current list of files to be used for finalization.
	 * @var array
	 */
	private  $listOfFiles=array();
	
	/**
	 * @param IOManager $ioManager
	 */
	public function setIOManager($ioManager) {
		$this->ioManager = $ioManager;
	}

	/**
	 *  Interprets the command bunch and 
	 * @param string $treeId
	 * @param string $syncIdentifier
	 * @param array $bunchOfCommand
	 * @param string $finalHashMapFilePath
	 * @return null on success and a string with the error in case of any error
	 */
	function interpretBunchOfCommand($treeId, $syncIdentifier, array $bunchOfCommand,  $finalHashMapFilePath) {
		$failures=array();
		foreach ($bunchOfCommand as $command) {
			if(is_array($command)){
				$result=$this->_decodeAndRunCommand($syncIdentifier,$command,$treeId);
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
			return $this->_finalize($treeId, $syncIdentifier, $finalHashMapFilePath);
		}
	}
	
	
	/**
	 *  Finalizes the bunch of command
	 *  
	 * @param string $syncIdentifier
	 * @param string $finalHashMapFilePath
	 */
	private function _finalize($treeId, $syncIdentifier,$finalHashMapFilePath){
		$failures=array();
		foreach ($this->listOfFiles  as $file) {
			$relativePath=dirname($file).DIRECTORY_SEPARATOR.$syncIdentifier.basename($file);
			$protectedPath= $this->ioManager->absolutePath($treeId, $relativePath);
			if($this->ioManager->exists($protectedPath)){
				$success=$this->ioManager->rename($protectedPath, $this->ioManager->absolutePath($treeId, $file));
			}else{
				$failures[]='Unexisting path : '.$protectedPath.'->'.$treeId.' ('.$relativePath.')';
			}
		}
		if(count($failures)>0){
			return $failures;
		}else{
			$this->ioManager->mkdir($this->ioManager-> absolutePath($treeId, METADATA_FOLDER));
			if($this->ioManager->saveHashMap($treeId,$finalHashMapFilePath)){
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
	 * @param string $treeId
	 * @return string on error, or null on success
	 */
	private function _decodeAndRunCommand($syncIdentifier, array $cmd , $treeId) {
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
						 if($this->ioManager->copy($cmd[PdSSource],  $cmd[PdSDestination])){
							return NULL;
						 }else{
						 	return 'PdSCopy error';
						 }
						return NULL;
					}else{
						return 'PdSCopy R_PRIVILEGE required on '. $cmd[PdSSource] . 'AND R_PRIVILEGE required on  '.$cmd[PdSDestination];
					}
					break;
				case PdSMove :
					if($this->_isAllowedTo(R_PRIVILEGE, $cmd[PdSSource]) &&
							$this->_isAllowedTo(R_PRIVILEGE, $cmd[PdSDestination]) ){
						 if($this->ioManager->rename($cmd[PdSSource],  $cmd[PdSDestination])){
							return NULL;
						 }else{
						 	return 'PdSMove error';
						 }
					}else{
						return 'PdSMove R_PRIVILEGE required on '. $cmd[PdSSource] . 'AND R_PRIVILEGE required on  '.$cmd[PdSDestination];
					}
					break;
				case PdSDelete :
					if($this->_isAllowedTo(W_PRIVILEGE, $cmd[PdSSource])){
						if($this->ioManager->delete($cmd[PdSSource])){
							return NULL;
						}else{
							return 'PdSDelete error';
						}
						return NULL;
					}else{
						return 'PdSDelete W_PRIVILEGE required on '. $cmd[PdSSource];
					}
					
					break;
				case PdsSanitize :
						if($this->_isAllowedTo(R_PRIVILEGE, $this->ioManager->absolutePath($treeId,''))){
							// @todo purge any unfinalized sync in progress.
						}
					break;
				case PdSChmod :

						if($this->_isAllowedTo(R_PRIVILEGE, $this->ioManager->absolutePath($treeId,''))){
							// @todo chmod should apply to the whole tree
						}
		
					break;
				case PdSForget :
						if($this->_isAllowedTo(R_PRIVILEGE, $this->ioManager->absolutePath($treeId,''))){
							//@todo erase the undoers and redoers to clean up the delta history
						}
					break;
				default ;
					break;
			}
		}
		return 'CMD '.json_encode($cmd).' is not valid';
	}
	

	private function _isAllowedTo($privilege,$relativePath){
		// @todo 
		//define ('R_PRIVILEGE', 2);
		//define ('W_PRIVILEGE', 4);
		//define ('X_PRIVILEGE', 8);
		return true;
	}
}?>