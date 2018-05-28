<?php

    include_once  "../api/v1/PdSSyncConfig.php";
    $site = "Mapping";
    $path = REPOSITORY_WRITING_PATH;

    $list = "";
    $content = scandir($path);
    foreach ($content as $element) {
        if (substr($element,0,1) == "."){
            //
        }else{
            $channelDescriptorPath = $path.$element.DIRECTORY_SEPARATOR.'channel.json';
            $json = file_get_contents($channelDescriptorPath);
            $json = utf8_encode(substr($json,2));
            $list .= "<p><b>$element</b>: $json</p>";
        }

    }
?>
<!doctype html>
<html lang="fr">
<head>
<meta charset="utf-8">
<title><?php echo ($site)?></title>
<link rel="stylesheet" type="text/css" href="map.css"/>
</head>
<body>
<p><?php echo ($list); ?></p>
</body>
</html>
