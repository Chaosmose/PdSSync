<?php

include 'api/v1/PdSSyncConst.php';
require_once 'api/v1/classes/TreeGenerator.class.php';
require_once 'api/v1/classes/OperationsInterpreter.class.php';
require_once 'api/v1/classes/BackgroundExecution.class.php';
/**
  *  A simple API facade in one file
  *  Inspired by http://coreymaynard.com/blog/creating-a-restful-api-with-php/
  *  
  * @author Benoit Pereira da Silva
  * @copyright https://github.com/benoit-pereira-da-silva/PdSSync
  */
class PdSSyncAPI {
	

	/**
	 * Property: method
	 * The HTTP method this request was made in, either GET, POST, PUT or DELETE
	 */
	protected $method = '';
	/**
	 * Property: endpoint
	 * The Model requested in the URI.
	 * eg: /files
	 */
	protected $endpoint = '';
	/**
	 * Property: verb
	 * An optional additional descriptor about the endpoint, used for things that can
	 * not be handled by the basic methods.
	 * eg: /files/process
	 */
	protected $verb = '';
	/**
	 * Property: args
	 * Any additional URI components after the endpoint and verb have been removed, in our
	 * case, an integer ID for the resource.
	 * eg: /<endpoint>/<verb>/<arg0>/<arg1>
	 * or /<endpoint>/<arg0>
	 */
	protected $args = Array ();
	/**
	 * Property: file
	 * Stores the input of the PUT request
	 */
	protected $file = Null;
	
	/**
	 * Constructor: __construct
	 * Allow for CORS, assemble and pre-process the data
	 */
	public function __construct() {
		// Requests from the same server don't have a HTTP_ORIGIN header
		if (! array_key_exists ( 'HTTP_ORIGIN', $_SERVER )) {
			$_SERVER ['HTTP_ORIGIN'] = $_SERVER ['SERVER_NAME'];
		}
		$request = $_REQUEST ['request'];
		$origin = $_SERVER ['HTTP_ORIGIN'];
		header ( "Access-Control-Allow-Orgin: *" );
		header ( "Access-Control-Allow-Methods: *" );
		header ( "Content-Type: application/json" );
		$this->args = explode ( '/', rtrim ( $request, '/' ) );
		$this->endpoint = array_shift ( $this->args );
		if (array_key_exists ( 0, $this->args ) && ! is_numeric ( $this->args [0] )) {
			$this->verb = array_shift ( $this->args );
		}
		$this->method = $_SERVER ['REQUEST_METHOD'];
		if ($this->method == 'POST' && array_key_exists ( 'HTTP_X_HTTP_METHOD', $_SERVER )) {
			if ($_SERVER ['HTTP_X_HTTP_METHOD'] == 'DELETE') {
				$this->method = 'DELETE';
			} else if ($_SERVER ['HTTP_X_HTTP_METHOD'] == 'PUT') {
				$this->method = 'PUT';
			} else {
				throw new Exception ( "Unexpected Header" );
			}
		}
	}
	
	/**
	 * The generic running method
	 *
	 * @return string
	 */
	public function run() {
		switch ($this->method) {
			case 'DELETE' :
			case 'POST' :
				$this->request = $this->_cleanInputs ( $_POST );
				break;
			case 'GET' :
				$this->request = $this->_cleanInputs ( $_GET );
				break;
			case 'PUT' :
				$this->request = $this->_cleanInputs ( $_GET );
				$this->file = file_get_contents ( "php://input" );
				break;
			default :
				return $this->_response($this->method,400);
				break;
		}
		if (( int ) method_exists ( $this->endpoint ) > 0) {
			return $this->_response ( $this->{$this->endpoint} ( $this->args ) );
		}
		return $this->_response ( '', 400 );
	}
	
	
	
	// ///////////////
	// End points
	// //////////////

	
	
