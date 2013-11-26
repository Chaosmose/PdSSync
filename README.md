PdSSync
=========

A simple delta synchronizer

	[ SERVER ]
	
	↑       |   
			
 upSync    downSync
    |       ↓
 MASTER   CLIENTS 



Objective C : 
=============


PHP : 
=====

A very simple PHP restfull service.


GET distantTree (string identifier)

GET locked (string identifier)

POST (string syncIdentifier) newSynchronisationID (string identifier) 

POST uploadToRelativePath (string relativePath)

POST finalizeWithOperations (string syncIdentifier, array operations) 
(cycle : 1- Locks 2- Finalize 3 -Unlocks) 


Distant FS operation : 
----------------------

- move
- copy
- remove

typedef enum _PdSSyncOperation {
    PdSCopy      = 0,
    PdSMove      = 1,
    PdSDelete    = 2
} PdSSyncOperation;

typedef enum _PdSSyncOperationParams {
    PdSSource      = 0,
    PdSDestination = 1
} PdSSyncOperationParams;

