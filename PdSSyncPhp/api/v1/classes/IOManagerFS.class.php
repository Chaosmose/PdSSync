  <?php

require_once 'IOManager.class.php';

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
		return unlink($filename);
	}
	
	public function move_uploaded($filename, $destination) {
		 $this->mkdir( dirname ( $destination ));
		return move_uploaded_file ( $filename, $destination );
	}
	
}

?>