<?php
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
	
	public function delete($filename){
		if(!file_exists($filename)){
			return true;
		}
		if(is_dir($filename)){
			return $this->_rmdir($filename,true);
		}else{
			return unlink($filename);
		}
	}
	
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
	
	
	public function move_uploaded($filename, $destination) {
		 $this->mkdir( dirname ( $destination ));
		return move_uploaded_file ( $filename, $destination );
	}
}?>