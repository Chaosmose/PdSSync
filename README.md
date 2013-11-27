# PdSSync #

A simple delta synchronizer for large repositories.
The synchronization relies on a client software and if necessary a mediation service currently implemented in PHP.
PdSSync is still in early development phases do not use in any project !


## Objective C ##
The objective c lib is a synchronisation client that synchronizes local A -\> B and distant set of files by using a mediation service MASTER  -\> \[ mediation server ] -\> CLIENTS

## PdSSyncPhp ##
A very simple PHP sync restfull service to use in conjonction with PdSSync

###For status code list check :###
+ [www.w3.org] (http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html title="www.w3.org")
+ [www.ietf.org] (http://www.ietf.org/assignments/http-status-codes/http-status-codes.xml title="www.ietf.org")

* 1xx: Informational - Request received, continuing process
* 2xx: Success - The action was successfully received, understood, and accepted
* 3xx: Redirection - Further action must be taken in order to complete the request
* 4xx: Client Error - The request contains bad syntax or cannot be fulfilled
* 5xx: Server Error - The server failed to fulfill an apparently valid request

###Important client errors ###

*401 => 'Unauthorized' : if auth is required
*423 => 'Locked' : if locked

### End points ###

GET distantTree (string identifier, array paths<optional>)
Returns the distant tree or subtree (string json)
Succes status code : 200 => 'OK'

POST uploadToRelativePath (string relativePath, string syncIdentifier)
Returns success on completion + the location: /uri/resources  ou Content-Location 
The upload path ".<syncIndentifier>_<file name>"
Succes status code : 201 => 'Created'

POST (string json) finalizeWithOperations (string syncIdentifier, array operations, string finalTree)
1. Locks 
2. Finalize the synchronization bunch 
3. Unlocks
Returns success on completion
Remains locked if there is an issue.
Succes status code : 200 => 'OK'
(200 => 'Accepted') 


#### Distant FS operation : ####
* unPrefix (string syncIdentifier) private 
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

