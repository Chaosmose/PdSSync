<?php

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
		// Sort the command to execute creative command first and  destructive commands at the end.
		$sortedCommands=usort($bunchOfCommand,array ($this,'_compareCommand'));
		foreach ( $sortedCommands as $sortedCommands ) {
			if (is_array ( $command )) {
				$result = $this->_decodeAndRunCommand ( $syncIdentifier, $command, $treeId );
				if ($result != NULL) {
					$failures [] = $result;
				}
			} else {
				$failures [] = $command . ' is not an array';
			}
			if (isset ( $result )) {
				$failures [] = $result;
			}
			$result = NULL;
		}
		if (count ( $failures ) > 0) {
			return $failures;
		} else {
			return $this->_finalize ( $treeId, $syncIdentifier, $finalHashMapFilePath );
		}
	}
	
	private function  _compareCommand($a,$b){
		//Compare the command by PdSSyncCMDParamsRank
		// PdSCreateOrUpdate = 0
		// PdSCopy = 1
		// PdSMove = 2
		// PdSDelete = 3	
		return strnatcmp($a[PdSCommand], $b[PdSCommand]);
	}
	
	
	/**
	 * Finalizes the bunch of command
	 *
	 * @param string $syncIdentifier        	
	 * @param string $finalHashMapFilePath        	
	 */
	private function _finalize($treeId, $syncIdentifier, $finalHashMapFilePath) {
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
		if (count ( $failures ) > 0) {
			return $failures;
		} else {
			$this->ioManager->mkdir ( $this->ioManager->absolutePath ( $treeId, METADATA_FOLDER ) );
			if ($this->ioManager->saveHashMap ( $treeId, $finalHashMapFilePath )) {
				return $fileList;
			} else {
				$failures [] = 'Error when saving the hashmap';
				return $failures;
			}
		}
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
		if (count ( $cmd > 1 )) {
			$command = $cmd [0];
			// Absolute paths
			$destination = $this->ioManager->absolutePath ( $treeId, $cmd [PdSDestination] );
			$source = $this->ioManager->absolutePath ( $treeId, $cmd [PdSSource] );
			switch ($command) {
				case PdSCreateOrUpdate :
					if (! isset ( $cmd [PdSDestination] )) {
						return 'PdSDestination must be non null :' . $cmd;
					}
					// There is no real FS action to perform
					// We just added the file for finalization.
					$this->listOfFiles [] = $cmd [PdSDestination];
					return NULL;
					break;
				case PdSCopy :
					if ($this->ioManager->copy ( $source, $destination )) {
						return NULL;
					} else {
						return 'PdSCopy error';
					}
					return NULL;
					break;
				case PdSMove :
					if ($this->ioManager->rename ( $source, $destination )) {
						return NULL;
					} else {
						return 'PdSMove error source:' . $cmd [PdSSource] . ' destination: ' . $cmd [PdSDestination];
					}
					break;
				case PdSDelete :
					if ($this->ioManager->delete ( $destination )) {
						return NULL;
					} else {
						return 'PdSDelete error on ' . $cmd [PdSDestination];
					}
				default :
					break;
			}
		}
		return 'CMD ' . json_encode ( $cmd ) . ' is not valid';
	}
}
?>