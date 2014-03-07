<?php

include_once 'api/v1/PdSSyncConst.php';
require_once 'api/v1/classes/CommandInterpreter.class.php';
require_once 'api/v1/classes/IOManager.class.php';

/**
 * A simple API facade in one file
 * Inspired by http://coreymaynard.com/blog/creating-a-restful-api-with-php/
 * 
 * Optimized according to google bests practices :  https://developers.google.com/speed/articles/optimizing-php
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
	protected $file = NULL;
	
	/**
	 * The command interpreter
	 * 
	 * @var CommandInterpreter
	 */
	protected $interpreter = NULL;
	
	/**
	 * The IOManager is currently a FS abstraction
	 * @var IOManager
	 */
	protected $ioManager = NULL;
	
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
				return $this->_response ( $this->method, 400 );
				break;
		}
		if (( int ) method_exists ( $this, $this->endpoint ) > 0) {
			return  $this->{$this->endpoint} ( $this->args );
		}
		return $this->_response ( '', 400 );
	}
	
	// ///////////////
	// End points
	// //////////////
	
	// http GET PdsSync.api.local/api/v1/reachable/
	
	
	protected function reachable() {
		if ($this->method == 'GET') {
			return $this->_response ( NULL, 200 );
		} else {
			$infos = array ();
			$infos [INFORMATIONS_KEY] = 'Method GET required';
			$infos [METHOD_KEY] = 'GET';
			return $this->_response ( $infos, 405 );
		}
	}
	
	// http -v -f POST PdsSync.api.local/api/v1/install/ key='6ca0c48126a15939-2c938833d4678913'
	
	protected function install() {
		if ($this->method == 'POST') {
			$this->ioManager = new IOManager ();
			if (isset ( $this->request ['key'] ) && $this->request ['key'] == CREATIVE_KEY) {
				$this->ioManager->install();
				return $this->_response ( NULL, 201 );
			} else {
				return $this->_response ( NULL, 401 );
			}
		} else {
			$infos = array ();
			$infos [INFORMATIONS_KEY] = 'Method POST required';
			$infos [METHOD_KEY] = 'POST';
			return $this->_response ( $infos, 405 );
		}
	}
	
	// http -v -f POST PdsSync.api.local/api/v1/create/tree/unique-public-id-1293 key='6ca0c48126a15939-2c938833d4678913'
	
	protected function create() {
		if ($this->method == 'POST') {
			
			if (isset ( $this->verb ) && count ( $this->args ) > 1 && $this->args [0] == "tree") {
				$treeId = $this->args [1];
				if(strlen($treeId)<20){
					return $this->_response ( NULL, 406 );
				}
				if (isset ( $this->request ['key'] ) && $this->request ['key'] == CREATIVE_KEY) {
					$this->ioManager = new IOManager ();
					$result=$this->ioManager->createTree($treeId);
					if($result==NULL){
						return $this->_response ( NULL, 201 );
					}else {
						return  $this->_response ( $result, 400 );
					}
				} else {
					return $this->_response ( NULL, 401 );
				}
			} else {
				return $this->_response ( 'Unknown entity' . $this->args [0], 400 );
			}
		} else {
			$infos = array ();
			$infos [INFORMATIONS_KEY] = 'Method POST required';
			$infos [METHOD_KEY] = 'POST';
			return $this->_response ( $infos, 405 );
		}
	}
	
	// http -v GET PdsSync.api.local/api/v1/hashMap/tree/unique-public-id-1293
	
	/**
	 * Returns the hash map
	 *
	 * @return multitype: string
	 */
	protected function hashMap() {
		if ($this->method == 'GET') {
			$this->ioManager = new IOManager ();
			if (isset ( $this->request ['path'] )) {
				if (isset ( $this->verb ) && count ( $this->args ) > 0) {
					$treeId = $this->args [0];
				} else {
					$treeId = 0;
				}
				
				// IMPORTANT
				// Return a 401 if not authorized.
				// A 301 on redirection.
				// When the ACL changes on a tree its Id changes ??
				
				$location = $this->ioManager->uriFor($treeId, METADATA_FOLDER.HASHMAP_FILENAME);
				header (  'Location:  '. $location,true,307);
				exit;
				
			}
			return $this->_response ( 'Hash map not found ', 404 );
		} else {
			$infos = array ();
			$infos [INFORMATIONS_KEY] = 'Method GET required';
			$infos [METHOD_KEY] = 'GET';
			return $this->_response ( $infos, 405 );
		}
	}
	
	// http -v GET PdsSync.api.local/api/v1/file/tree/unique-public-id-1293/?path=a/file1.txt
	
	/**
	 * Redirects to a file
	 *
	 * @return multitype: string
	 */
	protected function file() {
		if ($this->method == 'GET') {
			if (isset ( $this->request ['path']  )) {
				if (isset ( $this->verb ) && ($this->verb == "tree") && count ( $this->args ) > 0) {
					$treeId = $this->args [0];
				} else {
					$treeId = 0;
				}
				
				// IMPORTANT 
				// Return a 401 if not authorized.
				// A 307 on redirection.
				
				// Principles  : 
				// 1 resolution ( to prevent from hazardous discovery )
				// 2 @todo  acl
				// 3 use apache as much as possible
				// 4 files may be crypted ( and decrypted  client side only)
				
				$this->ioManager = new IOManager ();
				$location = $this->ioManager->uriFor($treeId, $this->request ['path']);
				header (  'Location:  '. $location,true,307);
				exit;
			}
			return $this->_response ( 'Hash map not found ', 404 );
		} else {
			$infos = array ();
			$infos [INFORMATIONS_KEY] = 'Method GET required';
			$infos [METHOD_KEY] = 'GET';
			return $this->_response ( $infos, 405 );
		}
	}
	
	// http -v -f POST PdsSync.api.local/api/v1/uploadFileTo/tree/5318a867a4e76/ destination='a/file1.txt' syncIdentifier='your-syncID_' source@~/Documents/Samples/text1.txt doers='' undoers=''
	
	/**
	 * Upload the file to the relative path
	 *
	 * @return multitype: string
	 */
	protected function uploadFileTo() {
		if ($this->method == 'POST' ) {
			if (isset ( $this->verb ) && count ( $this->args ) > 0) {
				$treeId = $this->args [0];
			} else {
				$treeId = '';
			}
			// @todo support doers / undoers
			if ( isset($this->request ['destination']) && Isset($this->request ['syncIdentifier']) && isset ( $_FILES ['source'] )) {
				$this->ioManager = new IOManager ();
				$d=  dirname($this->request ['destination']).DIRECTORY_SEPARATOR.$this->request ['syncIdentifier'].basename($this->request ['destination']);
				$uploadfile = $this->ioManager->absolutePath($treeId,$d) ;
				if ($this->ioManager->move_uploaded ( $_FILES ['source'] ['tmp_name'], $uploadfile )) {
					return $this->_response ( NULL, 201 );
				} else {
					return $this->_response ( NULL, 201 );
				}
			} else {
				return $this->_response ( 'destination, source and syncIdentifier are required', 400 );
			}
		} else {
			$infos = array ();
			$infos [INFORMATIONS_KEY] = 'Method POST required';
			$infos [METHOD_KEY] = $this->method ;
			return $this->_response ( $infos, 405 );
		}
	}
	
	
	/*
		http -v  POST PdsSync.api.local/api/v1/finalizeTransactionIn/tree/5318a867a4e76/ commands:='[ [   0 ,"a/file1.txt" ]]' syncIdentifier='your-syncID_' hashMap='[]'
	 */
	
	/**
	 *  Finalize the synchronization transaction with a bunch, then save the hashMap.
	 *
	 * @return multitype: string
	 */
	protected function finalizeTransactionIn() {
		if ($this->method == 'POST') {
			try {
				// http://www.php.net/manual/en/wrappers.php.php
				$post= json_decode( file_get_contents('php://input'),true ) ;// A raw post  not a Multi part form.
			} catch (Exception $e) {
				return $this->_response ( 'commands must be a valid json array : '.$post ['commands'], 400 );
			}
			if( isset ($post) && isset ( $post ['syncIdentifier'] )  && isset($post ['commands']) && isset($post ['hashMap']) ) {
				if (is_array ($post['commands'])){
					if (isset ( $this->verb ) && count ( $this->args ) > 0) {
						$treeId = $this->args [0];
					} else { 
						$treeId = '';
					}
					// @todo We will inject contextual information to deal with acl (current tree owner, current user, ...)
					$errors=$this->getInterpreter()->interpretBunchOfCommand ($treeId, $post ['syncIdentifier'], $post['commands'], $post ['hashMap'] );
					if($errors==NULL){
						return $this->_response ( NULL, 200 );
					} else {
						return $this->_response ( $errors , 417 );
					}
				} else {
					return $this->_response ( 'commands must be an array = '.$post, 400 );
				}
			} else {
				return $this->_response (
						 	'commands :' .   $post ['commands']  . 
							', hashMap:' . $post ['hashMap'] . 
							',  syncIdentifier:' .$post['syncIdentifier'] . ' are required', 400
						 );
			}
		} else {
			open . $infos = array ();
			$infos [INFORMATIONS_KEY] = 'Method POST required';
			$infos [METHOD_KEY] =$this->method ;
			return $this->_response ( $infos, 405 );
		}
	}
	

	/**
	 *
	 * @param string $data        	
	 * @param int $status        	
	 * @return string
	 */
	private function _response($data, $status = 200) {
		// we use this for JSON response only
		// We can accounter also redirections so we prefer to set 
		// the header contextually.
		header ( "Access-Control-Allow-Orgin: *" );
		header ( "Access-Control-Allow-Methods: *" );
		header ( "Content-Type: application/json" );
		$header = 'HTTP/1.1 ' . $status . ' ' . $this->_requestStatus ( $status );
		header ( $header );
		if (isset ( $data )) {
			return json_encode ( $data );
		} else {
			return NULL;
		}
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
	protected function _requestStatus($code) {
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
	
	
	// Setters and getters 
	
	/**
	 * A lazy loading command interpreter
	 * with its associated file manager
	 * @return the $interpreter
	 */
	protected function getInterpreter() {
		if(!$this->interpreter){
			$this->interpreter=new CommandInterpreter();
			if(!$this->ioManager){
				$this->ioManager=new IOManager();
			}
			$this->interpreter->setIOManager($this->ioManager);
		}
		return $this->interpreter;
	}
}
