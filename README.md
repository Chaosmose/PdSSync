## Disclaimer ##
**PdSSync** is still in early development phases do not use in any project !
Currently the web api is prototyped in PHP.

# PdSSync #

A simple delta synchronizer for documents and data between devices.It allows to synchronizes local and distant grouped sets of files.The standard synchronization topology relies on a client software and a light blind Restfull service, but it can work locally and using P2P.

## Approach ##

- do not rely on any server side framework
- the client should insure the security layer
- delegate as much as possible of the synchronization logic to the clients to distribute the load and to save server charge and bandwidth
- keep it as minimal and simple as possible
- do not focus on conflict resolution but on fault resilience (there is no transactional guarantee)
- allow very efficient caching and mem caching strategy (we will provide advanced implementation samples)
- support any encryption and cryptographic strategy
- allow advanced hashing strategy ( like : considering that a modified file should not be synchronized because the modification is not significant)

## HashMap  ##

For PdSSync a **HashMap** is a dictionary with for a given folder the list of all its files relative path as a key and a Hash as a value or the inverse.

The master maintains one HashMap per root folder, the hash map is crypted.

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

A **DeltaPathMap** references the differences between two **HashMap** and furnish the logic to planify downloading or uploading command operations for clients according to their role.

Json representation :

```javascript
	{
		"createdPaths":[],
		"copiedPaths":["folder1/a.mp3","folder2/a.mp3"],
		"deletedPaths":[],
		"movedPaths":["x.txt","folder1/y.txt"],
		"updatedPaths":["folder1/4fd6de231a723be15375552928c9c52a.track"],
	}
```

## Synchronization process synopsis ##

With 1 Source client (Objc), 1 sync service(php), and n Destination clients(Objc)

1. Source -> downloads the **HashMap** (if there is no HashMap the delta will be the current local)
2. Source -> proceed to **DeltaPathMap** creation and command provisionning
3. Source -> uploads files with a .upload prefix to the service
4. Source -> uploads the hasMap of the current root folder and finalize the transaction (un prefix the files, and call the sanitizing procedure =  removal of orpheans, **Optionaly** the synch server can send a push notification to the slave clients to force the step 5)
5. Destination -> downloads the current **HashMap**
6. Destination -> proceed to **DeltaPathMap** creation and command provisionning
7. Destination -> downloads the files (on any missing file the task list is interrupted, the local hash map is recomputed and we step back to 5)
8. Destination -> on completion the synchronization is finalized. (We redownload the **HashMap** and compare to conclude if stepping back to 5 is required.)


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

#### Commands  : ####

Any command is encoded in an array.
Json Encoded command [PdSCopy,<PdSDestination>,<PdSSource>] : [1,'a/a.caf','b/c/c.caf'] will copy the file from 'b/c/c.caf' to 'a/a.caf'

##### Sync CMD ####
```c
typedef NS_ENUM (NSUInteger,
                  PdSSyncCommand) {
    PdSCreate   = 0 , 
    PdSUpdate   = 1 ,
    PdSMove     = 2 , 
    PdSCopy     = 3 , 
    PdSDelete   = 4 
} ;


typedef NS_ENUM(NSUInteger,
                PdSSyncCMDParamRank) {
    PdSCommand     = 0,
    PdSDestination = 1,
    PdSSource      = 2
} ;

```

## How to proceed to basic tests with httpie ##

### Install httpie ###
https://github.com/jkbr/httpie

### You can update those keys on  in PdSSyncPhp/api/v1/PdSSyncConfig.php ###

1.CREATIVE_KEY
2.SECRET

### Create local files : ###

```shell
touch ~/Documents/Samples/text1.txt
echo "Eureka1" > ~/Documents/Samples/text1.txt

touch ~/Documents/Samples/text2.txt
echo "Eureka2" > ~/Documents/Samples/text2.txt

touch ~/Documents/Samples/hashmap.data
echo  "[]" > ~/Documents/Samples/hashmap.data
```

###  Usage sample of the end points ###

Replace your-base-url with your own base url

1.  Verify the reachability
```shell
http GET <your-base-url>api/v1/reachable/
```

2.  Install
```shell
http -v -f POST <your-base-url>api/v1/install/ key='default-creative-key'
```

3. Create a files trees
```shell
http -v -f POST  <your-base-url>api/v1/create/tree/1 key='default-creative-key'
http -v -f POST  <your-base-url>api/v1/create/tree/2 key='default-creative-key'
```

4. Touch the 1 tree to reset the public id, then try an unexisting ID
```shell
http -v -f POST <your-base-url>api/v1/touch/tree/1
http -v -f POST <your-base-url>api/v1/touch/tree/unexisting-tree
```
5. Grab the hashmap that should not exists
```shell
http -v GET  <your-base-url>api/v1/hashMap/tree/1/ redirect==true returnValue==false
```
6. Upload the files
```shell
http -v -f POST  <your-base-url>api/v1/uploadFileTo/tree/1/ destination=='a/file1.txt' syncIdentifier=='your-syncID_' source@~/Documents/Samples/text1.txt
```

```shell
http -v -f POST  <your-base-url>api/v1/uploadFileTo/tree/1/ destination=='a/file2.txt' syncIdentifier=='your-syncID_' source@~/Documents/Samples/text2.txt
```

7. Finalize the upload session
```shell
http -v -f POST <your-base-url>api/v1/finalizeTransactionIn/tree/1/ commands='[[0 ,"a/file1.txt"],[0 ,"a/file2.txt"]]' syncIdentifier='your-syncID_' hashmap@~/Documents/Samples/hashmap.data
```
8. Download the file1
```shell
http -v GET <your-base-url>api/v1/file/tree/1/ path=='a/file1.txt' redirect==false returnValue==true
```

9. Download the hashmap that should now exist
```shell
http -v GET  <your-base-url>api/v1/hashMap/tree/1/ redirect==true returnValue==false
```

### PdSSync in objective C: ###

```objc

```
