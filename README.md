# PdSSync

A simple delta synchronizer for large repositories.

# Objective C "An efficient synchronization lib"

The objective c lib is a synchronisation client that synchronizes local A -\> B and distant set of files by using a mediation service MASTER  -\> \[ mediation server ] -\> CLIENTS

# PdSSyncPhp "A very simple PHP sync restfull service" 

GET (string json)distantTree (string identifier)
GET (string json)locked (string identifier)
POST (string syncIdentifier) newSynchronisationID (string identifier) 
POST (string json) uploadToRelativePath (string relativePath)
POST (string json) finalizeWithOperations (string syncIdentifier, array operations)  1- Locks 2- Finalize 3 -Unlocks


## Distant FS operation :

- move
- copy
- remove


typedef enum \_PdSSyncOperation 
	PdSCopy      = 0,
	PdSMove      = 1,
	PdSDelete    = 2
} PdSSyncOperation;

typedef enum \_PdSSyncOperationParams 
	PdSSource      = 0,
	PdSDestination = 1
} PdSSyncOperationParams;