	/**
	 * Returns the tree $paths is null we use the global repository tree.
	 *
	 * @param array $relativePaths        	
	 * @return multitype: string
	 */
	protected function distantTree(array $relativePaths = array()) {
		if ($this->method == 'GET') {
			$this->_createFoldersIfNecessary();
			$fileName=crc32(  json_encode($relativePaths)  ) .TREE_SUFFIX ;
			$filePath=TREES_FOLDER_PATH.$fileName; 
			$locker=$fileName.LOCKED_SUFFIX;
			$lockerPath=TREES_FOLDER_PATH.$locker;
			if (file_exists($lockerPath)){
				// there is a locker and operation in progress.
				return $this->_response('Operation in progress on '.$fileName,423);
			}
			if(file_exists($filePath)){
				$tree=json_decode(file_get_contents($filePath));
				return $this->_response($tree,200);
			}else{
				// Generate the tree using a background process
				$process = new BackgroundProcess();
				$process->runPHP('
							$treeGenerator=new TreeGenerator();
							$treeGenerator->treeForRelativePaths('.$relativePaths.');
						');
				return $this->_response('Operation in progress on '.$fileName , 204 );
			}
		} else {
			$infos=array();
			 $infos[INFORMATIONS_KEY]='Method GET required';
			 $infos[METHOD_KEY]='GET';
			return $this->_response($infos,405);
		}
	}
						
	
	/**
	 * Upload the file to the relative path
	 *
	 * @param string $relativePath        	
	 * @param string $syncIdentifier        	
	 * @return multitype: string
	 */
	protected function uploadToRelativePath($relativePath, $syncIdentifier) {
		if ($this->method == 'POST') {
			// TODO 
			// DEAL WITH THE UPLOAD
			return $this->_response('',201);
		} else {
			$infos=array();
			 $infos[INFORMATIONS_KEY]='Method POST required';
			 $infos[METHOD_KEY]='POST';
			return $this->_response($infos,405);
		}
	}
	
	/**
	 * Locks, Finalize the synchronization bunch, then Unlocks.
	 *
	 * @param string $syncIdentifier        	
	 * @param array $operations        	
	 * @param string $finalTree        	
	 * @return multitype: string
	 */
	protected function finalizeSynchronization($syncIdentifier, array $operations, $finalTree) {
		if ($this->method == 'POST') {
			if(OperationsInterpreter::interpretOperation($syncIdentifier, $operations, $finalTree)){
				return  $this->_response('',200);
			}else{
				//@TODO qualify
				return  $this->_response('',500);
			}
		} else {
			$infos=array();
			$infos[INFORMATIONS_KEY]='Method POST required';
			$infos[METHOD_KEY]='POST';
			return $this->_response($infos,405);
		}
	}
	
	
	// ///////////////
	// PRIVATE
	// //////////////
	

	/**
	 * Creates the trees and repository folder.
	 */
	private  function _createFoldersIfNecessary(){
		if(!file_exists(TREES_FOLDER_PATH))
			mkdir(TREES_FOLDER_PATH);
		if(!file_exists(REPOSITORY_PATH))
			mkdir(REPOSITORY_PATH);
	}
	
	/**
	 *
	 * @param unknown_type $data        	
	 * @param unknown_type $status        	
	 * @return string
	 */
	private function _response($data, $status = 200) {
		header ( "HTTP/1.1 " . $status . " " . $this->_requestStatus ( $status ) );
		return json_encode ( $data );
	}
	
	/**
	 * Cleans up the inputs
	 *
	 * @param unknown_type $data        	
	 * @return Ambigous <string, multitype:NULL >
	 */
	private function _cleanInputs($data) {
		$clean_input = Array ();
		if (is_array ( $data )) {
			foreach ( $data as $k => $v ) {
				$clean_input [$k] = $this->_cleanInputs ( $v );
			}
		} else {
			$clean_input = trim ( strip_tags ( $data ) );
		}
		return $clean_input;
	}
	
	// ///////////////
	// protected
	// //////////////
	
	/**
	 *
	 * @param int $code        	
	 * @return string
	 */
	protected  function _requestStatus( $code) {
		$status = array (
				100 => 'Continue',
				101 => 'Switching Protocols',
				200 => 'OK',
				201 => 'Created',
				202 => 'Accepted',
				203 => 'Non-Authoritative Information',
				204 => 'No Content',
				205 => 'Reset Content',
				206 => 'Partial Content',
				300 => 'Multiple Choices',
				301 => 'Moved Permanently',
				302 => 'Found',
				303 => 'See Other',
				304 => 'Not Modified',
				305 => 'Use Proxy',
				306 => '(Unused)',
				307 => 'Temporary Redirect',
				400 => 'Bad Request',
				401 => 'Unauthorized',
				402 => 'Payment Required',
				403 => 'Forbidden',
				404 => 'Not Found',
				405 => 'Method Not Allowed',
				406 => 'Not Acceptable',
				407 => 'Proxy Authentication Required',
				408 => 'Request Timeout',
				409 => 'Conflict',
				410 => 'Gone',
				411 => 'Length Required',
				412 => 'Precondition Failed',
				413 => 'Request Entity Too Large',
				414 => 'Request-URI Too Long',
				415 => 'Unsupported Media Type',
				416 => 'Requested Range Not Satisfiable',
				417 => 'Expectation Failed',
				423 => 'Locked',
				500 => 'Internal Server Error',
				501 => 'Not Implemented',
				502 => 'Bad Gateway',
				503 => 'Service Unavailable',
				504 => 'Gateway Timeout',
				505 => 'HTTP Version Not Supported' 
		);
		return ($status [$code]) ? $status [$code] : $status [500];
	}
}
