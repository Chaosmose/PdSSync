## Disclaimer ##
**PdSSync** is still in early development phases do not use in any project !
Currently the web api is prototyped in PHP, it will be ported to JAVA and will support MessagePack in 2014.

# PdSSync #

A simple delta synchronizer for documents and data between devices.It allows to synchronizes local and distant grouped sets of files.The standard synchronization topology relies on a client software and a light blind Restfull service, but it can work locally and using P2P. 

## Approach ##

- do not rely on any framework
- the client should insure the security layer
- delegate as much as possible the synchronization logic to the clients to distribute the load and to save server charge and bandwidth
- keep it as minimal and simple as possible
- do not focus on conflict resolution but on fault resilience (there is no transactional guarantee)
- allow very efficient caching and mem caching strategy (we will provide advanced implementation samples)
- support hash maps encryption
- allow advanced hashing strategy ( like considering that a modified file should not be synchronized bec) 

## HashMap  ##

For PdSSync a **hashMap** is a dictionary with for a given folder the list of all its files relative path as a key and a Hash as a value or the inverse.

The master maintains one hashMap per root folder, the hash map is crypted.

Json representation :

```javascript
	{
		 "hashToPath" : {
    		 "1952419745" : "47b2e7fb27643408f95f7c66d995fbe9.music",
    		 "2402594160" : "folder1/4fd6de231a723be15375552928c9c52a.track",	
  		}
	}
```
## DeltaPathMap ##

A **DeltaPathMap** references the differences between two **hashMap** and furnish the logic to planify downloading or uploading command operations for clients according to their role.

Json representation : 

```javascript
	{
		"createdPaths":[]
		"deletedPaths":[]
		"updatedPaths":["folder1/4fd6de231a723be15375552928c9c52a.track"]
	}
```

## Synchronization process synopsis ##

With 1 Source client (Objc), 1 sync service(php), and n Destination clients(Objc)

1. Source -> downloads the **hashMap** (if there is no hasMap the delta will be the current local)
2. Source -> proceed to **DeltaPathMap** creation and command provisionning
3. Source -> uploads files with a .upload prefix to the service 
4. Source -> uploads the hasMap of the current root folder and finalize the transaction (un prefix the files, and call the sanitizing procedure =  removal of orpheans, **Optionaly** the synch server can send a push notification to the slave clients to force the step 5)
5. Destination -> downloads the current **hashMap**
6. Destination -> proceed to **DeltaPathMap** creation and command provisionning
7. Destination -> downloads the files (on any missing file the task list is interrupted, the local hash map is recomputed and we step back to 5)
8. Destination -> on completion the synchronization is finalized. (We redownload the **hashmap** and compare to conclude if stepping back to 5 is required.)


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

You can use [Httpie](https://github.com/jkbr/httpie) to test the endpoints. 
```shell
http GET dev.local/api/v1/reachable/

http -v -f POST dev.local/api/v1/install/ adminKey='YOUR KEY'

http -v -f POST dev.local/api/v1/create/tree/unique-public-id key='YOUR KEY'

http -v GET dev.local/api/v1/hashMap/tree/unique-public-id&redirect=true&returnValue=false

http -v -f POST dev.local/api/v1/uploadFileTo/tree/unique-public-id/ destination='file1.txt'  syncIdentifier='xx' source@~/Documents/text1.txt

http -v -f POST dev.local/api/v1/finalizeSynchronization/ commands[]='<encodedCommand>'  syncIdentifier='xx' hashMap='<hashmap>'

http -v GET dev.local/api/v1/file/tree/unique-public-id/?path=a/file1.txt&redirect=false&returnValue=false
```
#### Commands  : ####

Any command is encoded in an array.
Json Encoded command [PdSCopy,<PdSDestination>,<PdSSource>] : [1,'a/a.caf','b/c/c.caf'] will copy the file from 'b/c/c.caf' to 'a/a.caf'

##### Sync CMD ####
```c
typedef NS_ENUM (NSUInteger,
                  PdSSyncCommand) {
    PdSCreateOrUpdate   = 0 , // W destination
    PdSCopy     		= 1 , // R source W destination
    PdSMove     		= 2 , // R source W destination
    PdSDelete   		= 3 , // W source
} ;

typedef NS_ENUM(NSUInteger,
                PdSSyncCMDParam) {
    PdSDestination = 0,
    PdSSource      = 1
} ;
```
##### Admin CMD  #####
```c
typedef NS_ENUM (NSUInteger,
                 PdSAdminCommand) {
    PdsSanitize    = 4 , // X on tree
    PdSChmod       = 5 , // X on tree
    PdSForget      = 6 , // X on tree
} ;

typedef NS_ENUM(NSUInteger,
                PdSAdminCMDParam) {
    PdSPoi         = 0,
    PdSDepth       = 1,
    PdSValue       = 2
} ;
```


