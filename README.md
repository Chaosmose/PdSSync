# PdSSync #

A simple delta synchronizer for large repositories.
The synchronization relies on a client software and if necessary a mediation service currently implemented in PHP.
It allows to synchronizes local and distant sets of files grouped in a root folder by using a mediation service.
PdSSync is still in early development phases do not use in any project !


## HashMap  ##

For PdSSync a **hashMap** is a dictionary with for a given folder the list of all its files relative path as a key and a Hash as a value or the inverse.

The master maintains one hashMap per root folder, the hash map is crypted.

Json representation :

	{
		 "hashToPath" : {
    		 "1952419745" : "47b2e7fb27643408f95f7c66d995fbe9.music",
    		 "2402594160" : "folder1/4fd6de231a723be15375552928c9c52a.track",	
  		}
	}

## DeltaPathMap ##

A **DeltaPathMap** references the similarities and differences between two **hashMap** and furnish the logic to planify downloading or uploading command operations for clients according to their role.

Json representation : 

	{
		"similarPaths":["47b2e7fb27643408f95f7c66d995fbe9.music"]
		"createdPaths":[]
		"deletedPaths":[]
		"updatedPaths":["folder1/4fd6de231a723be15375552928c9c52a.track"]
	}


## Synchronization process synopsis ##

With 1 master client (Objc), 1 sync service(php), and n slaves clients(Objc)

1. Master -> downloads the **hashMap** (if there is no hasMap the delta will be the current local)
2. Master -> proceed to **DeltaPathMap** creation and command provisionning
3. Master -> uploads files with a .download prefix to the sync 
4. Master -> uploads the hasMap of a given channel and finalize the transaction (un prefix the files, and call the sanitizing procedure =  removal of orpheans, **Optionaly** the synch server can send a push notification to the slave clients to force the step 5)
5. Slave -> downloads the current **hashMap**
6. Slave -> proceed to **DeltaPathMap** creation and command provisionning
7. Slave -> downloads the files (on any missing file the task list is interrupted and go to 5)
8. Slave -> on completion the synchronization is finalized. With a possible interruption of the current song +  redownload the hashmap and compare to conclude if 5 is required.

## Objective C ##
The objective c lib 

## PdSSyncPhp ##
A very simple PHP sync restfull service to use in conjonction with PdSSync objc client

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
[www.w3.org] (http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html), [www.ietf.org] (http://www.ietf.org/assignments/http-status-codes/http-status-codes.xml)

### End points ###

1. GET **distantHashMap** (array paths)
Returns the distant hashMap or subhashMap (string json)
	Succes status code : 
	200 => 'OK'
	204 => 'No Content' ( the hashMap will be generated in background)

2. POST **uploadToRelativePath** (string relativePath, string syncIdentifier)
Returns success on completion + the location: /uri/resources  ou Content-Location 
The upload path ".syncIndentifier_file name"

	Succes status code : 201 => 'Created'

3. POST (string json) **finalizeSynchronization** (string syncIdentifier, array operations, string finalhashMap)
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

