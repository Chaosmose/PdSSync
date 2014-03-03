<?php

include_once 'api/v1/PdSSyncConst.php';
class CommandInterpreter {
	
	
	/**
	 *  Interprets the command bunch and 
	 *    
	 * @param string $syncIdentifier
	 * @param string $rootFolderRelativePath
	 * @param array $bunchOfCommand
	 * @param string $finalHashMap
	 * @return null on success and a string with the error in case of any error
	 */
	function interpretBunchOfCommand($syncIdentifier, $rootFolderRelativePath, array $bunchOfCommand, $finalHashMap) {
		$failures=array();
		foreach ($bunchOfCommand as $command) {
			$result=$this->_decodeAndRunCommand($command);
			if(isset($result)){
				$failures[]=$result;
			}
			$result=null;
		}
		if(count($failures)>0){
			return json_encode($failures);
		}else{
			return $this->_finalize($syncIdentifier, $finalHashMap);
		}
	}
	/**
	 *  Finalizes the bunch of command
	 *  
	 * @param unknown_type $syncIdentifier
	 * @param unknown_type $finalHashMap
	 */
	private function _finalize( $syncIdentifier,$finalHashMap){
		
	}	

	
	/**
	 *  Decodes and runs the command 
	 * @param array $cmd
	 * @return string on error, or null on success
	 */
	private function _decodeAndRunCommand(array $cmd) {
		if (count ( $cmd > 1 )) {
			$command = $cmd [0];
			$nbofParam=2;
			switch ($command) {
				case PdSCreate :
					break;
				case PdSCopy :
					break;
				case PdSCreate :
					break;
				case PdSMove :
					break;
				case PdSDelete :
					break;
				case PdsSanitize :
					$nbofParam=3;
					break;
				case PdSChmod :
					$nbofParam=3;
					break;
				case PdSForget :
					$nbofParam=3;
					break;
				default ;
					break;
			}
		}
		return 'CMD '.json_encode($cmd).' is not valid';
	}
	
	
	
	
}