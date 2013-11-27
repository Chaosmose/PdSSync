# PdSSync #

A simple delta synchronizer for large repositories.
The synchronization relies on a client software and if necessary a mediation service currently implemented in PHP.
It allows to synchronizes local and distant sets of files by using a mediation service master  -> mediation -> clients
PdSSync is still in early development phases do not use in any project !

## Key notions ##
For PdSSync a **tree** or a **subtree** is a dictionary with for a given folder a list of all its files and folder relative path as a key and a CRC32 of the file as a value.
	In json : { 'a/a.caf': 299993900 , ... } 
	
## Objective C ##
The objective c lib 

## PdSSyncPhp ##
A very simple PHP sync restfull service to use in conjonction with PdSSync

### Status codes ###

* 1xx: Informational - Request received, continuing process
* 2xx: Success - The action was successfully received, understood, and accepted
* 3xx: Redirection - Further action must be taken in order to complete the request
* 4xx: Client Error - The request contains bad syntax or cannot be fulfilled
* 5xx: Server Error - The server failed to fulfill an apparently valid request

#### Notable client errors ####

* 401 => 'Unauthorized' : if auth is required
* 423 => 'Locked' : if locked

##### Status code references ####
[www.w3.org] (http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html title="www.w3.org"), [www.ietf.org] (http://www.ietf.org/assignments/http-status-codes/http-status-codes.xml title="www.ietf.org")

### End points ###

1. GET **distantTree** (array paths)
Returns the distant tree or subtree (string json)
	Succes status code : 
	200 => 'OK'
	204 => 'No Content' ( the tree will be generated in background)

2. POST **uploadToRelativePath** (string relativePath, string syncIdentifier)
Returns success on completion + the location: /uri/resources  ou Content-Location 
The upload path ".syncIndentifier_file name"

	Succes status code : 201 => 'Created'

3. POST (string json) **finalizeSynchronization** (string syncIdentifier, array operations, string finalTree)
Locks, Finalize the synchronization bunch then Unlocks.

	Succes status code : 200 => 'OK'



#### Distant FS operation : ####
* unPrefix (string syncIdentifier) private operation performed on finalizeSynchronization
* move : for renaming or path changing
* copy : for duplication 
* remove : to delete a path, and sub paths

#### Operation keys : ####

	typedef enum _PdSSyncOperation 
		PdSCopy      = 0,
		PdSMove      = 1,
		PdSDelete    = 2
	} PdSSyncOperation;

	typedef enum _PdSSyncOperationParams 
		PdSSource      = 0,
		PdSDestination = 1
	} PdSSyncOperationParams;
	
	Json Encoding [ { '0':['a/a.caf','b/c/c.caf'] } ] will copy the file from 'a/a.caf' to 'b/c/c.caf'

