<?php
$html = (PHP_SAPI != 'cli');

ob_start();
phpinfo();
$info = ob_get_contents();
ob_clean();

$out = $html ? "<div class=\"center\">" : '';

if (function_exists('apache_get_modules'))
{
    $hdr = 'Apache modules';
    $out .= $html ? "<h2>$hdr</h2>\n<table class=\"tbl\">\n<tr>" : "$hdr:\n";
    $mods = apache_get_modules();
    asort($mods);
    $i = 0;
    foreach ($mods as $mod)
    {
        $out .= $html ? "<td>$mod</td>" : "  $mod\n";
	if ($html)
	{
	    $i++;
	    if ($i > 7)
	    {
		$out .= "</tr>\n<tr>";
		$i = 0;
	    }
	}
    }
    $out .= $html ? "</tr>\n</table><br>\n" : "\n";
}

if (function_exists('get_loaded_extensions'))
{
    $hdr = 'Loaded extensions';
    $out .= $html ? "<h2>$hdr</h2>\n<table class=\"tbl\">\n<tr>" : "$hdr:\n";
    $exts = get_loaded_extensions();
    if (!in_array('ereg', $exts) && function_exists('ereg_replace'))
	$exts[] = 'ereg [Core]';
    if (!in_array('mhash', $exts) && function_exists('mhash'))
	$exts[] = 'mhash [hash]';
    asort($exts);
    $i = 0;
    foreach ($exts as $ext)
    {
        $out .= $html ? "<td>$ext</td>" : "  $ext\n";
        $i++;
	if ($html)
	{
	    if ($i > 15)
	    {
		$out .= "</tr>\n<tr>";
		$i = 0;
	    }
	}
    }
    $out .= $html ? "</tr>\n</table><br>\n" : "\n";
}

$out .= $html ? "</div>\n" : "--------------------\n";

if ($html)
{
    $ver = PHP_VERSION;
    $sys = PHP_OS;
    $info = str_replace('</style>', ".tbl{width:auto}\n</style>", $info);
    $info = preg_replace('/<title>.*phpinfo\(\)/', "<title>PHP $ver / $sys info", $info);
    $info = str_replace('<body>', "<body>\n$out", $info);
    echo "$info";
}
else
    echo "$out$info";
?>
