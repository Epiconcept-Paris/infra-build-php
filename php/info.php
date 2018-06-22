<?php
$html = (PHP_SAPI != 'cli');
if ($html) {?>
<!DOCTYPE html>
<html>
<body>
<style type="text/css">.tbl{width:auto}</style>
<?php
}

echo 'PHP_OS = "'.PHP_OS.'"'.($html?'<br>':'')."\n";
echo $html ? '<div class="center">' : '';

if (function_exists('apache_get_modules'))
{
    $hdr = 'Apache modules';
    echo $html ? "<h2>$hdr</h2><table class=\"tbl\"><tr>" : "$hdr:\n";
    $mods = apache_get_modules();
    asort($mods);
    $i = 0;
    foreach ($mods as $mod)
    {
        echo $html ? "<td>$mod</td>" : "  $mod\n";
	if ($html)
	{
	    $i++;
	    if ($i > 7)
	    {
		echo '</tr><tr>';
		$i = 0;
	    }
	}
    }
    echo $html ? '</tr></table><br>' : "\n";
}

if (function_exists('get_loaded_extensions'))
{
    $hdr = 'Loaded extensions';
    echo $html ? "<h2>$hdr</h2><table class=\"tbl\"><tr>" : "$hdr:\n";
    $exts = get_loaded_extensions();
    asort($exts);
    $i = 0;
    foreach ($exts as $ext)
    {
        echo $html ? "<td>$ext</td>" : "  $ext\n";
        $i++;
	if ($html)
	{
	    if ($i > 15)
	    {
		echo '</tr><tr>';
		$i = 0;
	    }
	}
    }
    echo $html ? '</tr></table><br>' : "\n";
}

if (method_exists('PDO','getAvailableDrivers'))
{
    $hdr = 'PDO drivers';
    echo $html ? "<h2>$hdr</h2><table class=\"tbl\"><tr>" : "$hdr:\n";
    $drvs = PDO::getAvailableDrivers();
    asort($drvs);
    $i = 0;
    foreach ($drvs as $drv)
    {
        echo $html ? "<td>$drv</td>" : "  $drv\n";
        $i++;
	if ($html)
	{
	    if ($i > 15)
	    {
		echo '</tr><tr>';
		$i = 0;
	    }
	}
    }
    echo $html ? '</tr></table><br>' : "\n";
}

echo $html ? '</div>' : "\n";

phpinfo();

if ($html) {
?>
</body>
</html>
<?php
}
?>
