<?php

/** @noinspection PhpIncludeInspection */
include_once 'PdSSyncConst.php';


class CommandInterpreter {
	
	/**
	 * The $ioManager
	 *
	 * @var IOManager
	 */
	protected $ioManager = NULL;
	
	/**
	 * References the current list of files to be used for finalization.
	 *
	 * @var array
	 */
	private $listOfFiles = array ();
	
	/**
	 *
	 * @param IOManager $ioManager        	
	 */
	public function setIOManager($ioManager) {
		$this->ioManager = $ioManager;
	}
	
	/**
	 * Interprets the command bunch and
	 *
	 * @param string $treeId        	
	 * @param string $syncIdentifier        	
	 * @param array $bunchOfCommand        	
	 * @param string $finalHashMapFilePath        	
	 * @return null on success and a string with the error in case of any error
	 */
	function interpretBunchOfCommand($treeId, $syncIdentifier, array $bunchOfCommand, $finalHashMapFilePath) {
		$failures = array ();
		$hasProceededToUnPrefixing = FALSE;
		// Order matters.
		// Sort the command to execute delete commands at the end (after create, copy and move)
		usort ( $bunchOfCommand, array (
				$this,
				'_compareCommand' 
		) );

        // Let's remove possible doublons
        $filteredBunchOfCommand=array();
        foreach ($bunchOfCommand as $command){
            $alreadyExists=false;
            foreach($filteredBunchOfCommand as $filteredCommand){
                if(count ($filteredCommand)===count($command)){
                    $nbOfArguments=count($filteredCommand);
                    $match=true;
                    for($i=0;$i<$nbOfArguments;$i++){
                        $match=(($filteredBunchOfCommand[$i]==$command[$i])&& $match);
                    }
                    if($match==true){
                        $alreadyExists=true;
                    }
                }
            }
            if($alreadyExists===false){
                $filteredBunchOfCommand[]=$command;
            }
        }


        $secondAttempt=array();
		foreach ( $filteredBunchOfCommand as $command ) {
			if (is_array ( $command )) {
				if ($hasProceededToUnPrefixing === FALSE && $command [PdSCommand] > PdSUpdate) {
					// Un prefix after running all  commands.
					$unPrefixingFailures = $this->_unPrefix ( $treeId, $syncIdentifier );
					if (count ( $unPrefixingFailures ) > 0) {
						return $unPrefixingFailures;
					}
					$hasProceededToUnPrefixing = TRUE;
				}
				$result = $this->_decodeAndRunCommand ( $syncIdentifier, $command, $treeId );
				if ($result != NULL) {
                    $secondAttempt[]=$command;
				}
			} else {
				$failures [] = $command . ' is not an array';
			}
			if (isset ( $result )) {
				$failures [] = $result;
			}
			$result = NULL;
		}

        // If we encounter a problem of dependency (order of operation e.g a move before a dependant copy)
        foreach ( $secondAttempt as $command ) {
            if (is_array ( $command )) {
                $result = $this->_decodeAndRunCommand($syncIdentifier, $command, $treeId);
                if ($result != NULL) {
                    $failures [] = $result;
                }
            }
            $result = NULL;
        }

		if (count ( $failures ) > 0) {
			return $failures;
		} else {
			if($hasProceededToUnPrefixing==FALSE){
				$unPrefixingFailures = $this->_unPrefix ( $treeId, $syncIdentifier );
				if (count ( $unPrefixingFailures ) > 0) {
					return $unPrefixingFailures;
				}
			}
			$this->ioManager->mkdir ( $this->ioManager->absolutePath ( $treeId, METADATA_FOLDER ) );
			if ($this->ioManager->saveHashMap ( $treeId, $finalHashMapFilePath )) {
				
				return NULL;
			} else {
				$failures [] = 'Error when saving the hashmap';
				return $failures;
			}
		}
	}
	private function _compareCommand($a, $b) {

/*
        'PdSCreate' -> 0
        'PdSUpdate' -> 1
        'PdSMove' -> 2
        'PdSCopy' -> 3
        'PdSDelete' -> 4


        $aOrder=$a[PdSCommand];
        $bOrder=$b[PdSCommand];

*/
		return ($a [PdSCommand] > $b [PdSCommand]);
	}

