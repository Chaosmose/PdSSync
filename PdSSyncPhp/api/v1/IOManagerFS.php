<?php
/** @noinspection PhpIncludeInspection */
/** @noinspection PhpIncludeInspection */
require_once 'IOManager.php';

/**
 * Concrete IOManager using a file system
 * @author bpds
 */
final class IOManagerFS extends IOManagerAbstract implements IOManagerPersistency {
	
	public function exists($filename) {
		return file_exists ( $filename );
	}
	
	public function put_contents($filename, $data) {
		return file_put_contents ( $filename, $data );
	}
	
	public function get_contents($filename){
		return file_get_contents($filename);
	}
	
	public function mkdir($dir) {
		if (! file_exists ( $dir )) {
			return mkdir ( $dir, 0777, true );
		}
		return true;
	}
	
	public function rename($oldname, $newname) {
		return rename ( $oldname, $newname );
	}
	
	public function copy( $source, $destination ){
		return copy($source, $destination);
	}

    /**
     * Deletes a file or recursively a folder
     * Returns true if the file or the folder does not exists.
     * @see IOManagerPersistency::delete()
     * @param $filename
     * @return bool
     */
	public function delete($filename){
		if(!file_exists($filename)){
			return true;
		}
		if(is_dir($filename)){
			// we delete folders with a recursive deletion method
			return $this->_rmdir($filename,true);
		}else{
			return unlink($filename);
		}
	}

    /**
     * @param $dir
     * @param $result
     * @return bool
     */
    private function _rmdir($dir,$result) {
		if (is_dir($dir)) {
			$objects = scandir($dir);
			foreach ($objects as $object) {
				if ($object != "." && $object != "..") {
					if (filetype($dir."/".$object) == "dir") 
						$result=$result&&$this->_rmdir($dir."/".$object,$result);
					else 
						$result=$result&&unlink($dir."/".$object);
				}
			}
			$result=$result&&rmdir($dir);
		}
		return $result;
	}


    /**
     * @param $filename
     * @param $destination
     * @return bool
     */
    public function move_uploaded($filename, $destination) {
		 $this->mkdir( dirname ( $destination ));
		return move_uploaded_file ( $filename, $destination );
	}


    /**
     * @param $dirPath
     * @param string $prefix
     * @return array
     */
    public function  listRelativePathsIn ($dirPath,$prefix=''){
		$dir = rtrim($dirPath, '\\/');
		$result = array();
		foreach (scandir($dir) as $f) {
			if ($f !== '.' and $f !== '..') {
				if (is_dir("$dir/$f")) {
					$result = array_merge($result , $this->listRelativePathsIn("$dir/$f", "$prefix$f/"));
				} else {
					$result[] = $prefix.$f;
				}
			}
		}
		return $result;
	}

    public function removeGhosts(){
        $deletedPath=array();
        $foundPath=array();
        $pathFoundInTreeInfo=array();
        $pathFoundInTreeInfoOrigin=array();
        $dir=$this->repositoryAbsolutePath();
        foreach (scandir($dir) as $f) {
            $foundPath[]="$dir$f";
            $p=$dir.$f.'/'.TREE_INFOS_FILENAME;
            if($this->exists($p)){
                $this->treeData= json_decode( $this->get_contents($p));
                $associatedPath=$dir.$this->treeData[0].'/';
                $pathFoundInTreeInfo[]=$associatedPath;
                $pathFoundInTreeInfoOrigin[]=$p;
                if($this->exists($associatedPath)==false){
                    //IF there is TREE INFO file but no associated folder.
                    //ITS is a GHOST Delete the folder
                    $this->delete($dir.$f);
                    $deletedPath[]=$dir.$f;
                }
            }
            //if $foundPath
        }
        $i=0;
        foreach ($pathFoundInTreeInfo as $pathFound) {
            //  IF THERE IS NO ASSOCIATED TREE_INFOS_FILENAME IT IS A GHOST
            if($this->exists($pathFound)==false){
                $this->delete($pathFoundInTreeInfoOrigin[$i]);
                $deletedPath[]=$pathFoundInTreeInfoOrigin[$i];
            }
            $i++;
        }

        return array("foundPath"=>$foundPath,"deletedPath"=> $deletedPath);
    }
}
?>