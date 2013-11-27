<?php


class BackgroundExecution {

	private $pid;

	public  function runPHP($phpString,$outputFile = '/dev/null'){
		$this->pid = shell_exec(sprintf(
				'%s > %s 2>&amp;1 &amp; echo $!',
				'php -r \'.$phpStringp.\'',
				$outputFile
		));
	}
	
	public function isRunning() {
		try {
			$result = shell_exec(sprintf('ps %d', $this->pid));
			if(count(preg_split("/\n/", $result)) > 2) {
				return true;
			}
		} catch(Exception $e) {		
		}
		return false;
	}

	public function getPid(){
		return $this->pid;
	}
	
}