    /**
     * Finalizes the bunch of command
     *
     * @param $treeId
     * @param string $syncIdentifier
     * @internal param string $finalHashMapFilePath
     * @return array
     */
	private function _unPrefix($treeId, $syncIdentifier) {
		$failures = array ();
		foreach ( $this->listOfFiles as $file ) {
			if (substr ( $file, - 1 ) != "/") {
				$relativePath = dirname ( $file ) . DIRECTORY_SEPARATOR . $syncIdentifier . basename ( $file );
				$protectedPath = $this->ioManager->absolutePath ( $treeId, $relativePath );
				if ($this->ioManager->exists ( $protectedPath )) {
					$success = $this->ioManager->rename ( $protectedPath, $this->ioManager->absolutePath ( $treeId, $file ) );
				} else {
					$failures [] = 'Unexisting path : ' . $protectedPath . ' -> ' . $treeId . ' (' . $relativePath . ') ';
				}
			} else {
				// It is a folder with do not prefix currently the folders
			}
		}
        return $failures;
	}
	
	/**
	 * Decodes and runs the command
	 *
	 * @param
	 *        	$syncIdentifier
	 * @param array $cmd        	
	 * @param string $treeId        	
	 * @return string on error, or null on success
	 */
	private function _decodeAndRunCommand($syncIdentifier, array $cmd, $treeId) {
		if (count ( $cmd )> 1 ) {
			$command = $cmd [0];
			// Absolute paths
			$destination = $this->ioManager->absolutePath ( $treeId, $cmd [PdSDestination] );
			$source = $this->ioManager->absolutePath ( $treeId, $cmd [PdSSource] );
            $sourceExistsString=($this->ioManager->exists($source))?"Yes":"No";
            $destinationExistsString=($this->ioManager->exists($destination))?"Yes":"No";

			switch ($command) {
				case PdSCreate :
					if (! isset ( $cmd [PdSDestination] )) {
						return 'PdSDestination must be non null :' . $cmd;
					}
					// There is no real FS action to perform
					// The file should only be "unPrefixed"
					// We only add the file to listOfFiles to be unPrefixed
					$this->listOfFiles [] = $cmd [PdSDestination];
					return NULL;
					break;
					case PdSUpdate :
						if (! isset ( $cmd [PdSDestination] )) {
							return 'PdSDestination must be non null :' . $cmd;
						}
						// There is no real FS action to perform
						// The file should only be "unPrefixed"
						// We only add the file to listOfFiles to be unPrefixed
						$this->listOfFiles [] = $cmd [PdSDestination];
						return NULL;
						break;
				case PdSCopy :
					if ($this->ioManager->copy ( $source, $destination )) {
						return NULL;
					} else {
                        if(($this->ioManager->exists($destination)==true)
                            && ($this->ioManager->exists($source)==false)){
                            return NULL; // We keep the current destination file (May be inferred by a bad client sequence)
                        }
						return 'PdSCopy error source:' . $source .'(exists ='.$sourceExistsString.') destination: ' . $destination.' (exists ='.$destinationExistsString.')';
                    }
					break;
				case PdSMove :
					if ($this->ioManager->rename ( $source, $destination )) {
						return NULL;
					} else {
                        if(($this->ioManager->exists($destination)==true)
                            && ($this->ioManager->exists($source)==false)){
                            return NULL; // We keep the current destination file (May be inferred by a bad client sequence)
                        }
						return 'PdSMove error source:' . $source .'(exists ='.$sourceExistsString.') destination: ' . $destination.' (exists ='.$destinationExistsString.')';
					}
					break;
				case PdSDelete :
					if ($this->ioManager->delete ( $destination )) {
						return NULL;
					} else {
                        if($this->ioManager->exists($destination)==false){
                            return NULL;// There was no need to delete an unexisting path
                        }
						return 'PdSDelete error on ' . $destination.'(exists ='.$destinationExistsString.')';
					}
				default :
					break;
			}
		}
		return 'CMD ' . json_encode ( $cmd ) . ' is not valid';
	}
}
?>